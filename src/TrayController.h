#pragma once

#include <QElapsedTimer>
#include <QMenu>
#include <QObject>
#include <QPointer>
#include <QSystemTrayIcon>

class QQuickWindow;
class UsageWatcher;

// Owns the tray icon (a live 5-hour usage ring) and toggles the QML popup.
class TrayController : public QObject
{
    Q_OBJECT

public:
    TrayController(UsageWatcher *usage, QQuickWindow *popup, QObject *parent = nullptr);

    void togglePopup();
    void showPopup();

private slots:
    void updateWorkspaces();

private:
    void updateIcon();
    void positionPopup();

    UsageWatcher *m_usage;
    QPointer<QQuickWindow> m_popup;
    QSystemTrayIcon m_tray;
    QMenu m_menu;
    QElapsedTimer m_sinceHidden;
    int m_lastShownPercent = -2;
};
