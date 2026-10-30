# Lorien rice

Ciemny, minimalistyczny wygląd dla **KDE Plasma 6** i **GNOME** na Archu (EndeavourOS, CachyOS). Akcent kolorystyczny dobiera się sam do tapety, również do animowanej tapety z Wallpaper Engine.

## Co dostajesz

**KDE Plasma**
- Przezroczysty górny pasek z „wyspami” (Panel Colorizer): CPU, RAM, sieć, bateria, wizualizer dźwięku.
- Pływający dok na dole.
- Minimalne kafelki na pulpicie w dwóch kolumnach po bokach:
  - pogoda, zegar binarny, odtwarzacz, Pokémon dnia, terminale;
  - system, sieć, bateria, dyski, aktualizacje, notatka.
- Ramki okien w stylu Hyprlanda (KDE Rounded Corners) w kolorze akcentu.
- Czcionka JetBrains Mono, kolory system24, ikony Qogir.
- Skróty:
  - `Super+Q` zamyka okno;
  - `Super+Enter` otwiera Konsolę;
  - `Super+Shift+S` robi zrzut obszaru;
  - `Super+strzałki` układają okna.

**GNOME**
- Lorien Bar: przezroczysty pasek z czarnymi „pigułkami” jak wyspa Isle; po otwarciu menu przycisk wypełnia się kolorem akcentu.
- Isle (wyspa na środku paska), Dash to Dock, ArcMenu, Vitals, Blur my Shell.
- Foldery w siatce aplikacji.
- Mniejsze, ciemne paski tytułowe w aplikacjach Qt i Electron.
- Te same skróty co w KDE, plus `Super+E` do otwierania plików.

**Wspólne**
- Waywallen, czyli tapety z Wallpaper Engine na Waylandzie.
- Akcent z tapety: zmienia się razem z tapetą, a bez Wallpaper Engine bierze kolor ze zwykłej tapety.
- `updateall` aktualizuje wszystko: pacman i AUR, flatpak, firmware, rust, distrobox, oh-my-zsh, tldr. `updateall --check` tylko pokazuje, co czeka.
- `ramka` przebudowuje ramki okien po aktualizacji KDE.

## Instalacja

```bash
git clone https://github.com/<użytkownik>/lorien-rice.git
cd lorien-rice
./install.sh
```

Instalator:
1. Pokazuje listę pakietów i pyta przed instalacją (`packages.txt` i `packages-aur.txt`; doinstaluje `yay`, jeśli go nie masz).
2. Zapisuje kopię Twoich ustawień w `~/lorien-backup-<data>`.
3. Pyta o miasto do kafelka pogody.
4. Buduje ramki okien i paski tytułowe; `sudo` zapyta o hasło.
5. W sesji KDE pyta, czy zastąpić panele nowym układem.

Na końcu **wyloguj się i zaloguj ponownie**.

Opcje:
- `--kde` / `--gnome`: tylko jeden pulpit.
- `--city Kraków`: miasto bez pytania.
- `--yes`: bez pytań.
- `--no-packages`, `--no-build`, `--no-apply`: pomija dany krok.

Jeśli instalujesz z GNOME, a chcesz mieć też KDE, zaloguj się później do Plasmy i uruchom:

```bash
~/.local/share/lorien-rice/apply-kde.sh
```

## Tapety Wallpaper Engine

Waywallen korzysta z tapet z **Twojego** Steama: potrzebujesz kupionego Wallpaper Engine i pobranych tapet z Warsztatu. Otwórz Waywallen z zasobnika, wskaż bibliotekę Steama i wybierz tapetę. W KDE ustaw tapetę pulpitu na „Waywallen” (Prawy klik na pulpicie → Konfiguruj pulpit i tapetę).

Bez Wallpaper Engine wszystko działa na zwykłej tapecie, a akcent bierze z niej kolor.

## Po aktualizacjach

- **Po aktualizacji KDE** ramki okien mogą zniknąć. Zaloguj się ponownie i wpisz `ramka`.
- **Gdy `yay` zaktualizuje `qadwaitadecorations-qt6`**, paski tytułowe w GNOME wrócą do dużych. Przebuduj je:
  ```bash
  ./install.sh --gnome --no-packages --no-apply
  ```

## Odinstalowanie

```bash
./uninstall.sh
```

Przywraca ustawienia z najnowszej kopii `~/lorien-backup-*` i usuwa pliki Lorien. Pakiety zostają.

## Podziękowania

- [mayanklad/cachyos-kde-pixel-rice](https://github.com/mayanklad/cachyos-kde-pixel-rice): presety Panel Colorizera, punkt wyjścia.
- [refact0r/system24](https://github.com/refact0r/system24): paleta kolorów.
- [luisbocanegra](https://github.com/luisbocanegra): Panel Colorizer i Audio Visualizer.
- [matinlotfali/KDE-Rounded-Corners](https://github.com/matinlotfali/KDE-Rounded-Corners), [zickrian/isle](https://github.com/zickrian/isle), [Waywallen](https://github.com/waywallen/waywallen), [QAdwaitaDecorations](https://github.com/FedoraQt/QAdwaitaDecorations), [pokemon-colorscripts](https://gitlab.com/phoneybadger/pokemon-colorscripts).

Licencja: GPL-3.0-or-later (zobacz `LICENSE`).
