# Voice Dictation Setup on Wayland

A comprehensive guide to the current Arch Linux, Hyprland, and Waybar setup for
offline voice dictation using Voxtype and faster-whisper. Ubuntu/GNOME notes are
retained where installation or compositor behavior differs.

## Overview

This guide documents the complete setup of a push-to-talk voice dictation system that:
- Works offline using local Whisper AI models
- Supports Russian and English with automatic language detection
- Uses GPU acceleration (Vulkan) for fast transcription
- Runs as a background service with auto-start

### System Specifications

| Component | Value |
|-----------|-------|
| OS | Arch Linux |
| Desktop | Hyprland 0.56.2 with Waybar 0.15.0 |
| Audio | PipeWire |
| GPU | AMD Radeon 890M (integrated) |
| Kernel | 7.2.2-arch1-1 |
| Voxtype | 1.0.1 (`voxtype-bin` 1.0.1-1) |

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

On Arch Linux:

```bash
sudo pacman -S --needed wtype wl-clipboard ydotool
```

On Ubuntu 24.04:

```bash
sudo apt update
sudo apt install -y wtype wl-clipboard
```

- **wtype** - Wayland text input. It does not work on GNOME (Issue 2), and the
  Voxtype service deliberately hides it on Hyprland (Issue 11).
- **wl-clipboard** - Wayland clipboard (`wl-copy`/`wl-paste`).
- **ydotool** - Kernel-level input used for the paste shortcut. Arch currently
  provides the required 1.0.4 release directly.

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

The current stable release is 1.0.1. On Arch Linux, install the prebuilt AUR
package. The explicit `aur/` prefix avoids a same-named package shadowing the
AUR package on systems that add another repository:

```bash
yay -S aur/voxtype-bin
```

On Ubuntu 24.04, download and install the release package:

```bash
cd /tmp
wget https://github.com/peteonrails/voxtype/releases/download/v1.0.1/voxtype_1.0.1-1_amd64.deb
sudo apt install ./voxtype_1.0.1-1_amd64.deb
```

The package includes CPU, Vulkan, and ONNX backend binaries under
`/usr/lib/voxtype/`. The `/usr/bin/voxtype` wrapper selects the active backend.

### Step 5: Download Whisper Model

Run interactive model selection:

```bash
voxtype setup model
```

Select **large-v3-turbo** (1.6 GB), the multilingual model used by this GPU
setup. Do not select a model ending in `.en`; those models support only
English.

**Note on alternative engines**: Voxtype supports ONNX engines such as
SenseVoice, Paraformer, and Moonshine, but these focus on other language and
latency tradeoffs. This setup keeps Whisper `large-v3-turbo` for Russian and
English auto-detection.

### Step 6: Enable GPU Acceleration

```bash
sudo voxtype setup gpu --enable
```

This auto-detects the best GPU backend. On the Framework AMD setup it selects Vulkan for faster Whisper inference.

### Step 7: Install ydotool v1.0.4

On Arch, Step 1 installs ydotool 1.0.4 from the official repository, including
`/usr/bin/ydotoold`. The following manual installation is only for Ubuntu
24.04, whose repository package is too old for this setup:

```bash
cd /tmp
wget https://github.com/ReimuNotMoe/ydotool/releases/download/v1.0.4/ydotool-release-ubuntu-latest
wget https://github.com/ReimuNotMoe/ydotool/releases/download/v1.0.4/ydotoold-release-ubuntu-latest

sudo mv ydotool-release-ubuntu-latest /usr/local/bin/ydotool
sudo mv ydotoold-release-ubuntu-latest /usr/local/bin/ydotoold
sudo chmod +x /usr/local/bin/ydotool /usr/local/bin/ydotoold
```

**Why ydotool is still needed**: In Voxtype 1.0.1, paste mode tries
`wtype → eitype → ydotool` for the paste shortcut. On GNOME Wayland, `wtype`
does not work (Issue 2). On Hyprland it works, but its temporary virtual
keyboard breaks Waybar's dynamic language indicator (Issue 11). The managed
Voxtype service therefore hides only `/usr/bin/wtype`, allowing paste mode to
fall through to the persistent `ydotoold` device. The native GNOME alternative
`eitype` remains available after a separate installation
(`cargo install eitype`).

