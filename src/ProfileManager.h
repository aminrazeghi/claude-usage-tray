#pragma once

#include <QList>
#include <QObject>
#include <QVariantList>

class UsageWatcher;

// The subscriptions being watched: ~/.claude, plus an optional second Claude
// config directory chosen in the popup's settings (default ~/.claude-work,
// shown only when it exists). Owns one UsageWatcher per profile.
class ProfileManager : public QObject
{
    Q_OBJECT

    Q_PROPERTY(QVariantList profiles READ profiles NOTIFY profilesChanged)
    // As entered in settings, e.g. "~/.claude-work"; empty for none.
    Q_PROPERTY(QString secondDir READ secondDir NOTIFY profilesChanged)
    Q_PROPERTY(QString secondName READ secondName NOTIFY profilesChanged)
    // Why the second profile isn't shown, or empty when it is (or is unset).
    Q_PROPERTY(QString secondProblem READ secondProblem NOTIFY profilesChanged)

public:
    ProfileManager(QString mainUsageFile, bool runSetup, bool forceSetup, QObject *parent = nullptr);

    QList<UsageWatcher *> watchers() const { return m_watchers; }
    QVariantList profiles() const;
    QString secondDir() const { return m_secondDir; }
    QString secondName() const { return m_secondName; }
    QString secondProblem() const { return m_secondProblem; }

    // Saves the second profile's directory and tab name (name may be empty
    // to derive it from the directory) and rebuilds the profile list.
    Q_INVOKABLE void setSecondProfile(const QString &dir, const QString &name);
    Q_INVOKABLE void refreshAll();

signals:
    void profilesChanged();

private:
    void rebuild();

    QString m_mainUsageFile;
    bool m_runSetup;
    bool m_forceSetup;
    QString m_secondDir;
    QString m_secondName;
    QString m_secondProblem;
    QList<UsageWatcher *> m_watchers;
};
