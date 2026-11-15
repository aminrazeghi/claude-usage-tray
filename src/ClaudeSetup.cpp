#include "ClaudeSetup.h"

#include <QDateTime>
#include <QDebug>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QJsonDocument>
#include <QJsonObject>
#include <QSaveFile>

namespace {

const QString kScriptMarker = QStringLiteral("claude-usage-monitor statusline");

QByteArray readAll(const QString &path)
{
    QFile f(path);
    return f.open(QIODevice::ReadOnly) ? f.readAll() : QByteArray();
}

bool writeAtomically(const QString &path, const QByteArray &data)
{
    QSaveFile f(path);
    if (!f.open(QIODevice::WriteOnly) || f.write(data) != data.size())
        return false;
    return f.commit();
}

// The part after ".claude-" in a profile directory's name; empty for ~/.claude.
QString profileSuffix(const QString &configDir)
{
    const QString base = QFileInfo(configDir).fileName();
    return base.startsWith(QLatin1String(".claude-")) ? base.mid(8) : QString();
}

// "~/.claude-work/statusline.sh" for directories under $HOME, absolute otherwise.
QString statuslineCommand(const QString &configDir)
{
    const QString home = QDir::homePath();
    QString path = configDir + QStringLiteral("/statusline.sh");
    if (path.startsWith(home + QLatin1Char('/')))
        path = QStringLiteral("~") + path.mid(home.size());
    return path;
}

} // namespace

QList<ClaudeSetup::Profile> ClaudeSetup::discoverProfiles()
{
    const QString main = QDir::homePath() + QStringLiteral("/.claude");
    QList<Profile> profiles{{QStringLiteral("Main"), main, usageFileFor(main)}};

    const QFileInfoList dirs = QDir::home().entryInfoList({QStringLiteral(".claude-*")},
                                                          QDir::Dirs | QDir::Hidden | QDir::NoDotAndDotDot, QDir::Name);
    for (const QFileInfo &dir : dirs) {
        const QString path = dir.absoluteFilePath();
        const QString suffix = profileSuffix(path);
        if (suffix.isEmpty() || !(QFile::exists(path + QStringLiteral("/.claude.json")) || QDir(path + QStringLiteral("/projects")).exists()))
            continue;
        profiles.append({suffix.left(1).toUpper() + suffix.mid(1), path, usageFileFor(path)});
    }
    return profiles;
}

QString ClaudeSetup::usageFileFor(const QString &configDir)
{
    const QString suffix = profileSuffix(configDir);
    return suffix.isEmpty() ? QStringLiteral("/tmp/claude-usage.json")
                            : QStringLiteral("/tmp/claude-usage-%1.json").arg(suffix);
}

bool ClaudeSetup::installStatuslineScript(const QString &configDir)
{
    QDir().mkpath(configDir);
    const QString target = configDir + QStringLiteral("/statusline.sh");
    const QByteArray bundled = readAll(QStringLiteral(":/qt/qml/ClaudeUsage/resources/statusline.sh"));
    if (bundled.isEmpty()) {
        qWarning() << "Bundled statusline.sh is missing from resources";
        return false;
    }

    if (QFile::exists(target)) {
        const QByteArray current = readAll(target);
        if (current == bundled)
            return true;
        if (!current.contains(kScriptMarker.toUtf8())) {
            qWarning().noquote() << target << "was not written by claude-usage-monitor; leaving it alone."
                                 << "Usage data needs it to write /tmp/claude-usage.json.";
            return false;
        }
    }

    if (!writeAtomically(target, bundled)) {
        qWarning().noquote() << "Could not write" << target;
        return false;
    }
    QFile::setPermissions(target, QFile::ReadOwner | QFile::WriteOwner | QFile::ExeOwner
                                      | QFile::ReadGroup | QFile::ExeGroup | QFile::ReadOther | QFile::ExeOther);
    qInfo().noquote() << "Installed" << target;
    return true;
}

bool ClaudeSetup::configureSettings(const QString &configDir, bool force)
{
    const QString path = configDir + QStringLiteral("/settings.json");
    const QString wanted = statuslineCommand(configDir);
    QJsonObject settings;

    if (QFile::exists(path)) {
        QJsonParseError err;
        const QJsonDocument doc = QJsonDocument::fromJson(readAll(path), &err);
        if (err.error != QJsonParseError::NoError || !doc.isObject()) {
            qWarning().noquote() << path << "is not valid JSON (" << err.errorString() << "); not modifying it.";
            return false;
        }
        settings = doc.object();
    }

    const QJsonObject statusLine = settings.value(QStringLiteral("statusLine")).toObject();
    const QString command = statusLine.value(QStringLiteral("command")).toString();
    if (command == wanted || command == configDir + QStringLiteral("/statusline.sh"))
        return true;

    if (!command.isEmpty()) {
        if (!force) {
            qWarning().noquote() << path << "already has a statusLine command (" << command << ")."
                                 << "Run with --force-setup to replace it with" << wanted;
            return false;
        }
        const QString backup = path + QStringLiteral(".bak-") + QDateTime::currentDateTime().toString(QStringLiteral("yyyyMMdd-HHmmss"));
        QFile::copy(path, backup);
        qInfo().noquote() << "Backed up settings to" << backup;
    }

    settings.insert(QStringLiteral("statusLine"), QJsonObject{
        {QStringLiteral("type"), QStringLiteral("command")},
        {QStringLiteral("command"), wanted},
        {QStringLiteral("padding"), 0},
    });

    if (!writeAtomically(path, QJsonDocument(settings).toJson(QJsonDocument::Indented))) {
        qWarning().noquote() << "Could not write" << path;
        return false;
    }
    qInfo().noquote() << "Configured statusLine in" << path;
    return true;
}
