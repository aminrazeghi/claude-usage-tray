#include "TrayController.h"

#include "UsageWatcher.h"

#include <QApplication>
#include <QPainter>
#include <QQuickWindow>
#include <QScreen>

#include <cstring>

#include <xcb/xcb.h>

namespace {

QColor usageColor(double percent)
{
    if (percent >= 90)
        return QColor(0xFF, 0x45, 0x3A);
    if (percent >= 75)
        return QColor(0xFF, 0x9F, 0x0A);
    return QColor(0x34, 0xC7, 0x59);
}

// A ring showing 5-hour usage with the percentage in the middle; panels
// can't show text next to a StatusNotifierItem, so the number lives in the icon.
QIcon renderTrayIcon(int percent)
{
    QIcon icon;
    for (int size : {16, 22, 24, 32, 48, 64}) {
        QPixmap pm(size, size);
        pm.fill(Qt::transparent);
        QPainter p(&pm);
        p.setRenderHint(QPainter::Antialiasing);

        const qreal stroke = std::max<qreal>(2.0, size * 0.11);
        const QRectF ring = QRectF(0, 0, size, size).adjusted(stroke / 2 + 0.5, stroke / 2 + 0.5, -stroke / 2 - 0.5, -stroke / 2 - 0.5);

        p.setPen(QPen(QColor(255, 255, 255, 70), stroke));
        p.drawEllipse(ring);

        if (percent > 0) {
            QPen arc(usageColor(percent), stroke);
            arc.setCapStyle(Qt::RoundCap);
            p.setPen(arc);
            p.drawArc(ring, 90 * 16, -int(std::min(percent, 100) * 3.6 * 16));
        }

        const QString text = percent < 0 ? QStringLiteral("–") : QString::number(percent);
        QFont font = QApplication::font();
        font.setBold(true);
        font.setPixelSize(int(size * (text.size() >= 3 ? 0.30 : 0.40)));
        p.setFont(font);
        p.setPen(Qt::white);
        p.drawText(QRectF(0, 0, size, size), Qt::AlignCenter, text);
        p.end();
        icon.addPixmap(pm);
    }
    return icon;
}

xcb_atom_t internAtom(xcb_connection_t *conn, const char *name)
{
    xcb_intern_atom_reply_t *reply = xcb_intern_atom_reply(conn, xcb_intern_atom(conn, 0, uint16_t(strlen(name)), name), nullptr);
    const xcb_atom_t atom = reply ? reply->atom : xcb_atom_t(XCB_ATOM_NONE);
    free(reply);
    return atom;
}

// Show the window on every workspace (GNOME's "Always on Visible Workspace")
// or only the current one. Qt has no API for this, so use the EWMH hints
// directly; only possible under X11/XWayland.
void setOnAllWorkspaces(QWindow *window, bool all)
{
    auto *x11 = qApp->nativeInterface<QNativeInterface::QX11Application>();
    if (!x11)
        return;
    xcb_connection_t *conn = x11->connection();
    const auto win = xcb_window_t(window->winId());

    if (!window->isVisible()) {
        // The WM reads _NET_WM_DESKTOP (0xFFFFFFFF = all desktops) when the
        // window is mapped and drops it when it's withdrawn, so this has to
        // be set before every show.
        const xcb_atom_t desktop = internAtom(conn, "_NET_WM_DESKTOP");
        const uint32_t allDesktops = 0xFFFFFFFF;
        if (all)
            xcb_change_property(conn, XCB_PROP_MODE_REPLACE, win, desktop, XCB_ATOM_CARDINAL, 32, 1, &allDesktops);
        else
            xcb_delete_property(conn, win, desktop);
        return;
    }

    // Once mapped, the WM only honours a request sent to the root window.
    xcb_client_message_event_t event = {};
    event.response_type = XCB_CLIENT_MESSAGE;
    event.format = 32;
    event.window = win;
    event.type = internAtom(conn, "_NET_WM_STATE");
    event.data.data32[0] = all ? 1 : 0;  // _NET_WM_STATE_ADD / _NET_WM_STATE_REMOVE
    event.data.data32[1] = internAtom(conn, "_NET_WM_STATE_STICKY");
    event.data.data32[3] = 1;  // source: normal application
    const xcb_window_t root = xcb_setup_roots_iterator(xcb_get_setup(conn)).data->root;
    xcb_send_event(conn, 0, root, XCB_EVENT_MASK_SUBSTRUCTURE_REDIRECT | XCB_EVENT_MASK_SUBSTRUCTURE_NOTIFY,
                   reinterpret_cast<const char *>(&event));
    xcb_flush(conn);
}

} // namespace

