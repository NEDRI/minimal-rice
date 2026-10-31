# Lorien rice

A dark, minimal look for **KDE Plasma 6** and **GNOME** on Arch (EndeavourOS, CachyOS). The accent colour follows the wallpaper, including animated Wallpaper Engine wallpapers.

## What you get

**KDE Plasma**
- Transparent top bar with "islands" (Panel Colorizer): CPU, RAM, network, battery and an audio visualizer.
- Island: a black notch-style pill in the middle of the top bar, after [Isle](https://github.com/zickrian/isle) for GNOME. It shows the time, and the album art with dancing bars while music plays, or the focus timer. Click it and it springs open from the top edge of the screen into a card with Music, Focus and Calendar pages; plugging in the charger makes it peek with the battery level.
- Floating dock at the bottom.
- Minimal desktop tiles in two columns along the screen edges:
  - weather, binary clock, now playing, Pokémon of the day, terminals;
  - system, network, battery, disks, updates, a note.
- Hyprland-style window borders (KDE Rounded Corners) in the accent colour.
- JetBrains Mono font, system24 colours, Qogir icons.
- Shortcuts:
  - `Super+Q` closes the window;
  - `Super+Enter` opens Konsole;
  - `Super+Shift+S` takes a region screenshot;
  - `Super+arrows` tile windows.

**GNOME**
- Lorien Bar: a transparent top bar with black pills like the Isle island; when a menu is open, its button fills with the accent colour.
- Isle (the island in the middle of the bar), Dash to Dock, ArcMenu, Vitals, Blur my Shell.
- App folders in the app grid.
- Smaller, dark title bars for Qt and Electron apps.
- The same shortcuts as in KDE, plus `Super+E` to open Files.

**Both**
- Waywallen: Wallpaper Engine wallpapers on Wayland.
- Accent from the wallpaper: it changes with the wallpaper, and without Wallpaper Engine it takes the colour from the regular wallpaper.
- `updateall` updates everything: pacman and AUR, flatpak, firmware, rust, distrobox, oh-my-zsh, tldr. `updateall --check` only lists what is pending.
- `ramka` rebuilds the window borders after a KDE update.

## Installation

```bash
git clone https://github.com/NEDRI/minimal-rice.git
cd minimal-rice
./install.sh
```

The installer:
1. Shows the package list and asks before installing (`packages.txt` and `packages-aur.txt`; installs `yay` if you don't have it).
2. Saves a copy of your settings in `~/lorien-backup-<date>`.
3. Asks for your city for the weather tile.
4. Builds the window borders and the title bars; `sudo` will ask for your password.
5. In a KDE session, asks before replacing your panels with the new layout.

When it finishes, **log out and log back in**.

Options:
- `--kde` / `--gnome`: only one desktop.
- `--city Krakow`: set the city without asking.
- `--yes`: no questions.
- `--no-packages`, `--no-build`, `--no-apply`: skip that step.

If you install from GNOME and want KDE too, log in to Plasma later and run:

```bash
~/.local/share/lorien-rice/apply-kde.sh
```

## Wallpaper Engine wallpapers

Waywallen uses the wallpapers from **your own** Steam library: you need a purchased copy of Wallpaper Engine and wallpapers downloaded from the Workshop. Open Waywallen from the system tray, point it to your Steam library and pick a wallpaper. In KDE, set the desktop wallpaper type to "Waywallen" (right-click the desktop → Configure Desktop and Wallpaper).

Without Wallpaper Engine everything works with a regular wallpaper, and the accent takes its colour from it.

## After updates

- **After a KDE update** the window borders may disappear. Log out, log back in and run `ramka`.
- **When `yay` updates `qadwaitadecorations-qt6`**, the GNOME title bars go back to the large size. Rebuild them:
  ```bash
  ./install.sh --gnome --no-packages --no-apply
  ```

## Uninstalling

```bash
./uninstall.sh
```

Restores your settings from the newest `~/lorien-backup-*` copy and removes the Lorien files. Packages stay installed.

## Credits

- [mayanklad/cachyos-kde-pixel-rice](https://github.com/mayanklad/cachyos-kde-pixel-rice): Panel Colorizer presets, the starting point.
- [refact0r/system24](https://github.com/refact0r/system24): colour palette.
- [luisbocanegra](https://github.com/luisbocanegra): Panel Colorizer and Audio Visualizer.
- [matinlotfali/KDE-Rounded-Corners](https://github.com/matinlotfali/KDE-Rounded-Corners), [zickrian/isle](https://github.com/zickrian/isle) (also the design the KDE island follows), [Waywallen](https://github.com/waywallen/waywallen), [QAdwaitaDecorations](https://github.com/FedoraQt/QAdwaitaDecorations), [pokemon-colorscripts](https://gitlab.com/phoneybadger/pokemon-colorscripts).

License: GPL-3.0-or-later (see `LICENSE`).
