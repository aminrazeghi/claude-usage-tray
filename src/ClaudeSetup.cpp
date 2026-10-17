#include "ClaudeSetup.h"

#include <QDateTime>
#include <QDebug>
#include <QDir>
#include <QFile>
#include <QJsonDocument>
#include <QJsonObject>
#include <QSaveFile>

namespace {

const QString kScriptMarker = QStringLiteral("claude-usage-monitor statusline");
const QString kStatuslineCommand = QStringLiteral("~/.claude/statusline.sh");

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

} // namespace

QString ClaudeSetup::claudeDir()
{
    return QDir::homePath() + QStringLiteral("/.claude");
}

bool ClaudeSetup::installStatuslineScript()
{
    QDir().mkpath(claudeDir());
    const QString target = claudeDir() + QStringLiteral("/statusline.sh");
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

bool ClaudeSetup::configureSettings(bool force)
{
    const QString path = claudeDir() + QStringLiteral("/settings.json");
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
    const QString expanded = QString(kStatuslineCommand).replace(QStringLiteral("~"), QDir::homePath());
    if (command == kStatuslineCommand || command == expanded)
        return true;

    if (!command.isEmpty()) {
        if (!force) {
            qWarning().noquote() << "settings.json already has a statusLine command (" << command << ")."
                                 << "Run with --force-setup to replace it with" << kStatuslineCommand;
            return false;
        }
        const QString backup = path + QStringLiteral(".bak-") + QDateTime::currentDateTime().toString(QStringLiteral("yyyyMMdd-HHmmss"));
        QFile::copy(path, backup);
        qInfo().noquote() << "Backed up settings to" << backup;
    }

    settings.insert(QStringLiteral("statusLine"), QJsonObject{
        {QStringLiteral("type"), QStringLiteral("command")},
        {QStringLiteral("command"), kStatuslineCommand},
        {QStringLiteral("padding"), 0},
    });

    if (!writeAtomically(path, QJsonDocument(settings).toJson(QJsonDocument::Indented))) {
        qWarning().noquote() << "Could not write" << path;
        return false;
    }
    qInfo().noquote() << "Configured statusLine in" << path;
    return true;
}
