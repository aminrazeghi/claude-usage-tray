#!/usr/bin/env bash
# claude-usage-monitor statusline v3
#
# Claude Code runs this on every status line refresh and passes session JSON on
# stdin. We record the subscription rate limits for the tray app, then print a
# compact status line.
#
# One copy lives in each Claude config directory, and its location picks the
# snapshot file: ~/.claude -> /tmp/claude-usage.json,
# ~/.claude-<name> -> /tmp/claude-usage-<name>.json, any other folder ->
# /tmp/claude-usage-<folder>.json. $CLAUDE_USAGE_FILE overrides.
# This file is managed by claude-usage-monitor; remove the line above to keep
# your own edits from being overwritten.

config_dir=$(basename "$(dirname "${BASH_SOURCE[0]}")")
case "$config_dir" in
    .claude) suffix="" ;;
    .claude-*) suffix="${config_dir#.claude-}" ;;
    *) suffix="${config_dir#"${config_dir%%[!.]*}"}" ;;  # folder name without leading dots
esac
OUT="${CLAUDE_USAGE_FILE:-/tmp/claude-usage${suffix:+-$suffix}.json}"
input=$(cat)

if ! command -v jq >/dev/null 2>&1; then
    echo "Claude (install jq for usage stats)"
    exit 0
fi

prev='{}'
if [ -r "$OUT" ]; then
    prev=$(jq -c 'if type == "object" then . else {} end' "$OUT" 2>/dev/null) || prev='{}'
fi

# rate_limits is absent before the first API response and on API-key sessions,
# so merge with the previous snapshot instead of wiping it.
tmp=$(mktemp "${OUT}.XXXXXX" 2>/dev/null) && {
    if jq -c --argjson prev "$prev" --argjson now "$(date +%s)" '
        {
            updated_at: $now,
            session_id: .session_id,
            model: .model.display_name,
            cwd: .workspace.current_dir,
            version: .version,
            context_used_percentage: .context_window.used_percentage,
            session_cost_usd: .cost.total_cost_usd,
            rate_limits: ((($prev.rate_limits // {}) + (.rate_limits // {})) | if . == {} then null else . end),
            # Sessions this account ran in the last two days. Config dirs can
            # share a projects/ folder, so the app uses these to tell whose
            # transcripts are whose.
            sessions: (($prev.sessions // {})
                       + (if .session_id then {(.session_id): $now} else {} end)
                       | with_entries(select(.value > $now - 172800)))
        }' <<<"$input" >"$tmp" 2>/dev/null; then
        mv -f "$tmp" "$OUT"
    else
        rm -f "$tmp"
    fi
}

jq -r '
    def pct(x): "\(x | floor)%";
    [
        (.model.display_name // "Claude"),
        (.rate_limits.five_hour.used_percentage // empty | "5h \(pct(.))"),
        (.rate_limits.seven_day.used_percentage // empty | "7d \(pct(.))"),
        (.context_window.used_percentage // empty | "ctx \(pct(.))")
    ] | join(" · ")' <<<"$input" 2>/dev/null || echo "Claude"
