# Automatic VS Code Font Size Switching on GNOME Wayland

## Problem

When switching between a laptop display (13") and an external display (34"), VS Code font size needs adjustment:
- Laptop: font size 14
- External monitor: font size 18

Manually changing this setting every time is tedious.

## Solution Overview

On GNOME Wayland, we use:
1. **D-Bus** to detect connected monitors via `org.gnome.Mutter.DisplayConfig`
2. **dbus-monitor** to watch for `MonitorsChanged` signals
3. **sed** to update VS Code settings (JSONC format - jq cannot parse comments)
4. **systemd user service** to start the daemon on login

## Files

### 1. Main Script: `~/.local/bin/display-settings-switch`

```bash
#!/bin/bash
# Switch VS Code font size based on connected displays
# Auto-detects displays via GNOME Mutter D-Bus on Wayland
# Usage: display-settings-switch [laptop|external]

VSCODE_SETTINGS="$HOME/.config/Code/User/settings.json"
LOG_FILE="$HOME/.local/share/display-switch.log"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

# Detect connected monitors via D-Bus (GNOME Wayland)
detect_monitors() {
    gdbus call --session \
        --dest org.gnome.Mutter.DisplayConfig \
        --object-path /org/gnome/Mutter/DisplayConfig \
        --method org.gnome.Mutter.DisplayConfig.GetCurrentState 2>/dev/null
}

# Determine profile based on connected monitors
get_profile() {
    local monitors
    monitors=$(detect_monitors)

    if [ -z "$monitors" ]; then
        log "Could not detect monitors via D-Bus"
        echo "laptop"
        return
    fi

    # Count unique monitor entries (eDP, DP, HDMI, USB-C, DVI, VGA)
    local monitor_count
    monitor_count=$(echo "$monitors" | grep -oE "'(eDP|DP|HDMI|USB-C|DVI|VGA)-[0-9]+'" | sort -u | wc -l)

    log "Detected $monitor_count monitor(s)"

    if [ "$monitor_count" -gt 1 ]; then
        echo "external"
    else
        echo "laptop"
    fi
}

# Allow explicit profile override
if [ -n "$1" ]; then
    PROFILE="$1"
else
    sleep 2  # Wait for display to stabilize
    PROFILE=$(get_profile)
fi

log "Switching to profile: $PROFILE"

# Settings for each profile
case "$PROFILE" in
    laptop)
        VSCODE_FONT_SIZE=14
        ;;
    external)
        VSCODE_FONT_SIZE=18
        ;;
    *)
        log "Unknown profile: $PROFILE"
        exit 1
        ;;
esac

# Update VS Code settings (using sed for JSONC compatibility)
if [ -f "$VSCODE_SETTINGS" ]; then
    if grep -q '"editor.fontSize"' "$VSCODE_SETTINGS"; then
        sed -i 's/"editor\.fontSize": [0-9]*/"editor.fontSize": '"$VSCODE_FONT_SIZE"'/' "$VSCODE_SETTINGS"
        log "VS Code font size set to $VSCODE_FONT_SIZE"
    else
        log "editor.fontSize not found in VS Code settings"
    fi
fi

# Send notification
if command -v notify-send &> /dev/null; then
    notify-send -i display "Display Switch" "Profile: $PROFILE (VS Code: ${VSCODE_FONT_SIZE}px)"
fi

log "Switch complete"
```

### 2. Daemon Script: `~/.local/bin/display-monitor-daemon`

```bash
#!/bin/bash
# Monitor for display changes on GNOME Wayland via D-Bus
# Runs as a daemon and triggers display-settings-switch when monitors change

LAST_STATE=""
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
LOG_FILE="$HOME/.local/share/display-switch.log"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [daemon] $1" >> "$LOG_FILE"
}

get_monitor_state() {
    gdbus call --session \
        --dest org.gnome.Mutter.DisplayConfig \
        --object-path /org/gnome/Mutter/DisplayConfig \
        --method org.gnome.Mutter.DisplayConfig.GetCurrentState 2>/dev/null \
        | grep -oE "'(eDP|DP|HDMI|USB-C|DVI|VGA)-[0-9]+'" | sort -u | tr '\n' ','
}

log "Display monitor daemon started"

# Get initial state
LAST_STATE=$(get_monitor_state)
log "Initial state: $LAST_STATE"

# Monitor D-Bus for MonitorsChanged signal
dbus-monitor --session "type='signal',interface='org.gnome.Mutter.DisplayConfig',member='MonitorsChanged'" 2>/dev/null | \
while read -r line; do
    if echo "$line" | grep -q "MonitorsChanged"; then
        log "MonitorsChanged signal received"
        sleep 2  # Wait for display to stabilize

        NEW_STATE=$(get_monitor_state)
        if [ "$NEW_STATE" != "$LAST_STATE" ]; then
            log "State changed: $LAST_STATE -> $NEW_STATE"
            LAST_STATE="$NEW_STATE"
            "$SCRIPT_DIR/display-settings-switch"
        else
            log "Signal received but state unchanged"
        fi
    fi
done
```

### 3. Systemd Service: `~/.config/systemd/user/display-monitor.service`

```ini
[Unit]
Description=Monitor display changes and auto-switch settings
After=graphical-session.target
PartOf=graphical-session.target

[Service]
Type=simple
ExecStart=%h/.local/bin/display-monitor-daemon
Restart=on-failure
RestartSec=5

[Install]
WantedBy=graphical-session.target
```

## Usage

### Automatic

Connect or disconnect an external monitor - VS Code font size changes automatically.

### Manual

```bash
display-settings-switch laptop    # Set font size 14
display-settings-switch external  # Set font size 18
```

### Monitoring

```bash
# Check service status
systemctl --user status display-monitor

# View logs
tail -f ~/.local/share/display-switch.log
```

## Technical Notes

1. **Why not autorandr?** - autorandr uses xrandr which doesn't work on Wayland. It detects Wayland sessions and exits.

2. **Why sed instead of jq?** - VS Code settings.json uses JSONC (JSON with Comments). jq cannot parse comments and fails with "Invalid numeric literal" errors.

3. **Why D-Bus instead of udev?** - On GNOME Wayland, D-Bus provides the `MonitorsChanged` signal directly from Mutter, which is cleaner than udev rules that require complex user session handling.

4. **VS Code hot-reload** - VS Code automatically detects changes to settings.json and applies them without requiring a window reload.
