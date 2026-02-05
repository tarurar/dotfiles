# dotfiles

My primarily development tooling configuration files, managed with [chezmoi](https://www.chezmoi.io/).

## Installation

```bash
chezmoi init https://github.com/tarurar/dotfiles.git
chezmoi apply
```

## Post-Apply Setup

Some configurations require additional setup after `chezmoi apply`:

### Display Switch (VS Code font auto-adjustment)

Automatically adjusts VS Code font size when switching between laptop and external displays on GNOME Wayland.

**Enable the service:**

```bash
systemctl --user daemon-reload
systemctl --user enable --now display-monitor.service
```

See [docs/display-switch-setup.md](docs/display-switch-setup.md) for full documentation.

## Documentation

- [Display Switch Setup](docs/display-switch-setup.md) - Automatic VS Code font size switching on GNOME Wayland
