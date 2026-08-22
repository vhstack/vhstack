#!/usr/bin/env bash
#
# install.sh — Full install of the vhstack terminal environment
#
# Installs in one go:
#   1. Oh My Posh prompt with the vhstack theme   (vhstack/termpp)
#   2. Tmux configuration                         (vhstack/tmuxpp)
#      on WSL additionally win32yank.exe for a fast clipboard
#   3. Neovim C/C++ configuration                 (vhstack/nvimpp)
#   4. xssh helper script (SSH into a Xephyr X-screen, see README)
#   5. update-vhstack command to ~/.local/bin — run it any time to pull
#      the latest configurations without a full reinstall
#
# Existing configurations are moved to a timestamped backup directory
# (~/.vhstack-backup-<timestamp>) before anything is overwritten.
#
# Quick install (bash or zsh):
#
#   curl -sL https://raw.githubusercontent.com/vhstack/vhstack/main/install.sh | bash
#
# Remove everything later with uninstall.sh (backups are kept):
#
#   curl -sL https://raw.githubusercontent.com/vhstack/vhstack/main/uninstall.sh | bash
#
# Requirements: git, curl — tmux and nvim should be installed, e.g.:
#
#   sudo apt install tmux neovim ripgrep clangd   # Debian/Ubuntu
#   brew install tmux neovim ripgrep llvm         # macOS
#
# After the installation start a new shell session (or `source ~/.bashrc`),
# then run `nvim` once so the Neovim plugins finish their setup.

set -euo pipefail

# shellcheck disable=SC2088  # Tilden in Meldungstexten sind reine Anzeige (~/...), keine Pfade

