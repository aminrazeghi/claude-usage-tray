#include "UsageWatcher.h"

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QJsonDocument>
#include <QJsonObject>
#include <QLocale>
#include <QtConcurrent/QtConcurrentRun>

namespace {

bool localeUses12h()
{
    return QLocale::system().timeFormat(QLocale::ShortFormat).contains(QLatin1String("ap"), Qt::CaseInsensitive);
}

QString formatTime(const QTime &t, bool dropZeroMinutes)
{
    if (!localeUses12h())
        return t.toString(QStringLiteral("HH:mm"));
    const bool dropMinutes = dropZeroMinutes && t.minute() == 0;
    return QLocale(QLocale::English).toString(t, dropMinutes ? QStringLiteral("h AP") : QStringLiteral("h:mm AP"));
}

} // namespace

UsageWatcher::UsageWatcher(QString name, QString configDir, QString usageFile, bool sharedProjects, QObject *parent)
    : QObject(parent)
    , m_name(std::move(name))
    , m_configDir(std::move(configDir))
    , m_sharedProjects(sharedProjects)
    , m_usageFile(std::move(usageFile))
{
    connect(&m_watcher, &QFileSystemWatcher::fileChanged, this, [this] {
        readUsageFile();
        ensureWatched();  // statusline.sh replaces the file via rename, which drops the watch
    });

    m_clock.setInterval(1000);
    connect(&m_clock, &QTimer::timeout, this, &UsageWatcher::tick);
    m_clock.start();

    m_scanTimer.setInterval(60 * 1000);
    connect(&m_scanTimer, &QTimer::timeout, this, &UsageWatcher::startScan);
    m_scanTimer.start();

    connect(&m_scan, &QFutureWatcher<TodayScanState>::finished, this, [this] {
        m_today = m_scan.result();
        emit todayChanged();
        emit scanningChanged();
        if (m_rescanPending) {
            m_rescanPending = false;
            startScan();
        }
    });

    refresh();
}

void UsageWatcher::refresh()
{
    readUsageFile();
    ensureWatched();
    readPlan();
    startScan();
}

void UsageWatcher::ensureWatched()
{
    if (QFile::exists(m_usageFile) && !m_watcher.files().contains(m_usageFile))
        m_watcher.addPath(m_usageFile);
}

void UsageWatcher::tick()
{
    // Polling fallback for when the watch was lost between rename and re-add.
    const QFileInfo info(m_usageFile);
    if (info.exists() && info.lastModified() != m_fileMtime) {
        readUsageFile();
        ensureWatched();
    }
    emit clockChanged();
}

void UsageWatcher::readUsageFile()
{
    QFile f(m_usageFile);
    if (!f.open(QIODevice::ReadOnly))
        return;
    m_fileMtime = QFileInfo(f).lastModified();

    const QJsonDocument doc = QJsonDocument::fromJson(f.readAll());
    if (!doc.isObject())
        return;  // mid-write or corrupt; keep the last good snapshot
    const QJsonObject root = doc.object();

    auto parseWindow = [](const QJsonValue &v) {
        LimitWindow w;
        const QJsonObject o = v.toObject();
        if (o.contains(QStringLiteral("used_percentage"))) {
            w.present = true;
            w.used = qBound(0.0, o.value(QStringLiteral("used_percentage")).toDouble(), 100.0);
            const qint64 resets = o.value(QStringLiteral("resets_at")).toInteger();
            if (resets > 0)
                w.resetsAt = QDateTime::fromSecsSinceEpoch(resets);
        }
        return w;
    };

    const QJsonObject limits = root.value(QStringLiteral("rate_limits")).toObject();
    m_fiveHour = parseWindow(limits.value(QStringLiteral("five_hour")));
    m_sevenDay = parseWindow(limits.value(QStringLiteral("seven_day")));
    m_model = root.value(QStringLiteral("model")).toString();
    const QStringList sessions = root.value(QStringLiteral("sessions")).toObject().keys();
    m_sessions = QSet<QString>(sessions.begin(), sessions.end());
    const qint64 updated = root.value(QStringLiteral("updated_at")).toInteger();
    m_updatedAt = updated > 0 ? QDateTime::fromSecsSinceEpoch(updated) : m_fileMtime;
    m_hasData = m_fiveHour.present || m_sevenDay.present;

    emit dataChanged();
    emit clockChanged();
}