TrayController::TrayController(UsageWatcher *usage, QQuickWindow *popup, QObject *parent)
    : QObject(parent)
    , m_usage(usage)
    , m_popup(popup)
{
    m_menu.addAction(QStringLiteral("Show Usage"), this, &TrayController::showPopup);
    m_menu.addAction(QStringLiteral("Refresh"), m_usage, &UsageWatcher::refresh);
    m_menu.addSeparator();
    m_menu.addAction(QStringLiteral("Quit"), qApp, &QCoreApplication::quit);
    m_tray.setContextMenu(&m_menu);

    // GNOME's AppIndicator extension opens the context menu on a single left
    // click and only sends Activate (Trigger) on a double click; other hosts
    // send Trigger on a single click.
    connect(&m_tray, &QSystemTrayIcon::activated, this, [this](QSystemTrayIcon::ActivationReason reason) {
        if (reason == QSystemTrayIcon::Trigger || reason == QSystemTrayIcon::DoubleClick)
            togglePopup();
    });

    // The popup hides itself when it loses focus. Clicking the tray icon causes
    // exactly that just before `activated` fires, so remember when it happened
    // to keep the click from immediately reopening it.
    connect(m_popup, &QWindow::visibleChanged, this, [this](bool visible) {
        if (!visible)
            m_sinceHidden.start();
    });

    // A pinned popup follows you across workspaces; an unpinned one closes
    // as soon as it loses focus anyway.
    connect(m_popup, SIGNAL(pinnedChanged()), this, SLOT(updateWorkspaces()));

    connect(m_usage, &UsageWatcher::clockChanged, this, &TrayController::updateIcon);
    connect(m_usage, &UsageWatcher::dataChanged, this, &TrayController::updateIcon);
    updateIcon();
    m_tray.show();
}

void TrayController::updateIcon()
{
    const int percent = m_usage->fiveHourKnown() ? int(std::lround(m_usage->fiveHourUsed())) : -1;
    if (percent == m_lastShownPercent)
        return;
    m_lastShownPercent = percent;
    m_tray.setIcon(renderTrayIcon(percent));

    QString tip = QStringLiteral("Claude Usage");
    if (m_usage->fiveHourKnown())
        tip += QStringLiteral("\n5-hour: %1% (resets %2)").arg(percent).arg(m_usage->fiveHourResetText());
    if (m_usage->sevenDayKnown())
        tip += QStringLiteral("\n7-day: %1% (resets %2)").arg(std::lround(m_usage->sevenDayUsed())).arg(m_usage->sevenDayResetText());
    m_tray.setToolTip(tip);
}

void TrayController::updateWorkspaces()
{
    setOnAllWorkspaces(m_popup, m_popup->property("pinned").toBool());
}

void TrayController::togglePopup()
{
    if (!m_popup)
        return;
    if (m_popup->isVisible()) {
        m_popup->hide();
        return;
    }
    // Long enough to cover GNOME's double-click wait between the two presses.
    if (m_sinceHidden.isValid() && m_sinceHidden.elapsed() < 500)
        return;
    showPopup();
}

void TrayController::showPopup()
{
    if (!m_popup)
        return;
    positionPopup();
    updateWorkspaces();
    m_popup->show();
    m_popup->raise();
    m_popup->requestActivate();
}

void TrayController::positionPopup()
{
    const QRect trayRect = m_tray.geometry();
    QScreen *screen = nullptr;
    if (trayRect.isValid())
        screen = QGuiApplication::screenAt(trayRect.center());
    if (!screen)
        screen = QGuiApplication::primaryScreen();  // GNOME and KDE put the panel on the primary monitor

    const QRect avail = screen->availableGeometry();
    const QSize size = m_popup->size();
    const int margin = 6;
    QPoint pos;

    if (trayRect.isValid()) {
        // Below the icon for a top panel, above it for a bottom panel.
        const bool topHalf = trayRect.center().y() < screen->geometry().center().y();
        pos.setX(trayRect.center().x() - size.width() / 2);
        pos.setY(topHalf ? trayRect.bottom() + margin : trayRect.top() - size.height() - margin);
    } else {
        // StatusNotifierItem hosts (GNOME, KDE) don't report the icon's
        // geometry; the tray area lives in the top-right corner on most desktops.
        pos = QPoint(avail.right() - size.width() - margin, avail.top() + margin);
    }

    pos.setX(std::clamp(pos.x(), avail.left() + margin, avail.right() - size.width() - margin));
    pos.setY(std::clamp(pos.y(), avail.top() + margin, avail.bottom() - size.height() - margin));
    m_popup->setPosition(pos);
}
