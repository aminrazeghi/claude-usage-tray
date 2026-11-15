#!/usr/bin/env bash
# Install Claude Usage Monitor for the current user (no root needed).
#
#   curl -fsSL https://raw.githubusercontent.com/aminrazeghi/claude-usage-tray/main/install.sh | bash
#
# Downloads the portable build from the latest GitHub release into
# ~/.local/share/claude-usage-monitor, links the binary into ~/.local/bin,
# installs the icon and menu entry, and starts it on login.
#
# Options (with curl, pass them as: ... | bash -s -- --no-autostart):
#   --version vX.Y.Z   install a specific release instead of the latest
#   --no-autostart     don't add ~/.config/autostart entry
#   --no-start         don't launch the app after installing
#   --uninstall        remove everything this script installed

set -euo pipefail

REPO="aminrazeghi/claude-usage-tray"
APP="claude-usage-monitor"

DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
BIN_DIR="$HOME/.local/bin"
INSTALL_DIR="$DATA_HOME/$APP"
DESKTOP_FILE="$DATA_HOME/applications/$APP.desktop"
ICON_FILE="$DATA_HOME/icons/hicolor/scalable/apps/$APP.svg"
AUTOSTART_FILE="$CONFIG_HOME/autostart/$APP.desktop"

info() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33mwarning:\033[0m %s\n' "$*" >&2; }
die() { printf '\033[1;31merror:\033[0m %s\n' "$*" >&2; exit 1; }

stop_running() {
    # Only instances started from our install dir; a dev build is left alone.
    if pkill -f "^$INSTALL_DIR/usr/bin/$APP" 2>/dev/null; then
        info "Stopped the running instance"
        sleep 1
    fi
}

check_platform() {
    [ "$(uname -s)" = "Linux" ] || die "Claude Usage Monitor only runs on Linux (found $(uname -s))."
    case "$(uname -m)" in
        x86_64 | amd64) ;;
        *) die "Only x86_64 builds are published (found $(uname -m)). Build from source instead: https://github.com/$REPO" ;;
    esac
    for tool in curl tar; do
        command -v "$tool" >/dev/null 2>&1 || die "'$tool' is required."
    done
}