### Step 8: Create ydotoold Systemd Service

The service file is managed by chezmoi at:

```bash
~/.config/systemd/user/ydotoold.service
```

After `chezmoi apply`, enable and start it:

```bash
systemctl --user daemon-reload
systemctl --user enable --now ydotoold
```

The managed Arch unit starts `/usr/bin/ydotoold`. If using the manual Ubuntu
installation from Step 7, change `ExecStart` to `/usr/local/bin/ydotoold`.

### Step 9: Configure Voxtype

Edit `~/.config/voxtype/config.toml`:

```toml
# State file for status integrations and record toggle
state_file = "auto"

[hotkey]
enabled = true             # Built-in evdev hotkey detection
key = "RIGHTMETA"          # Right Cmd/Super/Windows key
modifiers = []
mode = "toggle"            # Press to start, press to stop

[audio]
device = "default"
sample_rate = 16000
max_duration_secs = 180

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
paste_keys = "ctrl+shift+v"
fallback_to_clipboard = true
type_delay_ms = 0

[output.notification]
on_recording_start = false
on_recording_stop = false
on_transcription = true
```

Do not add `driver_order = ["ydotool", "clipboard"]` as a workaround for
Issue 11. Voxtype 1.0.1 parses that setting, but paste mode does not consult it
when choosing the backend that sends `paste_keys`; the paste implementation has
its own fixed `wtype → eitype → ydotool` sequence. The service-level restriction
in Step 10 is what prevents `wtype` from being selected.

Optional features such as the OSD, alternate engines, and
`[output.post_process]` grammar cleanup are intentionally left disabled in this
setup.

### Step 10: Enable Voxtype Auto-Start

The service file is managed by chezmoi at:

```bash
~/.config/systemd/user/voxtype.service
```

It points to `/usr/bin/voxtype -q daemon`, so the service uses the package
wrapper and the backend selected by `voxtype setup gpu`. On the Arch/Hyprland
host, it also contains:

```ini
InaccessiblePaths=/usr/bin/wtype
```

This systemd restriction hides `wtype` only inside the Voxtype service. The
binary stays installed and available to every other application. Since paste
mode can no longer detect or execute it, Voxtype falls through to `ydotool`,
whose long-lived daemon does not repeatedly add and remove keyboards from
Hyprland.

After `chezmoi apply`, reload the user manager and enable the services:

```bash
systemctl --user daemon-reload
systemctl --user enable --now voxtype
```

### Step 11: Install Framework AltGr Remap

The internal Framework Laptop 13 keyboard has no physical Right Meta key. To keep
Voxtype listening on `RIGHTMETA` for the external NuPhy keyboard while also
supporting laptop-only use, the laptop's AltGr key is remapped to `rightmeta`
with a systemd hwdb entry.

The hwdb source file is managed by chezmoi at:

```bash
~/.config/voxtype/hwdb/61-framework-voxtype-keyboard.hwdb
```

The rule uses the `evdev:atkbd:dmi` selector because the internal keyboard is
an AT keyboard exposed as `AT Translated Set 2 keyboard`. The product-name
match uses `pnLaptop13*` because udev sanitizes punctuation in the DMI modalias
before hwdb lookup.

Install it into the system hwdb directory and reload only the internal keyboard:

```bash
sudo install -m 0644 ~/.config/voxtype/hwdb/61-framework-voxtype-keyboard.hwdb /etc/udev/hwdb.d/61-framework-voxtype-keyboard.hwdb
sudo systemd-hwdb update
sudo udevadm trigger /dev/input/by-path/platform-i8042-serio-0-event-kbd
```

The rule is scoped to the internal `AT Translated Set 2 keyboard` on the
Framework Laptop 13 AMD Ryzen AI 300 model. It does not change the external
NuPhy keyboard.

## Issues Encountered and Solutions

### Issue 1: Input Group Not Taking Effect

**Symptom**: After running `sudo usermod -aG input $USER`, voxtype still reports user not in input group.

