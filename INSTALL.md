<p align="right">
  <a href="INSTALL.md"><img src="assets/flag-de.png" width="16" height="12" alt="Deutsch" title="Zur deutschen Version wechseln" /></a>  
  <a href="INSTALL.en.md"><img src="assets/flag-gb.png" width="16" height="12" alt="English" title="Switch to English" /></a>  
  <a href="INSTALL.ru.md"><img src="assets/flag-ru.png" width="16" height="12" alt="Русский" title="Переключиться на русскую версию" /></a>
</p>

# vhstack installieren

Die gesamte vhstack-Arbeitsumgebung — **Oh My Posh Prompt**
([`vhstack/termpp`](https://github.com/vhstack/termpp)), **Tmux**
([`vhstack/tmuxpp`](https://github.com/vhstack/tmuxpp)) und **Neovim**
([`vhstack/nvimpp`](https://github.com/vhstack/nvimpp)) — richtet das Skript
[`install.sh`](./install.sh) in einem Schritt ein:

```bash
curl -sL https://raw.githubusercontent.com/vhstack/vhstack/main/install.sh | bash
```

Das Skript übernimmt automatisch:

- **Sicherung** vorhandener Konfigurationen nach `~/.vhstack-backup-<Zeitstempel>`
  (`~/.tmux*`, `~/.config/nvim`, Neovim-Plugindaten, Prompt-Theme sowie eine
  Kopie der `~/.bashrc`/`~/.zshrc`)
- Installation von **Oh My Posh** samt `vhstack.omp.json`-Theme und
  Init-Zeile in `~/.bashrc` bzw. `~/.zshrc`
- **Tmux-Konfiguration**
- Nur unter WSL: **win32yank.exe** für die schnelle Zwischenablage
  ([Details in tmuxpp](https://github.com/vhstack/tmuxpp#win32yankexe-unter-wsl))
- **Neovim-Konfiguration** inklusive Plugin-Synchronisation (headless)
- **xssh-Skript** nach `~/.local/bin` (X11 über Xephyr,
  [Details in termpp](https://github.com/vhstack/termpp))
- **update-vhstack-Befehl** nach `~/.local/bin` für spätere Updates

**Später aktualisieren:** Eine bestehende Installation bringt der Befehl
`update-vhstack` (bzw. [`update.sh`](./update.sh)) auf den aktuellen Stand —
Theme, Tmux- und Neovim-Konfiguration samt Neovim-Plugins, ohne die
`~/.bashrc`/`~/.zshrc` anzufassen. Ersetzte Konfigurationen landen vorher in
`~/.vhstack-backup-update-<Zeitstempel>`:

```bash
update-vhstack   # oder:
curl -sL https://raw.githubusercontent.com/vhstack/vhstack/main/update.sh | bash
```

Voraussetzungen: `git` und `curl`; `tmux` und `nvim` sollten installiert sein:

```bash
sudo apt install tmux neovim ripgrep clangd   # Debian/Ubuntu
brew install tmux neovim ripgrep llvm         # macOS
```

> **Tipp:** Danach eine neue Shell starten (oder `source ~/.bashrc`) und `tmux`
> sowie `nvim` einmal öffnen. In Neovim bei Bedarf
> `:MasonInstall clangd cmake-language-server` für den C/C++-LSP ausführen.