latest_tag() {
    # github.com/<repo>/releases/latest redirects to .../releases/tag/<tag>;
    # this avoids the rate-limited API and any JSON parsing.
    local url
    url=$(curl -fsSLI -o /dev/null -w '%{url_effective}' "https://github.com/$REPO/releases/latest") \
        || die "Could not reach GitHub."
    [[ "$url" == */releases/tag/* ]] || die "No release found for $REPO."
    printf '%s\n' "${url##*/}"
}

write_desktop_file() {
    local target="$1" extra="${2:-}"
    mkdir -p "$(dirname "$target")"
    cat >"$target" <<EOF
[Desktop Entry]
Type=Application
Name=Claude Usage
GenericName=Usage Monitor
Comment=Tray monitor for Claude usage limits
Exec=$INSTALL_DIR/usr/bin/$APP
Icon=$APP
Terminal=false
Categories=Utility;Development;
Keywords=claude;usage;limits;tray;
StartupNotify=false
$extra
EOF
}

install_app() {
    local tag="$1" autostart="$2" start="$3"
    local version="${tag#v}"
    local asset="$APP-$version-linux-x86_64.tar.gz"
    local url="https://github.com/$REPO/releases/download/$tag/$asset"

    local tmp
    tmp=$(mktemp -d)
    # Expanded now: the EXIT trap runs after this function's locals are gone.
    trap "rm -rf '$tmp'" EXIT

    info "Downloading $asset"
    curl -fL --progress-bar -o "$tmp/$asset" "$url" || die "Download failed: $url"
    tar -xzf "$tmp/$asset" -C "$tmp"
    [ -x "$tmp/$APP/usr/bin/$APP" ] || die "Unexpected archive layout in $asset."

    stop_running

    info "Installing to $INSTALL_DIR"
    mkdir -p "$(dirname "$INSTALL_DIR")"
    rm -rf "$INSTALL_DIR.old"
    [ -d "$INSTALL_DIR" ] && mv "$INSTALL_DIR" "$INSTALL_DIR.old"
    mv "$tmp/$APP" "$INSTALL_DIR"
    rm -rf "$INSTALL_DIR.old"

    # The binary finds its bundled Qt through its real path, so a symlink is enough.
    mkdir -p "$BIN_DIR"
    ln -sfn "$INSTALL_DIR/usr/bin/$APP" "$BIN_DIR/$APP"

    mkdir -p "$(dirname "$ICON_FILE")"
    cp "$INSTALL_DIR/usr/share/icons/hicolor/scalable/apps/$APP.svg" "$ICON_FILE"

    # Absolute Exec path: ~/.local/bin is often not on PATH for the session
    # that runs menu entries and autostart.
    write_desktop_file "$DESKTOP_FILE"
    command -v update-desktop-database >/dev/null 2>&1 \
        && update-desktop-database -q "$(dirname "$DESKTOP_FILE")" 2>/dev/null || true
    command -v gtk-update-icon-cache >/dev/null 2>&1 \
        && gtk-update-icon-cache -q -t "$DATA_HOME/icons/hicolor" 2>/dev/null || true

    if [ "$autostart" = 1 ]; then
        # Delay so the panel's tray host is up before the icon registers.
        write_desktop_file "$AUTOSTART_FILE" "X-GNOME-Autostart-enabled=true
X-GNOME-Autostart-Delay=5"
        info "Enabled autostart ($AUTOSTART_FILE)"
    else
        rm -f "$AUTOSTART_FILE"
    fi

    info "Installed Claude Usage Monitor $version"

    command -v jq >/dev/null 2>&1 \
        || warn "jq is not installed; the Claude Code status line needs it to report usage (e.g. sudo apt install jq)."
    if [ "${XDG_CURRENT_DESKTOP:-}" != "${XDG_CURRENT_DESKTOP#*GNOME}" ] && command -v gnome-extensions >/dev/null 2>&1; then
        gnome-extensions list --enabled 2>/dev/null | grep -qi appindicator \
            || warn "GNOME needs the AppIndicator extension for tray icons (Ubuntu: gnome-shell-extension-appindicator)."
    fi
    case ":$PATH:" in
        *":$BIN_DIR:"*) ;;
        *) warn "$BIN_DIR is not on your PATH; run the app as $INSTALL_DIR/usr/bin/$APP or from the app menu." ;;
    esac

    if [ "$start" = 1 ] && { [ -n "${DISPLAY:-}" ] || [ -n "${WAYLAND_DISPLAY:-}" ]; }; then
        nohup setsid "$INSTALL_DIR/usr/bin/$APP" >/dev/null 2>&1 </dev/null &
        info "Started. Look for the usage ring in your system tray."
    fi
}

uninstall_app() {
    stop_running
    rm -rf "$INSTALL_DIR" "$INSTALL_DIR.old"
    [ -L "$BIN_DIR/$APP" ] && rm -f "$BIN_DIR/$APP"
    rm -f "$DESKTOP_FILE" "$ICON_FILE" "$AUTOSTART_FILE"
    info "Uninstalled Claude Usage Monitor."
    info "Left in place: statusline.sh and the statusLine entry in settings.json of ~/.claude and each ~/.claude-*, and $CONFIG_HOME/$APP/."
}

main() {
    local tag="" autostart=1 start=1 uninstall=0
    while [ $# -gt 0 ]; do
        case "$1" in
            --version) [ $# -ge 2 ] || die "--version needs a tag, e.g. v0.1.2"; tag="$2"; shift ;;
            --no-autostart) autostart=0 ;;
            --no-start) start=0 ;;
            --uninstall) uninstall=1 ;;
            -h | --help) sed -n '2,15p' "$0" 2>/dev/null | sed 's/^# \{0,1\}//'; exit 0 ;;
            *) die "Unknown option: $1" ;;
        esac
        shift
    done

    if [ "$uninstall" = 1 ]; then
        uninstall_app
        return
    fi

    check_platform
    [ -n "$tag" ] || tag=$(latest_tag)
    [[ "$tag" == v* ]] || tag="v$tag"
    install_app "$tag" "$autostart" "$start"
}

# Everything runs from here, so a partially downloaded script does nothing.
main "$@"