**Cause**: Closing terminal doesn't apply group changes - only the login session has the old groups.

**Solution**: Fully log out of the desktop session (or reboot), then log back
in.

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

**Cause**: The service uses a path from a different installation method. The
Arch package installs `/usr/bin/ydotoold`; the manual Ubuntu installation in
Step 7 installs `/usr/local/bin/ydotoold`.

**Solution**: Run `command -v ydotoold` and use the returned absolute path in
the service. The checked-in unit targets the current Arch package and therefore
uses `/usr/bin/ydotoold`.

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

### Issue 8: Right Cmd Hotkey Stops Working After Dongle Unplug/Replug

**Symptom**: After unplugging and replugging the NuPhy dongle, Right Cmd no longer triggers recording. Voxtype is still running but not listening to the keyboard.

**Cause**: Voxtype uses `inotify` on `/dev/input/` to detect new keyboard devices. When the dongle reconnects, voxtype intermittently fails to re-open the new `/dev/input/eventN` device nodes.

**Solution**: Automatically restart voxtype when the dongle reconnects via a udev rule + systemd service.

**Step 1** — Install the chezmoi-managed udev rule:

The source file is managed at `~/.config/voxtype/udev/81-nuphy-voxtype.rules`.
It must be installed into `/etc/udev/rules.d/` because udev only reads system rule directories.

```bash
sudo install -m 0644 ~/.config/voxtype/udev/81-nuphy-voxtype.rules /etc/udev/rules.d/81-nuphy-voxtype.rules
```

**Step 2** — Create the system service at `/etc/systemd/system/restart-voxtype.service`:

```ini
[Unit]
Description=Restart voxtype after NuPhy keyboard reconnect

[Service]
Type=oneshot
ExecStart=/usr/bin/systemctl --user -M tarurar@ restart voxtype
```

**Step 3** — Reload udev and systemd:

```bash
sudo udevadm control --reload-rules
sudo systemctl daemon-reload
```

**What the rule does**: It matches the NuPhy Air75 V3 USB dongle by vendor/product ID (`19f5:2620`) when the dongle is added, then asks systemd to start `restart-voxtype.service`. That oneshot service restarts the user `voxtype` daemon so it re-opens the new `/dev/input/eventN` keyboard devices.

**Why `TAG+="systemd"` instead of `RUN+=`**: udev workers run with a security sandbox that blocks all D-Bus (`AF_UNIX`) sockets. Any command in `RUN+=` that needs D-Bus (including `systemctl --user`) will silently fail. Using `TAG+="systemd"` with `SYSTEMD_WANTS` signals systemd directly via kernel netlink, bypassing the sandbox entirely.

**Note on username**: The service uses `-M tarurar@` to connect to the user session via system D-Bus. Replace `tarurar` with your username if setting up on a new machine.

### Issue 9: Voice Transcribed as "." (Dot) Only

**Symptom**: Recording works (beeps heard), but transcription always produces a single ".".

**Cause**: Whisper outputs "." when fed silent or near-silent audio. This happens when WirePlumber automatically switches the default PipeWire source to a newly connected device (e.g., TRRS headphones) and initializes it at a very low volume (0.20 = 20%), too quiet for Whisper to detect speech.

**Diagnosis**:

```bash
# Check current default source and its volume
wpctl status | grep -A5 Sources
wpctl get-volume @DEFAULT_SOURCE@
```

**Solution**: Set the correct default source and ensure its volume is 1.0:

```bash
# List all available sources with IDs
wpctl status

# Set default source (replace ID with the correct one)
wpctl set-default <source-id>

# Set volume to 100%
wpctl set-volume @DEFAULT_SOURCE@ 1.0
```

**TRRS headphone cable note**: A headphone cable with **2 black rings** (TRRS connector) includes a microphone. WirePlumber will detect and expose this as a separate audio source. The microphone works correctly at volume 1.0.

### Issue 10: Laptop Keyboard Has No Right Meta Key

**Symptom**: Voxtype is configured for `RIGHTMETA`, which works on the external
NuPhy Air75 V3 but cannot be triggered from the laptop keyboard because the
Framework internal keyboard has no physical Right Meta key.

