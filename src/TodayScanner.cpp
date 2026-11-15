#include "TodayScanner.h"

#include <QDateTime>
#include <QDir>
#include <QDirIterator>
#include <QFile>
#include <QFileInfo>
#include <QJsonDocument>
#include <QJsonObject>

qint64 TodayScanState::tokens() const
{
    qint64 sum = 0;
    for (qint64 t : tokensById)
        sum += t;
    return sum;
}

namespace {

// Transcripts live at <project>/<session>.jsonl, and subagents' at
// <project>/<session>/subagents/<agent>.jsonl.
QString sessionOf(const QString &projectsDir, const QString &path)
{
    const QStringList parts = QDir(projectsDir).relativeFilePath(path).split(QLatin1Char('/'));
    if (parts.size() < 2)
        return QString();
    QString session = parts.at(1);
    if (session.endsWith(QLatin1String(".jsonl")))
        session.chop(6);
    return session;
}

void consumeLine(const QByteArray &line, const QDate &today, TodayScanState &state)
{
    // Cheap pre-filter: transcripts are compact JSON, most lines are not assistant turns.
    if (!line.contains("\"type\":\"assistant\""))
        return;

    const QJsonObject obj = QJsonDocument::fromJson(line).object();
    if (obj.value(QStringLiteral("type")).toString() != QLatin1String("assistant"))
        return;

    const QDateTime ts = QDateTime::fromString(obj.value(QStringLiteral("timestamp")).toString(), Qt::ISODateWithMs);
    if (!ts.isValid() || ts.toLocalTime().date() != today)
        return;

    const QJsonObject message = obj.value(QStringLiteral("message")).toObject();
    const QString id = message.value(QStringLiteral("id")).toString();
    if (id.isEmpty())
        return;

    const QJsonObject usage = message.value(QStringLiteral("usage")).toObject();
    const qint64 tokens = usage.value(QStringLiteral("input_tokens")).toInteger()
                          + usage.value(QStringLiteral("output_tokens")).toInteger();

    // One response is written as several lines (one per content block) sharing
    // the message id; the later lines carry the final output token count.
    qint64 &slot = state.tokensById[id];
    slot = std::max(slot, tokens);
}

} // namespace

TodayScanState scanToday(TodayScanState state, const QString &projectsDir, const std::optional<QSet<QString>> &sessions)
{
    const QDate today = QDate::currentDate();
    if (state.day != today) {
        state = TodayScanState();
        state.day = today;
    }
    const QDateTime midnight = today.startOfDay();

    QDirIterator it(projectsDir, {QStringLiteral("*.jsonl")}, QDir::Files, QDirIterator::Subdirectories);
    while (it.hasNext()) {
        const QString path = it.next();
        const QFileInfo info = it.fileInfo();
        if (info.lastModified() < midnight)
            continue;
        // Skipped files keep no offset, so a session attributed later is read in full.
        if (sessions && !sessions->contains(sessionOf(projectsDir, path)))
            continue;

        qint64 &offset = state.fileOffsets[path];
        if (info.size() < offset)
            offset = 0;  // file was rewritten
        if (info.size() == offset)
            continue;

        QFile f(path);
        if (!f.open(QIODevice::ReadOnly) || !f.seek(offset))
            continue;
        const QByteArray chunk = f.read(info.size() - offset);

        // Only consume complete lines; a partially written line is picked up next time.
        const qsizetype end = chunk.lastIndexOf('\n');
        if (end < 0)
            continue;
        qsizetype start = 0;
        while (start <= end) {
            const qsizetype nl = chunk.indexOf('\n', start);
            consumeLine(chunk.mid(start, nl - start), today, state);
            start = nl + 1;
        }
        offset += end + 1;
    }
    return state;
}
