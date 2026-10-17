#pragma once

#include <QString>

// First-launch integration with Claude Code: installs ~/.claude/statusline.sh
// and points the statusLine setting in ~/.claude/settings.json at it.
namespace ClaudeSetup {

QString claudeDir();

// Installs (or upgrades) our statusline script. A statusline.sh that we did
// not write is left untouched. Returns true when our script is in place.
bool installStatuslineScript();

// Sets statusLine.command when it is missing. A different, user-configured
// command is only replaced when force is set (a backup is written first).
bool configureSettings(bool force);

} // namespace ClaudeSetup
