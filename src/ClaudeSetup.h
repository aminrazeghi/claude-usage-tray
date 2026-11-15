#pragma once

#include <QList>
#include <QString>

// Integration with Claude Code config directories (one per subscription):
// wires each one's status line to report usage.
namespace ClaudeSetup {

struct Profile
{
    QString name;       // tab label: "Main" for ~/.claude, e.g. "Work" for ~/.claude-work
    QString configDir;  // what CLAUDE_CONFIG_DIR points at
    QString usageFile;  // where that profile's statusline.sh writes its snapshot
};

// Mirrors statusline.sh: /tmp/claude-usage.json for ~/.claude,
// /tmp/claude-usage-<name>.json for ~/.claude-<name> (or any other folder,
// named after it).
QString usageFileFor(const QString &configDir);

// Tab label for a directory: "Work" for ~/.claude-work, "Account 2" for ~/.claude-2.
QString defaultProfileName(const QString &configDir);

// Installs (or upgrades) our statusline script in configDir. A statusline.sh
// that we did not write is left untouched. Returns true when ours is in place.
bool installStatuslineScript(const QString &configDir);

// Sets statusLine.command in configDir/settings.json when it is missing. A
// different, user-configured command is only replaced when force is set (a
// backup is written first).
bool configureSettings(const QString &configDir, bool force);

} // namespace ClaudeSetup
