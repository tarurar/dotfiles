# dotfiles

My primarily development tooling configuration files, managed with [chezmoi](https://www.chezmoi.io/).

## Installation

```bash
chezmoi init https://github.com/tarurar/dotfiles.git
chezmoi apply
```

## Post-Apply Setup

Some configurations require additional setup after `chezmoi apply`:

### Display Switch (VS Code zoom auto-adjustment)

Automatically adjusts VS Code window zoom level when switching between laptop and external displays on GNOME Wayland.

**Enable the service:**

```bash
systemctl --user daemon-reload
systemctl --user enable --now display-monitor.service
```

See [docs/display-switch-setup.md](docs/display-switch-setup.md) for full documentation.

### Voxtype Voice Dictation

Offline voice dictation with Voxtype, faster-whisper, ydotoold, and a NuPhy dongle reconnect workaround.

**Enable the user services:**

```bash
systemctl --user daemon-reload
systemctl --user enable --now ydotoold.service voxtype.service
```

**Install the NuPhy udev rule:**

```bash
sudo install -m 0644 ~/.config/voxtype/udev/81-nuphy-voxtype.rules /etc/udev/rules.d/81-nuphy-voxtype.rules
sudo udevadm control --reload-rules
sudo systemctl daemon-reload
```

**Install the Framework laptop keyboard hwdb remap:**

```bash
sudo install -m 0644 ~/.config/voxtype/hwdb/61-framework-voxtype-keyboard.hwdb /etc/udev/hwdb.d/61-framework-voxtype-keyboard.hwdb
sudo systemd-hwdb update
sudo udevadm trigger /dev/input/by-path/platform-i8042-serio-0-event-kbd
```

See [Voxtype setup guide](private_dot_config/voxtype/voice-dictation-setup-guide.md) for full documentation.

## Documentation

- [Display Switch Setup](docs/display-switch-setup.md) - Automatic VS Code window zoom switching on GNOME Wayland
- [Voxtype Setup](private_dot_config/voxtype/voice-dictation-setup-guide.md) - Offline voice dictation on GNOME Wayland
