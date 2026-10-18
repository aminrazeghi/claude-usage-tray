#include "ClaudeSetup.h"
#include "TrayController.h"
#include "UsageWatcher.h"

#include <QApplication>
#include <QCommandLineParser>
#include <QDir>
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
    QApplication::setApplicationName(QStringLiteral("claude-usage-monitor"));
    QApplication::setApplicationDisplayName(QStringLiteral("Claude Usage"));
    QApplication::setApplicationVersion(QStringLiteral(PROJECT_VERSION_STRING));
    QApplication::setQuitOnLastWindowClosed(false);
    QApplication::setWindowIcon(QIcon(QStringLiteral(":/qt/qml/ClaudeUsage/resources/claude-icon.svg")));

    QCommandLineParser parser;
    parser.setApplicationDescription(QStringLiteral("System tray monitor for Claude usage limits."));
    parser.addHelpOption();
    parser.addVersionOption();
    const QCommandLineOption noSetup(QStringLiteral("no-setup"), QStringLiteral("Do not touch ~/.claude/settings.json or statusline.sh."));
    const QCommandLineOption forceSetup(QStringLiteral("force-setup"), QStringLiteral("Replace an existing statusLine command (settings are backed up first)."));
    const QCommandLineOption showOption(QStringLiteral("show"), QStringLiteral("Open a popup on startup."));
    const QCommandLineOption viewOption(QStringLiteral("view"), QStringLiteral("Popup for --show/--grab: details or gauge."), QStringLiteral("view"),
                                        QStringLiteral("details"));
    const QCommandLineOption fileOption(QStringLiteral("file"), QStringLiteral("Usage snapshot to watch."), QStringLiteral("path"),
                                        qEnvironmentVariable("CLAUDE_USAGE_FILE", QStringLiteral("/tmp/claude-usage.json")));
    const QCommandLineOption grabOption(QStringLiteral("grab"), QStringLiteral("Render the popup to an image file and exit."), QStringLiteral("png"));
    parser.addOptions({noSetup, forceSetup, showOption, viewOption, fileOption, grabOption});
    parser.process(app);

    QLockFile lock(QDir::tempPath() + QStringLiteral("/claude-usage-monitor-%1.lock").arg(qEnvironmentVariable("USER")));
    if (!lock.tryLock(100)) {
        qWarning("claude-usage-monitor is already running.");
        return 0;
    }

    if (!parser.isSet(noSetup)) {
        ClaudeSetup::installStatuslineScript();
        ClaudeSetup::configureSettings(parser.isSet(forceSetup));
    }

    if (!QSystemTrayIcon::isSystemTrayAvailable())
        qWarning("No system tray detected. On GNOME, enable the AppIndicator extension.");

    UsageWatcher usage(parser.value(fileOption));

    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty(QStringLiteral("usage"), &usage);
    engine.load(QUrl(QStringLiteral("qrc:/qt/qml/ClaudeUsage/qml/main.qml")));
    QObject *root = engine.rootObjects().isEmpty() ? nullptr : engine.rootObjects().constFirst();
    auto *details = root ? root->property("detailsWindow").value<QQuickWindow *>() : nullptr;
    auto *gauge = root ? root->property("gaugeWindow").value<QQuickWindow *>() : nullptr;
    if (!details || !gauge)
        return 1;

    const auto view = parser.value(viewOption) == QLatin1String("gauge") ? TrayController::View::Gauge
                                                                         : TrayController::View::Details;

    if (parser.isSet(grabOption)) {
        QQuickWindow *popup = view == TrayController::View::Gauge ? gauge : details;
        const QString target = parser.value(grabOption);
        popup->show();
        QTimer::singleShot(1500, popup, [popup, target] {
            QCoreApplication::exit(popup->grabWindow().save(target) ? 0 : 1);
        });
        return app.exec();
    }

    TrayController tray(&usage, details, gauge);
    if (parser.isSet(showOption))
        tray.show(view);

    return app.exec();
}