**Cause**: Voxtype has a single built-in evdev hotkey (`[hotkey].key` /
`--hotkey <KEY>`). There is no native config for `RIGHTMETA` OR `RIGHTALT`.

**Solution**: Keep Voxtype configured for `RIGHTMETA` and remap the laptop-only
AltGr key to `rightmeta` with systemd hwdb. Diagnostics showed AltGr on
`/dev/input/event2` emits scan code `b8` as `KEY_RIGHTALT`, so the managed hwdb
rule maps `KEYBOARD_KEY_b8=rightmeta` for the Framework internal keyboard only.

### Issue 11: Waybar Language Indicator Disappears After Transcription

**Applies to**: Arch Linux with Hyprland and Waybar. Reproduced with Voxtype
1.0.1, Hyprland 0.56.2, and Waybar 0.15.0.

**Symptom**: If `EN` or `RU` is visible before dictation, it disappears when
transcription completes. If the indicator is already missing, it briefly
appears at completion and immediately disappears again. Switching the physical
keyboard layout restores it until the next transcription.

**Cause**: Paste mode copies the transcription with `wl-copy` and then sends
`Ctrl+Shift+V`. Its keystroke backend selection is hardcoded to try `wtype`
first, independently of `[output].driver_order`. On Hyprland, each `wtype`
process registers a temporary virtual keyboard. Its layout event briefly gives
Waybar a value to display, but the device has already disappeared when Waybar
resolves it, so the unpinned `hyprland/language` module clears its label.

The behavior can be reproduced without VoxType or any typed text:

```bash
wtype ''
```

**Solution**: Keep Waybar unpinned so it can follow both the NuPhy and the
laptop keyboard. Hide `wtype` only from the Voxtype systemd service and let its
paste implementation fall through to the already persistent `ydotoold` device:

```ini
[Service]
InaccessiblePaths=/usr/bin/wtype
ExecStart=/usr/bin/voxtype -q daemon
```

Apply and verify the workaround without rebooting:

```bash
systemctl --user daemon-reload
systemctl --user enable --now ydotoold.service
systemctl --user restart voxtype.service waybar.service
systemctl --user show voxtype.service -p InaccessiblePaths
```

Expected output:

```text
InaccessiblePaths=/usr/bin/wtype
```

The global command `wtype` remains available; only the Voxtype service sees it
as inaccessible. A real transcription test retained the language label before
and at three checkpoints up to one second after returning to `idle`, with no
`wtype` layout event.

**Rejected workarounds**:

- `keyboard-name` in Waybar prevents the label from following the other
  physical keyboard when switching between docked and laptop-only use.
- `min-length` only reserves visual width and does not prevent Waybar from
  clearing the label state.
- `[output].driver_order` affects the general output chain but is ignored by
  the paste shortcut selection in Voxtype 1.0.1.
- A full reboot is unnecessary; reloading systemd and restarting Voxtype and
  Waybar is sufficient.

## Upgrading Voxtype

As of September 4, 2026, 1.0.1 is the latest stable GitHub release and is also
the version installed on the current Arch host. Update it and restart the
daemon with:

```bash
yay -S aur/voxtype-bin
sudo voxtype setup gpu --enable
systemctl --user restart voxtype.service
voxtype --version
```

For Debian/Ubuntu, download the 1.0.1 `.deb` shown in Step 4 and install it with
`apt`. The package uses the `/usr/bin/voxtype` wrapper to select the configured
backend variant.

The Waybar workaround remains required in 1.0.1. It is also still required by
the current `dev` branch at the time of writing: its paste implementation still
selects the shortcut backend with a fixed `wtype → eitype → ydotool` sequence.

### Historical migration from v0.6.4 to v0.7.5

1. Stop the service: `systemctl --user stop voxtype`
2. Download and install: `sudo apt install ./voxtype_0.7.5-1_amd64.deb`
3. Enable the wrapper-selected GPU backend: `sudo voxtype setup gpu --enable`
4. Update the user service to start `/usr/bin/voxtype -q daemon`
5. Restart: `systemctl --user daemon-reload && systemctl --user restart voxtype`
6. Verify: `voxtype --version`, `voxtype setup gpu --status`, and `voxtype info variants`

