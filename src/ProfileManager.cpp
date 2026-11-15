#include "ProfileManager.h"

#include "ClaudeSetup.h"
#include "UsageWatcher.h"

#include <QDir>
#include <QFileInfo>
#include <QSettings>

namespace {

const QString kSecondDirKey = QStringLiteral("profiles/secondDir");
const QString kSecondNameKey = QStringLiteral("profiles/secondName");
const QString kDefaultSecondDir = QStringLiteral("~/.claude-work");

QString expandHome(const QString &path)
{
    if (path == QLatin1String("~"))
        return QDir::homePath();
    if (path.startsWith(QLatin1String("~/")))
        return QDir::homePath() + path.mid(1);
    return path;
}

QString projectsDirOf(const QString &configDir)
{
    return QFileInfo(configDir + QStringLiteral("/projects")).canonicalFilePath();
}

} // namespace

ProfileManager::ProfileManager(QString mainUsageFile, bool runSetup, bool forceSetup, QObject *parent)
    : QObject(parent)
    , m_mainUsageFile(std::move(mainUsageFile))
    , m_runSetup(runSetup)
    , m_forceSetup(forceSetup)
{
    QSettings settings;
    m_secondDir = settings.value(kSecondDirKey, kDefaultSecondDir).toString();
    m_secondName = settings.value(kSecondNameKey).toString();
    rebuild();
}

QVariantList ProfileManager::profiles() const
{
    QVariantList list;
    for (UsageWatcher *watcher : m_watchers)
        list.append(QVariant::fromValue(static_cast<QObject *>(watcher)));
    return list;
}

void ProfileManager::setSecondProfile(const QString &dir, const QString &name)
{
    const QString trimmedDir = dir.trimmed();
    const QString trimmedName = name.trimmed();
    if (trimmedDir == m_secondDir && trimmedName == m_secondName)
        return;
    m_secondDir = trimmedDir;
    m_secondName = trimmedName;

    QSettings settings;
    settings.setValue(kSecondDirKey, m_secondDir);
    settings.setValue(kSecondNameKey, m_secondName);
    rebuild();
}

void ProfileManager::refreshAll()
{
    for (UsageWatcher *watcher : std::as_const(m_watchers))
        watcher->refresh();
}

void ProfileManager::rebuild()
{
    const QString mainDir = QDir::homePath() + QStringLiteral("/.claude");
    QList<ClaudeSetup::Profile> profiles{{QStringLiteral("Main"), mainDir, m_mainUsageFile}};

    m_secondProblem.clear();
    if (!m_secondDir.isEmpty()) {
        const QString dir = QDir::cleanPath(expandHome(m_secondDir));
        if (!QFileInfo(dir).isDir())
            m_secondProblem = QStringLiteral("Folder not found");
        else if (QFileInfo(dir).canonicalFilePath() == QFileInfo(mainDir).canonicalFilePath())
            m_secondProblem = QStringLiteral("That's the main account's folder");
        else
            profiles.append({m_secondName.isEmpty() ? ClaudeSetup::defaultProfileName(dir) : m_secondName,
                             dir, ClaudeSetup::usageFileFor(dir)});
    }

    if (m_runSetup) {
        for (const ClaudeSetup::Profile &profile : std::as_const(profiles)) {
            ClaudeSetup::installStatuslineScript(profile.configDir);
            ClaudeSetup::configureSettings(profile.configDir, m_forceSetup);
        }
    }

    // Profiles whose projects/ resolve to the same folder (e.g. a symlink)
    // split "Today" by session instead of counting each other's transcripts.
    const bool sharedProjects = profiles.size() > 1 && !projectsDirOf(profiles.at(0).configDir).isEmpty()
                                && projectsDirOf(profiles.at(0).configDir) == projectsDirOf(profiles.at(1).configDir);

    const QList<UsageWatcher *> old = m_watchers;
    m_watchers.clear();
    for (const ClaudeSetup::Profile &profile : std::as_const(profiles))
        m_watchers.append(new UsageWatcher(profile.name, profile.configDir, profile.usageFile, sharedProjects, this));

    emit profilesChanged();
    // Deleted only after QML and the tray have switched to the new watchers.
    for (UsageWatcher *watcher : old)
        watcher->deleteLater();
}
