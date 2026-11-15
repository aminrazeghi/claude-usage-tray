#pragma once

#include <QElapsedTimer>
#include <QList>
#include <QMenu>
#include <QObject>
#include <QPointer>
#include <QSystemTrayIcon>

class ProfileManager;
class QQuickWindow;
class UsageWatcher;

// Owns the tray icon (a live 5-hour usage ring for the profile selected in the
// popup) and toggles the QML popup.
class TrayController : public QObject
{
    Q_OBJECT

public:
    TrayController(ProfileManager *profiles, QQuickWindow *popup, QObject *parent = nullptr);

    void togglePopup();
    void showPopup();

private slots:
    void updateWorkspaces();
    void updateIcon();

private:
    void connectProfiles();
    UsageWatcher *currentProfile() const;
    void positionPopup();

    ProfileManager *m_profiles;
    QPointer<QQuickWindow> m_popup;
    QSystemTrayIcon m_tray;
    QMenu m_menu;
    QElapsedTimer m_sinceHidden;
    int m_lastShownPercent = -2;
};