**What changed**: v0.7.5 uses the `/usr/bin/voxtype` wrapper to select installed backend variants. The previous direct `/usr/lib/voxtype/voxtype-vulkan daemon` service path is replaced with the wrapper.

## Final Configuration Summary

| Component | Version/Setting |
|-----------|-----------------|
| Voxtype | 1.0.1 (`voxtype-bin` 1.0.1-1, wrapper-selected Vulkan backend) |
| Whisper model | large-v3-turbo (1.6 GB) |
| ydotool | 1.0.4 |
| Hotkey | Right Cmd / laptop AltGr via hwdb remap (toggle mode) |
| Output mode | paste; wtype hidden inside service so shortcut uses ydotoold |
| Language | auto-detect |
| GPU | Vulkan enabled (AMD Radeon 890M) |
| Auto-start | chezmoi-managed systemd user services |

## Usage

1. Press **Right Cmd** on NuPhy or **AltGr** on the laptop to start recording (beep sound)
2. Speak in Russian or English
3. Press the same key again to stop (beep sound)
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

# Check the service-local wtype restriction
systemctl --user show voxtype.service -p InaccessiblePaths

# Run voxtype with verbose logging (for debugging)
systemctl --user stop voxtype
voxtype -vv daemon

# Check version
voxtype --version

# Check active backend variant
voxtype setup gpu --status
voxtype info variants

# Check default audio source and volume (if transcription returns ".")
wpctl status
wpctl get-volume @DEFAULT_SOURCE@
wpctl set-volume @DEFAULT_SOURCE@ 1.0

# Check udev auto-restart service (after dongle replug)
sudo journalctl -u restart-voxtype.service --since "5 minutes ago"

# Install/update the NuPhy voxtype udev rule from chezmoi-managed source
sudo install -m 0644 ~/.config/voxtype/udev/81-nuphy-voxtype.rules /etc/udev/rules.d/81-nuphy-voxtype.rules
sudo udevadm control --reload-rules

# Install/update the Framework laptop AltGr -> Right Meta hwdb remap
sudo install -m 0644 ~/.config/voxtype/hwdb/61-framework-voxtype-keyboard.hwdb /etc/udev/hwdb.d/61-framework-voxtype-keyboard.hwdb
sudo systemd-hwdb update
sudo udevadm trigger /dev/input/by-path/platform-i8042-serio-0-event-kbd

# Verify the laptop AltGr key now emits KEY_RIGHTMETA
sudo evtest /dev/input/by-path/platform-i8042-serio-0-event-kbd
```

## References

- [Voxtype](https://voxtype.io/) - Official website
- [Voxtype GitHub](https://github.com/peteonrails/voxtype) - Source code and
  releases
- [Voxtype 1.0.1 release](https://github.com/peteonrails/voxtype/releases/tag/v1.0.1) -
  Current stable release and Arch upgrade command
- [Voxtype installation guide](https://github.com/peteonrails/voxtype/blob/dev/docs/INSTALL.md) -
  Current package names and distro instructions
- [Voxtype 1.0.1 paste implementation](https://github.com/peteonrails/voxtype/blob/v1.0.1/src/output/paste.rs) -
  Released hardcoded paste shortcut backend sequence
- [Voxtype development paste implementation](https://github.com/peteonrails/voxtype/blob/dev/src/output/paste.rs) -
  Sequence still present after the latest stable release
- [Voxtype issue #306](https://github.com/peteonrails/voxtype/issues/306) -
  Analysis of paste mode ignoring `driver_order`
- [ydotool GitHub](https://github.com/ReimuNotMoe/ydotool) -
  Wayland-compatible input automation
- [soupawhisper](https://github.com/ksred/soupawhisper) - Original X11
  reference project
- [faster-whisper](https://github.com/SYSTRAN/faster-whisper) - Optimized
  Whisper implementation

---

*Last updated: September 4, 2026 (updated the documented deployment to Voxtype
1.0.1 on Arch/Hyprland and isolated wtype from paste mode to preserve Waybar's
dynamic language indicator)*
