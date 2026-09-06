# Dr460nized / GarudaRice portable installer for KDE Plasma 6

Reproduce Garuda Linux **Dr460nized** look-and-feel on Arch, Fedora, or Debian-family systems — without Garuda system packages (`garuda-hooks`, `garuda-update`, etc.).

## Requirements

- KDE **Plasma 6**
- `git`, `curl` or `wget`, and a working package manager (`pacman` / `dnf` / `apt`)
- Network access on first run (themes are fetched from GitLab/GitHub)

## Usage

```bash
chmod +x install.sh uninstall.sh
./install.sh                 # install themes, applets, fonts, fish/bash, Konsole
./install.sh --apply         # also reset panels/dock/wallpaper to Dr460nized
./install.sh --apply --yes   # non-interactive apply
./install.sh --shell-only    # only shell + starship + Konsole
./install.sh --user          # install under ~/.local (no root for theme files)
./install.sh --shell bash    # Konsole profile uses bash instead of fish
./uninstall.sh               # remove share files (keeps ~/.config)
```

`--apply` is destructive: it backs up existing configs to `~/.garuda-rice-backup-<timestamp>/`, then applies the Global Theme layout (top panel + dock).

After install without `--apply`, open **System Settings → Appearance → Global Theme → Dr460nized** (enable desktop layout if you want the panels).

Log out/in (or `plasmashell --replace &`) after applying.

## What gets installed

| Component | Source |
|-----------|--------|
| Dr460nized look-and-feel, plasma theme, Kvantum, layouts, Maldrakor | [garuda-dr460nized](https://gitlab.com/garuda-linux/themes-and-settings/settings/garuda-dr460nized) |
| Sweet GTK / Aurorae / cursors / colors / SDDM | [EliverLara/sweet](https://github.com/EliverLara/sweet) |
| BeautyLine + candy-icons | Garuda beautyline + EliverLara candy-icons |
| Panel Colorizer, window buttons/title, blurred wallpaper | respective GitHub projects |
| Fish + bash configs, Starship, Konsole Sweet profile | adapted from Garuda (distro-specific aliases) |

Shell aliases like `upd` map to `pacman` / `dnf` / `apt` depending on the host.

## Credits

Artwork and settings © Garuda Linux and theme authors (Sweet by EliverLara, etc.). This project only packages a portable installer; respect upstream licenses (typically GPL / theme licenses).
