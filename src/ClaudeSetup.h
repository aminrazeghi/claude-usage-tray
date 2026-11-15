#pragma once

#include <QList>
#include <QString>

// Integration with Claude Code: finds the config directories (one per
// subscription) and wires each one's status line to report usage.
namespace ClaudeSetup {

struct Profile
{
    QString name;       // "Main" for ~/.claude, "Work" for ~/.claude-work
    QString configDir;  // what CLAUDE_CONFIG_DIR points at
    QString usageFile;  // where that profile's statusline.sh writes its snapshot
};

// ~/.claude plus every ~/.claude-<name> that Claude Code has used
// (it holds a .claude.json or projects/). ~/.claude always comes first.
QList<Profile> discoverProfiles();

// Mirrors statusline.sh: /tmp/claude-usage.json for ~/.claude,
// /tmp/claude-usage-<name>.json for ~/.claude-<name>.
QString usageFileFor(const QString &configDir);

// Installs (or upgrades) our statusline script in configDir. A statusline.sh
// that we did not write is left untouched. Returns true when ours is in place.
bool installStatuslineScript(const QString &configDir);

// Sets statusLine.command in configDir/settings.json when it is missing. A
// different, user-configured command is only replaced when force is set (a
// backup is written first).
bool configureSettings(const QString &configDir, bool force);

} // namespace ClaudeSetup
