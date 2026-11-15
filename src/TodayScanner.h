#pragma once

#include <QDate>
#include <QHash>
#include <QSet>
#include <QString>

#include <optional>

// Incremental scan of Claude Code transcripts (~/.claude/projects/**/*.jsonl)
// for today's assistant messages and token usage. The state is passed by value
// so a scan can run on a worker thread and hand the result back.
struct TodayScanState
{
    QDate day;
    QHash<QString, qint64> fileOffsets;  // bytes already consumed per transcript
    QHash<QString, qint64> tokensById;   // assistant message id -> input + output tokens

    int messages() const { return int(tokensById.size()); }
    qint64 tokens() const;
};

// When `sessions` is set, only transcripts of those session ids are counted;
// used when several config directories share one projects/ folder.
TodayScanState scanToday(TodayScanState state, const QString &projectsDir,
                         const std::optional<QSet<QString>> &sessions = std::nullopt);