void UsageWatcher::readPlan()
{
    // Claude Code keeps account info in $CLAUDE_CONFIG_DIR/.claude.json, or in
    // ~/.claude.json for ~/.claude when the variable is unset; use the newest.
    QFileInfo account(m_configDir + QStringLiteral("/.claude.json"));
    const QFileInfo legacy(QDir::homePath() + QStringLiteral("/.claude.json"));
    if (m_configDir == QDir::homePath() + QStringLiteral("/.claude") && legacy.exists()
        && (!account.exists() || legacy.lastModified() > account.lastModified()))
        account = legacy;

    QFile f(account.filePath());
    if (!f.open(QIODevice::ReadOnly))
        return;
    const QJsonObject oauth = QJsonDocument::fromJson(f.readAll()).object().value(QStringLiteral("oauthAccount")).toObject();
    QString org = oauth.value(QStringLiteral("organizationType")).toString();  // e.g. "claude_pro"

    QString plan;
    if (org.startsWith(QLatin1String("claude_"))) {
        org = org.mid(7);
        plan = org.left(1).toUpper() + org.mid(1);
    } else if (!org.isEmpty()) {
        plan = org;
    }
    if (plan != m_plan) {
        m_plan = plan;
        emit planChanged();
    }
}

void UsageWatcher::startScan()
{
    if (m_scan.isRunning()) {
        m_rescanPending = true;
        return;
    }
    const QString projectsDir = m_configDir + QStringLiteral("/projects");
    const std::optional<QSet<QString>> sessions = m_sharedProjects ? std::optional(m_sessions) : std::nullopt;
    m_scan.setFuture(QtConcurrent::run(scanToday, m_today, projectsDir, sessions));
    emit scanningChanged();
}

double UsageWatcher::effectiveUsed(const LimitWindow &w)
{
    if (!w.present)
        return 0;
    if (w.resetsAt.isValid() && w.resetsAt <= QDateTime::currentDateTime())
        return 0;
    return w.used;
}

QString UsageWatcher::resetText(const LimitWindow &w)
{
    if (!w.present || !w.resetsAt.isValid())
        return QStringLiteral("—");
    const QDateTime at = w.resetsAt.toLocalTime();
    const QDate today = QDate::currentDate();
    const qint64 days = today.daysTo(at.date());

    if (days <= 0)
        return QStringLiteral("Today ") + formatTime(at.time(), false);
    if (days == 1)
        return QStringLiteral("Tomorrow ") + formatTime(at.time(), true);
    if (days < 7)
        return QLocale(QLocale::English).toString(at.date(), QStringLiteral("ddd ")) + formatTime(at.time(), true);
    return QLocale(QLocale::English).toString(at.date(), QStringLiteral("MMM d ")) + formatTime(at.time(), true);
}

QString UsageWatcher::leftText(const LimitWindow &w)
{
    if (!w.present || !w.resetsAt.isValid())
        return QStringLiteral("—");
    const QString remaining = remainingText(w);
    return remaining.isEmpty() ? QStringLiteral("Reset") : remaining + QStringLiteral(" left");
}

QString UsageWatcher::remainingText(const LimitWindow &w)
{
    if (!w.present || !w.resetsAt.isValid())
        return QString();
    const qint64 secs = QDateTime::currentDateTime().secsTo(w.resetsAt);
    if (secs <= 0)
        return QString();

    const qint64 d = secs / 86400, h = (secs % 86400) / 3600, m = (secs % 3600) / 60;
    if (d > 0)
        return QStringLiteral("%1d %2h").arg(d).arg(h);
    if (h > 0)
        return QStringLiteral("%1h %2m").arg(h).arg(m);
    if (m > 0)
        return QStringLiteral("%1m").arg(m);
    return QStringLiteral("<1m");
}

QString UsageWatcher::todayTokensText() const
{
    const double t = double(m_today.tokens());
    if (t >= 1e6)
        return QString::number(t / 1e6, 'f', t >= 1e7 ? 0 : 1) + QLatin1Char('M');
    if (t >= 1e3)
        return QString::number(t / 1e3, 'f', t >= 1e4 ? 0 : 1) + QLatin1Char('K');
    return QString::number(qint64(t));
}

QString UsageWatcher::updatedText() const
{
    if (!m_updatedAt.isValid())
        return QStringLiteral("Waiting for Claude Code…");
    const qint64 secs = std::max<qint64>(0, m_updatedAt.secsTo(QDateTime::currentDateTime()));
    if (secs < 60)
        return QStringLiteral("Updated %1 sec ago").arg(secs);
    if (secs < 3600)
        return QStringLiteral("Updated %1 min ago").arg(secs / 60);
    if (secs < 86400)
        return QStringLiteral("Updated %1 h ago").arg(secs / 3600);
    return QStringLiteral("Updated ") + QLocale(QLocale::English).toString(m_updatedAt.toLocalTime().date(), QStringLiteral("MMM d"));
}