# Alles in main(): bash parst so das komplette Skript, bevor der erste
# Befehl laeuft. Bei 'curl | bash' kann sonst ein Kindprozess, der stdin
# liest (etwa cmd.exe/win32yank.exe ueber die WSL-Interop), den restlichen
# Skripttext verschlucken -- das Skript endet dann still mitten im Lauf.
main() {

  SECONDS=0
  BACKUP_DIR="$HOME/.vhstack-backup-$(date +%Y%m%d-%H%M%S)"

  # --- Ausgabe: feste Label-Spalte, Status dezent farbig (nur am Terminal).
  # Unterbefehle schreiben in ein Log, das nur im Fehlerfall gezeigt wird --
  # die Installation selbst bleibt ruhig.
  if [ -t 1 ]; then
    BLD=$'\033[1m'; DIM=$'\033[2m'; GRN=$'\033[32m'; YEL=$'\033[33m'
    RED=$'\033[31m'; RST=$'\033[0m'
  else
    BLD=""; DIM=""; GRN=""; YEL=""; RED=""; RST=""
  fi
  LOG=$(mktemp)
  trap 'rm -f "$LOG"' EXIT

  label()   { : >"$LOG"; printf '  %-10s ' "$1"; }
  ok()      { printf '%sok%s      %s\n' "$GRN" "$RST" "$1"; }
  warn()    { printf '%swarn%s    %s\n' "$YEL" "$RST" "$1"; }
  showlog() { if [ -s "$LOG" ]; then sed "s/^/          $DIM/;s/\$/$RST/" "$LOG"; fi; }
  fail()    { printf '%sfail%s    %s\n' "$RED" "$RST" "$1"; showlog; exit 1; }
  note()    { printf '  %-10s %s\n' "$1" "$2"; }

  # Vorhandenes still ins Backup verschieben (Pfad relativ zu $HOME
  # gespiegelt); gemeldet wird das Backup am Ende in einer Zeile.
  backup() {
    local path="$1"
    [ -e "$path" ] || [ -L "$path" ] || return 0
    local rel="${path#"$HOME"/}"
    mkdir -p "$BACKUP_DIR/$(dirname "$rel")"
    mv "$path" "$BACKUP_DIR/$rel"
  }

  printf '%svhstack install%s  %s·  vhstack.github.io%s\n\n' "$BLD" "$RST" "$DIM" "$RST"

  # --- 0. Preconditions -------------------------------------------------------

  label "tools"
  for tool in git curl; do
    command -v "$tool" &>/dev/null || fail "'$tool' is required but not installed."
  done
  missing=""
  for tool in tmux nvim; do
    command -v "$tool" &>/dev/null || missing="$missing $tool"
  done
  if [ -n "$missing" ]; then
    warn "not installed:$missing — configs are set up anyway, active once installed"
  else
    ok "git, curl, tmux, nvim found"
  fi

  # --- 1. Prompt: Oh My Posh + vhstack theme (termpp) -------------------------

  label "prompt"
  if ! command -v oh-my-posh &>/dev/null && [ ! -x "$HOME/.local/bin/oh-my-posh" ]; then
    mkdir -p "$HOME/.local/bin"
    curl -s https://ohmyposh.dev/install.sh | bash -s -- -d "$HOME/.local/bin" >>"$LOG" 2>&1 ||
      fail "Oh My Posh installation failed"
  fi

  mkdir -p "$HOME/.config/ohmyposh"
  backup "$HOME/.config/ohmyposh/vhstack.omp.json"
  curl -fsSL https://raw.githubusercontent.com/vhstack/termpp/main/vhstack.omp.json \
    -o "$HOME/.config/ohmyposh/vhstack.omp.json" 2>>"$LOG" ||
    fail "download of vhstack.omp.json failed"

  # Detect shell and pick the matching rc file
  SHELL_NAME=$(basename "${SHELL:-bash}")
  case "$SHELL_NAME" in
    zsh) RC_FILE="$HOME/.zshrc" ;;
    *)   SHELL_NAME=bash
         RC_FILE="$HOME/.bashrc" ;;
  esac
  touch "$RC_FILE"

  # Keep a copy of the rc file before modifying it
  mkdir -p "$BACKUP_DIR"
  cp "$RC_FILE" "$BACKUP_DIR/$(basename "$RC_FILE")"

  # True color support
  if ! grep -q "TERM=xterm-256color" "$RC_FILE"; then
    {
      echo ""
      echo "# vhstack: true color support"
      echo "export TERM=xterm-256color"
    } >> "$RC_FILE"
  fi

  # Prompt init line
  if grep -q "oh-my-posh init" "$RC_FILE"; then
    ok "theme installed; existing oh-my-posh init in ${RC_FILE/#$HOME/\~} left untouched"
  else
    {
      echo ""
      echo "# oh-my-posh vhstack/termpp theme"
      # shellcheck disable=SC2016  # $(...) soll woertlich in die rc-Datei
      echo 'eval "$('"$HOME"'/.local/bin/oh-my-posh init '"$SHELL_NAME"' --config ~/.config/ohmyposh/vhstack.omp.json)"'
    } >> "$RC_FILE"
    ok "theme installed; init line added to ${RC_FILE/#$HOME/\~}"
  fi

  # --- 2. Tmux configuration (tmuxpp) ------------------------------------------

  label "tmux"
  backup "$HOME/.tmux.conf"
  backup "$HOME/.tmux"
  git clone --depth 1 --quiet https://github.com/vhstack/tmuxpp.git "$HOME/.tmux" 2>>"$LOG" ||
    fail "clone of vhstack/tmuxpp failed"
  rm -rf "$HOME/.tmux/.git" "$HOME/.tmux/assets" "$HOME/.tmux"/README*.md
  ln -s "$HOME/.tmux/tmux.conf" "$HOME/.tmux.conf"
  ok "~/.tmux installed, ~/.tmux.conf linked"

  # --- 2b. WSL: fast clipboard via win32yank ------------------------------------

  # Only relevant on WSL; on a server or plain Linux the step is skipped.
  # install_win32yank.sh ships with tmuxpp (pinned release, checksum-verified,
  # activates nothing if its function probe fails) — a failure here must not
  # abort the rest of the vhstack installation.
  if [ -n "${WSL_DISTRO_NAME:-}" ] || grep -qi microsoft /proc/version 2>/dev/null; then
    label "clipboard"
    if sh "$HOME/.tmux/install_win32yank.sh" </dev/null >>"$LOG" 2>&1; then
      ok "win32yank.exe active (WSL)"
    else
      warn "win32yank setup failed — clipboard falls back to powershell.exe"
      showlog
      printf '          %sretry later with: sh ~/.tmux/install_win32yank.sh%s\n' "$DIM" "$RST"
    fi
  fi

  # --- 3. Neovim configuration (nvimpp) ----------------------------------------

  label "neovim"
  backup "$HOME/.config/nvim"
  # Move old plugin/runtime state aside for a clean start
  backup "$HOME/.local/share/nvim"
  backup "$HOME/.local/state/nvim"
  backup "$HOME/.cache/nvim"
  git clone --depth 1 --quiet https://github.com/vhstack/nvimpp "$HOME/.config/nvim" 2>>"$LOG" ||
    fail "clone of vhstack/nvimpp failed"
  rm -rf "$HOME/.config/nvim/.git" "$HOME/.config/nvim/assets" "$HOME/.config/nvim"/README*.md

  if ! command -v nvim &>/dev/null; then
    ok "~/.config/nvim installed (plugins install on first nvim start)"
  elif nvim --headless "+Lazy! sync" +qa >>"$LOG" 2>&1; then
    ok "~/.config/nvim installed, plugins synchronized"
  else
    ok "~/.config/nvim installed (plugin sync failed — plugins install on first start)"
  fi

  # --- 4. xssh: SSH with X11 forwarding into a Xephyr screen --------------------

  label "xssh"
  mkdir -p "$HOME/.local/bin"
  backup "$HOME/.local/bin/xssh"
  curl -fsSL https://raw.githubusercontent.com/vhstack/termpp/main/xssh \
    -o "$HOME/.local/bin/xssh" 2>>"$LOG" || fail "download of xssh failed"
  chmod +x "$HOME/.local/bin/xssh"
  if command -v Xephyr &>/dev/null && command -v xdpyinfo &>/dev/null; then
    ok "~/.local/bin/xssh"
  else
    ok "~/.local/bin/xssh (runtime needs: sudo apt install xserver-xephyr openbox x11-utils)"
  fi

  # --- 5. update-vhstack: update command for later ------------------------------

  label "update"
  backup "$HOME/.local/bin/update-vhstack"
  if curl -fsSL https://raw.githubusercontent.com/vhstack/vhstack/main/update.sh \
       -o "$HOME/.local/bin/update-vhstack" 2>>"$LOG"; then
    chmod +x "$HOME/.local/bin/update-vhstack"
    ok "~/.local/bin/update-vhstack — updates everything with one command"
  else
    rm -f "$HOME/.local/bin/update-vhstack"
    warn "download failed — update later via: curl -sL https://raw.githubusercontent.com/vhstack/vhstack/main/update.sh | bash"
  fi

  # --- 6. Version manifest ------------------------------------------------------

  # Die Klone verlieren oben ihr .git und termpp wird gar nicht geklont --
  # 'git describe' ist beim Nutzer also nicht moeglich. Ein Manifest haelt
  # fest, was installiert wurde; update.sh liest es fuer die alt->neu-Meldung.
  label "version"
  STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/vhstack"
  mkdir -p "$STATE_DIR"

  read_version()  { if [ -r "$1" ]; then tr -d ' \t\n\r' <"$1"; else echo unknown; fi; }
  fetch_version() { curl -fsSL "https://raw.githubusercontent.com/vhstack/$1/main/VERSION" 2>>"$LOG" | tr -d ' \t\n\r'; }

  # tmuxpp/nvimpp liegen als Klon vor, termpp nicht -- und install.sh selbst
  # laeuft per 'curl | bash', kennt sein eigenes Repo also auch nicht lokal.
  # Das '|| true' muss an den Aufruf: bei 'pipefail' reisst ein
  # fehlgeschlagenes curl die Pipe mit und beendet sonst das Skript.
  V_TMUXPP=$(read_version "$HOME/.tmux/VERSION")
  V_NVIMPP=$(read_version "$HOME/.config/nvim/VERSION")
  V_TERMPP=$(fetch_version termpp   || true); [ -n "$V_TERMPP" ]  || V_TERMPP=unknown
  V_VHSTACK=$(fetch_version vhstack || true); [ -n "$V_VHSTACK" ] || V_VHSTACK=unknown

  {
    echo "VHSTACK=$V_VHSTACK"
    echo "NVIMPP=$V_NVIMPP"
    echo "TMUXPP=$V_TMUXPP"
    echo "TERMPP=$V_TERMPP"
    echo "INSTALLED=$(date +%Y-%m-%dT%H:%M:%S%z)"
  } >"$STATE_DIR/versions"

  ok "vhstack v$V_VHSTACK  ${DIM}(nvimpp v$V_NVIMPP · tmuxpp v$V_TMUXPP · termpp v$V_TERMPP)${RST}"

  label "backup"
  ok "${BACKUP_DIR/#$HOME/\~}"
  case ":$PATH:" in
    *":$HOME/.local/bin:"*) ;;
    *) note "" "${DIM}hint: ~/.local/bin is not in your PATH — needed for xssh and update-vhstack${RST}" ;;
  esac

  # Ob das lokale Terminal eine Nerd Font hat, laesst sich serverseitig nicht
  # erkennen -- Probe ausgeben und den Nutzer selbst schauen lassen.
  label "fontcheck"
  printf '        \n'
  note "" "${DIM}boxes instead of symbols? set font 'Cascadia Code NF' — see github.com/vhstack/termpp${RST}"

  # --- Summary ------------------------------------------------------------------

  printf '\n%sdone in %ss.%s vhstack v%s — next steps:\n' "$BLD" "$SECONDS" "$RST" "$V_VHSTACK"
  echo "  1. start a new $SHELL_NAME session   (or: source ${RC_FILE/#$HOME/\~})"
  echo "  2. run 'tmux'   (prefix = Ctrl+A)"
  echo "  3. run 'nvim'   (:MasonInstall clangd cmake-language-server for C/C++ LSP)"
}

main "$@"
