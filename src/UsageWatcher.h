#pragma once

#include "TodayScanner.h"

#include <QDateTime>
#include <QFileSystemWatcher>
#include <QFutureWatcher>
#include <QObject>
#include <QTimer>

// Watches the usage snapshot written by statusline.sh and exposes it to QML.
class UsageWatcher : public QObject
{
    Q_OBJECT

    Q_PROPERTY(bool hasData READ hasData NOTIFY dataChanged)
    Q_PROPERTY(QString model READ model NOTIFY dataChanged)
    Q_PROPERTY(QString plan READ plan NOTIFY planChanged)

    // Percentages (0-100) are 0 once a window's reset time has passed.
    Q_PROPERTY(bool fiveHourKnown READ fiveHourKnown NOTIFY dataChanged)
    Q_PROPERTY(double fiveHourUsed READ fiveHourUsed NOTIFY clockChanged)
    Q_PROPERTY(QString fiveHourResetText READ fiveHourResetText NOTIFY clockChanged)
    Q_PROPERTY(QString fiveHourLeftText READ fiveHourLeftText NOTIFY clockChanged)
    Q_PROPERTY(QString fiveHourRemainingText READ fiveHourRemainingText NOTIFY clockChanged)

    Q_PROPERTY(bool sevenDayKnown READ sevenDayKnown NOTIFY dataChanged)
    Q_PROPERTY(double sevenDayUsed READ sevenDayUsed NOTIFY clockChanged)
    Q_PROPERTY(QString sevenDayResetText READ sevenDayResetText NOTIFY clockChanged)
    Q_PROPERTY(QString sevenDayLeftText READ sevenDayLeftText NOTIFY clockChanged)
    Q_PROPERTY(QString sevenDayRemainingText READ sevenDayRemainingText NOTIFY clockChanged)

    Q_PROPERTY(int todayMessages READ todayMessages NOTIFY todayChanged)
    Q_PROPERTY(QString todayTokensText READ todayTokensText NOTIFY todayChanged)
    Q_PROPERTY(bool scanning READ scanning NOTIFY scanningChanged)

    Q_PROPERTY(QString updatedText READ updatedText NOTIFY clockChanged)
    Q_PROPERTY(QString usageFile READ usageFile CONSTANT)

public:
    explicit UsageWatcher(QString usageFile, QObject *parent = nullptr);

    bool hasData() const { return m_hasData; }
    QString model() const { return m_model; }
    QString plan() const { return m_plan; }

    bool fiveHourKnown() const { return m_fiveHour.present; }
    double fiveHourUsed() const { return effectiveUsed(m_fiveHour); }
    QString fiveHourResetText() const { return resetText(m_fiveHour); }
    QString fiveHourLeftText() const { return leftText(m_fiveHour); }
    QString fiveHourRemainingText() const { return remainingText(m_fiveHour); }

    bool sevenDayKnown() const { return m_sevenDay.present; }
    double sevenDayUsed() const { return effectiveUsed(m_sevenDay); }
    QString sevenDayResetText() const { return resetText(m_sevenDay); }
    QString sevenDayLeftText() const { return leftText(m_sevenDay); }
    QString sevenDayRemainingText() const { return remainingText(m_sevenDay); }

    int todayMessages() const { return m_today.messages(); }
    QString todayTokensText() const;
    bool scanning() const { return m_scan.isRunning(); }

    QString updatedText() const;
    QString usageFile() const { return m_usageFile; }

    Q_INVOKABLE void refresh();

signals:
    void dataChanged();
    void planChanged();
    void clockChanged();
    void todayChanged();
    void scanningChanged();

private:
    struct LimitWindow
    {
        bool present = false;
        double used = 0;
        QDateTime resetsAt;
    };

    static double effectiveUsed(const LimitWindow &w);
    static QString resetText(const LimitWindow &w);
    static QString leftText(const LimitWindow &w);
    static QString remainingText(const LimitWindow &w);  // "4h 39m"; empty when unknown or passed

    void readUsageFile();
    void readPlan();
    void startScan();
    void tick();
    void ensureWatched();

    QString m_usageFile;
    QFileSystemWatcher m_watcher;
    QTimer m_clock;
    QTimer m_scanTimer;
    QDateTime m_fileMtime;

    bool m_hasData = false;
    QString m_model;
    QString m_plan;
    QDateTime m_updatedAt;
    LimitWindow m_fiveHour;
    LimitWindow m_sevenDay;

    TodayScanState m_today;
    QFutureWatcher<TodayScanState> m_scan;
    bool m_rescanPending = false;
};
