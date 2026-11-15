#pragma once

#include <QElapsedTimer>
#include <QList>
#include <QMenu>
#include <QObject>
#include <QPointer>
#include <QSystemTrayIcon>

class QQuickWindow;
class UsageWatcher;

// Owns the tray icon (a live 5-hour usage ring for the profile selected in the
// popup) and toggles the QML popup.
class TrayController : public QObject
{
    Q_OBJECT

public:
    TrayController(QList<UsageWatcher *> profiles, QQuickWindow *popup, QObject *parent = nullptr);

    void togglePopup();
    void showPopup();

private slots:
    void updateWorkspaces();
    void updateIcon();

private:
    UsageWatcher *currentProfile() const;
    void positionPopup();

    QList<UsageWatcher *> m_profiles;
    QPointer<QQuickWindow> m_popup;
    QSystemTrayIcon m_tray;
    QMenu m_menu;
    QElapsedTimer m_sinceHidden;
    int m_lastShownPercent = -2;
};
