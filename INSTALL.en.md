<p align="right">
  <a href="INSTALL.md"><img src="assets/flag-de.png" width="16" height="12" alt="Deutsch" title="Zur deutschen Version wechseln" /></a>  
  <a href="INSTALL.en.md"><img src="assets/flag-gb.png" width="16" height="12" alt="English" title="Switch to English" /></a>  
  <a href="INSTALL.ru.md"><img src="assets/flag-ru.png" width="16" height="12" alt="Русский" title="Переключиться на русскую версию" /></a>
</p>

# Installing vhstack

The script [`install.sh`](./install.sh) sets up the entire vhstack
environment — **Oh My Posh prompt**
([`vhstack/termpp`](https://github.com/vhstack/termpp)), **Tmux**
([`vhstack/tmuxpp`](https://github.com/vhstack/tmuxpp)) and **Neovim**
([`vhstack/nvimpp`](https://github.com/vhstack/nvimpp)) — in a single step:

```bash
curl -sL https://raw.githubusercontent.com/vhstack/vhstack/main/install.sh | bash
```

The script automatically takes care of:

- **Backing up** existing configurations to `~/.vhstack-backup-<timestamp>`
  (`~/.tmux*`, `~/.config/nvim`, Neovim plugin data, the prompt theme, and a
  copy of your `~/.bashrc`/`~/.zshrc`)
- Installing **Oh My Posh** with the `vhstack.omp.json` theme and the init
  line in `~/.bashrc` or `~/.zshrc`
- The **Tmux configuration**
- On WSL only: **win32yank.exe** for the fast clipboard
  ([details in tmuxpp](https://github.com/vhstack/tmuxpp/blob/main/README.en.md#win32yankexe-on-wsl))
- The **Neovim configuration** including headless plugin synchronization
- The **xssh script** to `~/.local/bin` (X11 via Xephyr,
  [details in termpp](https://github.com/vhstack/termpp))
- The **update-vhstack command** to `~/.local/bin` for later updates

**Updating later:** Bring an existing installation up to date with the
`update-vhstack` command (or [`update.sh`](./update.sh)) — theme, Tmux and
Neovim configuration including the Neovim plugins, without touching your
`~/.bashrc`/`~/.zshrc`. Replaced configurations are saved to
`~/.vhstack-backup-update-<timestamp>` first:

```bash
update-vhstack   # or:
curl -sL https://raw.githubusercontent.com/vhstack/vhstack/main/update.sh | bash
```

Requirements: `git` and `curl`; `tmux` and `nvim` should be installed:

```bash
sudo apt install tmux neovim ripgrep clangd   # Debian/Ubuntu
brew install tmux neovim ripgrep llvm         # macOS
```

> **Tip:** Afterwards start a new shell (or run `source ~/.bashrc`) and open
> `tmux` and `nvim` once. In Neovim, run `:MasonInstall clangd cmake-language-server`
> if you need the C/C++ LSP.

## Installed Paths

| Component | Paths |
| --- | --- |
| Prompt | `~/.config/ohmyposh/vhstack.omp.json`, init lines in `~/.bashrc`/`~/.zshrc`, `~/.local/bin/oh-my-posh` if needed |
| Tmux | `~/.tmux/`, symlink `~/.tmux.conf` |
| Clipboard (WSL only) | `%LOCALAPPDATA%\win32yank`, symlink in PATH, `~/.cache/tmuxpp/` |
| Neovim | `~/.config/nvim/`, plugin data under `~/.local/share/nvim`, `~/.local/state/nvim`, `~/.cache/nvim` |
| Tools | `~/.local/bin/xssh`, `~/.local/bin/update-vhstack` |

`install.sh` is idempotent: running it again refreshes the installation, and anything existing is moved to a new backup directory first.

## Uninstall

One command removes all of the components listed above ([`uninstall.sh`](./uninstall.sh)):

```bash
curl -sL https://raw.githubusercontent.com/vhstack/vhstack/main/uninstall.sh | bash
```

The script first shows what it found and asks for confirmation (skip the prompt with `... | bash -s -- --yes`). The backup directories `~/.vhstack-backup-*` are kept — they hold the state from before the installation and can be restored by hand:

```bash
cp -a ~/.vhstack-backup-<timestamp>/.tmux ~/
```

The `oh-my-posh` binary itself stays installed (`~/.local/bin/oh-my-posh`) — delete it manually if unwanted.
