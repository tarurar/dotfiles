# Voice Dictation Setup on Ubuntu 24.04 with Wayland

A comprehensive guide to setting up offline voice dictation using Voxtype and faster-whisper on Ubuntu 24.04 with GNOME/Wayland.

## Overview

This guide documents the complete setup of a push-to-talk voice dictation system that:
- Works offline using local Whisper AI models
- Supports Russian and English with automatic language detection
- Uses GPU acceleration (Vulkan) for fast transcription
- Runs as a background service with auto-start

### System Specifications

| Component | Value |
|-----------|-------|
| OS | Ubuntu 24.04.3 LTS |
| Desktop | GNOME on Wayland |
| Audio | PipeWire |
| GPU | AMD Radeon (integrated) |
| Kernel | 6.17.8 |

## Why Not soupawhisper?

The original reference project [soupawhisper](https://github.com/ksred/soupawhisper) is designed for X11 and uses tools that don't work on Wayland:

| X11 Tool | Purpose | Wayland Status |
|----------|---------|----------------|
| xdotool | Keyboard simulation | Doesn't work |
| xclip | Clipboard | Doesn't work |
| pynput | Hotkey detection | Limited/broken |

For Wayland, we chose [Voxtype](https://github.com/peteonrails/voxtype) - a Rust-based alternative with native Wayland support.

## Installation Steps

### Step 1: Install Wayland Dependencies

```bash
sudo apt update
sudo apt install -y wtype wl-clipboard
```

- **wtype** - Wayland text input (installed as dependency, but doesn't work on GNOME — see Issue 2)
- **wl-clipboard** - Wayland clipboard (wl-copy/wl-paste)

### Step 2: Add User to Input Group

Required for global hotkey detection via evdev:

```bash
sudo usermod -aG input $USER
```

**Important**: This requires a full logout/login (not just closing terminal) for the group change to take effect.

### Step 3: Configure uinput Permissions

Allow the input group to access `/dev/uinput`:

```bash
echo 'KERNEL=="uinput", GROUP="input", MODE="0660"' | sudo tee /etc/udev/rules.d/80-uinput.rules
sudo udevadm control --reload-rules
sudo udevadm trigger
```

### Step 4: Install Voxtype

Download and install the .deb package:

```bash
cd /tmp
wget https://github.com/peteonrails/voxtype/releases/download/v0.6.4/voxtype_0.6.4-1_amd64.deb
sudo dpkg -i voxtype_0.6.4-1_amd64.deb
```

The package includes all backend binaries (CPU, Vulkan, ONNX variants). The Vulkan binary at `/usr/lib/voxtype/voxtype-vulkan` is used for AMD GPU acceleration.

**Note**: The package may not install the `/usr/bin/voxtype` wrapper correctly. If `voxtype` command is not found after install, create a symlink:

```bash
sudo ln -sf /usr/lib/voxtype/voxtype-vulkan /usr/bin/voxtype
```

### Step 5: Download Whisper Model

Run interactive model selection:

```bash
voxtype setup model
```

Select **large-v3-turbo** (1.6 GB) - the multilingual model recommended for GPU acceleration. Do NOT select models ending in `.en` as they only support English.

**Note on alternative engines**: Voxtype v0.6.0+ supports ONNX engines (SenseVoice, Paraformer, Moonshine, etc.), but these focus on CJK languages. For Russian + English auto-detect, Whisper `large-v3-turbo` remains the best choice.

### Step 6: Enable GPU Acceleration

```bash
sudo voxtype setup gpu --enable
```

This enables Vulkan-based GPU inference for faster transcription.

### Step 7: Install ydotool v1.0.4

The Ubuntu repository has an outdated version (0.1.8) that doesn't work reliably. Install v1.0.4 from GitHub:

```bash
cd /tmp
wget https://github.com/ReimuNotMoe/ydotool/releases/download/v1.0.4/ydotool-release-ubuntu-latest
wget https://github.com/ReimuNotMoe/ydotool/releases/download/v1.0.4/ydotoold-release-ubuntu-latest

sudo mv ydotool-release-ubuntu-latest /usr/local/bin/ydotool
sudo mv ydotoold-release-ubuntu-latest /usr/local/bin/ydotoold
sudo chmod +x /usr/local/bin/ydotool /usr/local/bin/ydotoold
```

**Why ydotool is still needed**: Voxtype's output driver fallback chain is `wtype → eitype → dotool → ydotool → clipboard`. On GNOME Wayland, wtype doesn't work (Issue 2). The native alternative `eitype` (using libei protocol) can replace ydotool but requires separate installation (`cargo install eitype`). Until eitype is installed, ydotool handles the Ctrl+V keystroke for paste mode.

### Step 8: Create ydotoold Systemd Service

Create the service file:

```bash
mkdir -p ~/.config/systemd/user

cat > ~/.config/systemd/user/ydotoold.service << 'EOF'
[Unit]
Description=ydotool daemon for virtual input
Documentation=man:ydotool(1)

[Service]
ExecStart=/usr/local/bin/ydotoold
Restart=on-failure
RestartSec=3

[Install]
WantedBy=default.target
EOF
```

Enable and start:

```bash
systemctl --user daemon-reload
systemctl --user enable --now ydotoold
```

### Step 9: Configure Voxtype

Edit `~/.config/voxtype/config.toml`:

```toml
# State file for status integrations and record toggle
state_file = "auto"

[hotkey]
enabled = true             # Must be explicit — v0.6.4 defaults to false
key = "RIGHTMETA"          # Right Cmd/Super/Windows key
modifiers = []
mode = "toggle"            # Press to start, press to stop

[audio]
device = "default"
sample_rate = 16000
max_duration_secs = 120

[audio.feedback]
enabled = true
theme = "default"
volume = 0.7

[whisper]
model = "large-v3-turbo"
language = "auto"          # Auto-detect Russian/English
translate = false

[output]
mode = "paste"             # Clipboard + Ctrl+V (required for Cyrillic)
fallback_to_clipboard = true
type_delay_ms = 0

[output.notification]
on_recording_start = false
on_recording_stop = false
on_transcription = true
```

**Important v0.6.4 config changes**:
- `hotkey.enabled = true` — must be set explicitly (new default is `false`)
- `state_file = "auto"` — new top-level setting for status integration

### Step 10: Enable Voxtype Auto-Start

```bash
voxtype setup systemd
```

This creates a systemd user service that starts automatically on login. The service file is at `~/.config/systemd/user/voxtype.service` and points to `/usr/lib/voxtype/voxtype-vulkan daemon`.

## Issues Encountered and Solutions

### Issue 1: Input Group Not Taking Effect

**Symptom**: After running `sudo usermod -aG input $USER`, voxtype still reports user not in input group.

**Cause**: Closing terminal doesn't apply group changes - only the login session has the old groups.

**Solution**: Full logout from GNOME desktop (or reboot), then log back in.

### Issue 2: wtype Doesn't Work on GNOME

**Symptom**: Error message: `Compositor does not support the virtual keyboard protocol`

**Cause**: GNOME's Mutter compositor doesn't implement the `wlr-virtual-keyboard` Wayland protocol that wtype requires.

**Solution**: Use ydotool instead, which uses `/dev/uinput` at the kernel level, bypassing the compositor. Alternatively, install `eitype` (`cargo install eitype`) which uses the libei protocol supported natively by GNOME 45+.

### Issue 3: Ubuntu's ydotool Package is Outdated

**Symptom**: ydotool works intermittently, `ydotoold backend unavailable` warnings.

**Cause**: Ubuntu 24.04 ships ydotool v0.1.8 which doesn't have proper daemon support.

**Solution**: Install v1.0.4 binaries from GitHub releases (see Step 7).

### Issue 4: ydotoold Service Fails to Start

**Symptom**: `Exit code 203/EXEC` when starting ydotoold service.

**Cause**: Service file pointed to `/usr/bin/ydotoold` but the new binary is in `/usr/local/bin/`.

**Solution**: Update service file to use correct path `/usr/local/bin/ydotoold`.

### Issue 5: /dev/uinput Permission Denied

**Symptom**: ydotool can't create virtual input device.

**Cause**: `/dev/uinput` is owned by root with mode 0600.

**Solution**: Add udev rule to give input group access (see Step 3).

### Issue 6: ydotool Doesn't Type Cyrillic

**Symptom**: Russian text appears as garbage or nothing.

**Cause**: ydotool sends keycodes, not Unicode characters. Cyrillic would require Russian keyboard layout active and correct keycode mapping.

**Solution**: Use `paste` mode instead of `type` mode. Text goes to clipboard via wl-copy (Unicode-safe), then ydotool just sends Ctrl+V.

### Issue 7: Right Cmd Hotkey Intermittently Fails to Start Recording

**Symptom**: Pressing Right Cmd does nothing. No beep, no recording. Works fine after pressing any other key first.

**Cause**: The external keyboard (NuPhy Air75 V3 via 2.4GHz dongle) enters **auto-sleep** after inactivity. The first key press wakes the keyboard and re-establishes the wireless link, but that key event is swallowed during wake-up and never reaches the host. Voxtype never sees the RIGHTMETA event.

**Solution**: Press any key (e.g., Shift) to wake the keyboard before pressing Right Cmd. Once the keyboard is awake (indicator light stops blinking), the hotkey works reliably.

**Alternative**: Disable auto-sleep entirely by pressing `Fn + ]` on the NuPhy keyboard. This ensures every key press is transmitted but increases battery usage.

## Upgrading Voxtype

### From v0.4.2 to v0.6.4

1. Stop the service: `systemctl --user stop voxtype`
2. Download and install: `sudo dpkg -i voxtype_0.6.4-1_amd64.deb`
3. Update `~/.config/voxtype/config.toml`:
   - Add `state_file = "auto"` at the top level
   - Add `enabled = true` under `[hotkey]` (new default is `false`)
4. Restart: `systemctl --user restart voxtype`
5. Verify: `/usr/lib/voxtype/voxtype-vulkan --version`

**What changed**: The v0.6.4 .deb package includes the Vulkan binary with the UTF-8/Cyrillic fix (previously required building from source). No need to rebuild from source.

## Final Configuration Summary

| Component | Version/Setting |
|-----------|-----------------|
| Voxtype | 0.6.4 (.deb package, Vulkan binary) |
| Whisper model | large-v3-turbo (1.6 GB) |
| ydotool | 1.0.4 |
| Hotkey | Right Cmd (toggle mode) |
| Output mode | paste |
| Language | auto-detect |
| GPU | Vulkan enabled (AMD Radeon 890M) |
| Auto-start | systemd user services |

## Usage

1. Press **Right Cmd** key to start recording (beep sound)
2. Speak in Russian or English
3. Press **Right Cmd** again to stop (beep sound)
4. Text is transcribed and pasted at cursor position
5. Notification shows the transcribed text

## Useful Commands

```bash
# View voxtype status
systemctl --user status voxtype

# Restart voxtype
systemctl --user restart voxtype

# Check ydotoold status
systemctl --user status ydotoold

# Run voxtype with verbose logging (for debugging)
systemctl --user stop voxtype
/usr/lib/voxtype/voxtype-vulkan -vv daemon

# Check version
/usr/lib/voxtype/voxtype-vulkan --version
```

## References

- [Voxtype](https://voxtype.io/) - Official website
- [Voxtype GitHub](https://github.com/peteonrails/voxtype) - Source code and releases
- [ydotool GitHub](https://github.com/ReimuNotMoe/ydotool) - Wayland-compatible input automation
- [soupawhisper](https://github.com/ksred/soupawhisper) - Original X11 reference project
- [faster-whisper](https://github.com/SYSTRAN/faster-whisper) - Optimized Whisper implementation

---

*Last updated: March 25, 2026 (upgraded to v0.6.4, added auto-sleep fix, removed obsolete build-from-source section)*
