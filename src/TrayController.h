#pragma once

#include <QElapsedTimer>
#include <QMenu>
#include <QObject>
#include <QPointer>
#include <QSystemTrayIcon>

class QQuickWindow;
class UsageWatcher;

// Owns the tray icon (a live 5-hour usage ring) and the QML popups: the
// details panel opens on primary activation, the gauge from the context menu.
class TrayController : public QObject
{
    Q_OBJECT

public:
    enum class View { Details, Gauge };

    TrayController(UsageWatcher *usage, QQuickWindow *details, QQuickWindow *gauge, QObject *parent = nullptr);

    void toggle(View view);
    void show(View view);

private:
    struct Popup
    {
        QPointer<QQuickWindow> window;
        QElapsedTimer sinceHidden;
    };

    Popup &popup(View view) { return view == View::Details ? m_details : m_gauge; }
    void updateIcon();
    void position(QQuickWindow *window);

    UsageWatcher *m_usage;
    Popup m_details;
    Popup m_gauge;
    QSystemTrayIcon m_tray;
    QMenu m_menu;
    int m_lastShownPercent = -2;
};
