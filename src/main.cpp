#include "ClaudeSetup.h"
#include "TrayController.h"
#include "UsageWatcher.h"

#include <QApplication>
#include <QCommandLineParser>
#include <QDir>
#include <QFileInfo>
#include <QHash>
#include <QLockFile>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickWindow>
#include <QSystemTrayIcon>
#include <QTimer>

int main(int argc, char *argv[])
{
    // Native Wayland clients cannot place their own windows, so the popup could
    // not appear under the tray. Run through XWayland unless told otherwise.
    if (qEnvironmentVariableIsEmpty("QT_QPA_PLATFORM") && !qEnvironmentVariableIsEmpty("WAYLAND_DISPLAY")
        && !qEnvironmentVariableIsEmpty("DISPLAY"))
        qputenv("QT_QPA_PLATFORM", "xcb");

    QApplication app(argc, argv);
    QApplication::setOrganizationName(QStringLiteral("claude-usage-monitor"));  // QML Settings -> ~/.config/claude-usage-monitor/
    QApplication::setApplicationName(QStringLiteral("claude-usage-monitor"));
    QApplication::setApplicationDisplayName(QStringLiteral("Claude Usage"));
    QApplication::setApplicationVersion(QStringLiteral(PROJECT_VERSION_STRING));
    QApplication::setQuitOnLastWindowClosed(false);
    QApplication::setWindowIcon(QIcon(QStringLiteral(":/qt/qml/ClaudeUsage/resources/claude-icon.svg")));

    QCommandLineParser parser;
    parser.setApplicationDescription(QStringLiteral("System tray monitor for Claude usage limits."));
    parser.addHelpOption();
    parser.addVersionOption();
    const QCommandLineOption noSetup(QStringLiteral("no-setup"), QStringLiteral("Do not touch settings.json or statusline.sh in ~/.claude and ~/.claude-*."));
    const QCommandLineOption forceSetup(QStringLiteral("force-setup"), QStringLiteral("Replace an existing statusLine command (settings are backed up first)."));
    const QCommandLineOption showOption(QStringLiteral("show"), QStringLiteral("Open the popup on startup."));
    const QCommandLineOption fileOption(QStringLiteral("file"), QStringLiteral("Usage snapshot to watch for the ~/.claude profile."), QStringLiteral("path"),
                                        qEnvironmentVariable("CLAUDE_USAGE_FILE", QStringLiteral("/tmp/claude-usage.json")));
    const QCommandLineOption grabOption(QStringLiteral("grab"), QStringLiteral("Render the popup to an image file and exit."), QStringLiteral("png"));
    parser.addOptions({noSetup, forceSetup, showOption, fileOption, grabOption});
    parser.process(app);

    QLockFile lock(QDir::tempPath() + QStringLiteral("/claude-usage-monitor-%1.lock").arg(qEnvironmentVariable("USER")));
    if (!lock.tryLock(100)) {
        qWarning("claude-usage-monitor is already running.");
        return 0;
    }

    QList<ClaudeSetup::Profile> profiles = ClaudeSetup::discoverProfiles();
    if (parser.isSet(fileOption) || qEnvironmentVariableIsSet("CLAUDE_USAGE_FILE"))
        profiles.first().usageFile = parser.value(fileOption);

    if (!parser.isSet(noSetup)) {
        for (const ClaudeSetup::Profile &profile : std::as_const(profiles)) {
            ClaudeSetup::installStatuslineScript(profile.configDir);
            ClaudeSetup::configureSettings(profile.configDir, parser.isSet(forceSetup));
        }
    }

    if (!QSystemTrayIcon::isSystemTrayAvailable())
        qWarning("No system tray detected. On GNOME, enable the AppIndicator extension.");

    // Profiles whose projects/ resolve to the same folder (e.g. a symlink)
    // split "Today" by session instead of counting each other's transcripts.
    auto projectsOf = [](const ClaudeSetup::Profile &profile) {
        return QFileInfo(profile.configDir + QStringLiteral("/projects")).canonicalFilePath();
    };
    QHash<QString, int> projectDirUsers;
    for (const ClaudeSetup::Profile &profile : std::as_const(profiles))
        ++projectDirUsers[projectsOf(profile)];

    // One watcher per subscription, owned by the app.
    QList<UsageWatcher *> watchers;
    QVariantList watcherObjects;
    for (const ClaudeSetup::Profile &profile : std::as_const(profiles)) {
        const QString projects = projectsOf(profile);
        const bool shared = !projects.isEmpty() && projectDirUsers.value(projects) > 1;
        auto *watcher = new UsageWatcher(profile.name, profile.configDir, profile.usageFile, shared, &app);
        watchers.append(watcher);
        watcherObjects.append(QVariant::fromValue(static_cast<QObject *>(watcher)));
    }

    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty(QStringLiteral("profiles"), watcherObjects);
    engine.load(QUrl(QStringLiteral("qrc:/qt/qml/ClaudeUsage/qml/main.qml")));
    auto *popup = engine.rootObjects().isEmpty() ? nullptr : qobject_cast<QQuickWindow *>(engine.rootObjects().constFirst());
    if (!popup)
        return 1;

    if (parser.isSet(grabOption)) {
        const QString target = parser.value(grabOption);
        popup->show();
        QTimer::singleShot(1500, popup, [popup, target] {
            QCoreApplication::exit(popup->grabWindow().save(target) ? 0 : 1);
        });
        return app.exec();
    }

    TrayController tray(watchers, popup);
    if (parser.isSet(showOption))
        tray.showPopup();

    return app.exec();
}
