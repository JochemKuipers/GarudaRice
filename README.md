# Dr460nized / GarudaRice — portable Garuda KDE rice (Plasma 6)

## Quick install

```bash
git clone --depth 1 https://github.com/JochemKuipers/GarudaRice.git && cd GarudaRice && ./install.sh
```

Apply the desktop layout in the same go:

```bash
git clone --depth 1 https://github.com/JochemKuipers/GarudaRice.git && cd GarudaRice && ./install.sh --apply
```

## Usage

```bash
./install.sh              # themes, applets, fish/bash, Konsole
./install.sh --apply      # also reset panels/dock/wallpaper
./install.sh --update     # refresh upstream themes (keeps your layout)
./install.sh --update --apply   # refresh + reset layout (rare)
./install.sh --shell-only
./install.sh --user       # ~/.local instead of /usr/local
./uninstall.sh
```

Needs Plasma 6, git, curl/wget, and pacman/dnf/apt. First run downloads Sweet, BeautyLine, candy-icons, plasmoids, and garuda-dr460nized from upstream.

`--update` pulls latest git sources, re-fetches the newest `garuda-dr460nized` tag, and reinstalls theme files. It does **not** reset panels — only add `--apply` when Garuda changes the dock/panel layout.

`--apply` backs up to `~/.garuda-rice-backup-<timestamp>/` then applies the Dr460nized Global Theme layout.

Credits: Garuda Linux, EliverLara/Sweet, and the plasmoid authors. This repo is only a portable installer.
