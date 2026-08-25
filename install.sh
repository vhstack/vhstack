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
#   5. vhstack-update command to ~/.local/bin — run it any time to pull
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

  # --- Ausgabe im Stil der Landing-Page (vhstack.github.io): Module blau,
  # Erfolg gruen, Hinweise peach, Nebensaechliches gedimmt. Catppuccin-
  # Truecolor wo das Terminal es meldet, sonst die 16 Standardfarben;
  # ohne Terminal (Pipe) oder mit NO_COLOR bleibt alles schmucklos.
  if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
    if [ "${COLORTERM:-}" = "truecolor" ] || [ "${COLORTERM:-}" = "24bit" ]; then
      BLU=$'\033[38;2;138;173;244m'   # Catppuccin blue
      GRN=$'\033[38;2;166;227;161m'   # Catppuccin green
      PCH=$'\033[38;2;245;169;127m'   # Catppuccin peach
      RED=$'\033[38;2;243;139;168m'   # Catppuccin red
    else
      case "${TERM:-}" in
        *256color*)  # ohne COLORTERM (etwa ueber SSH): naechstliegende 256er-Toene
          BLU=$'\033[38;5;111m'; GRN=$'\033[38;5;151m'; PCH=$'\033[38;5;216m'; RED=$'\033[38;5;211m' ;;
        *)
          BLU=$'\033[34m'; GRN=$'\033[32m'; PCH=$'\033[33m'; RED=$'\033[31m' ;;
      esac
    fi
    BLD=$'\033[1m'; DIM=$'\033[2m'; RST=$'\033[0m'
  else
    BLU=""; GRN=""; PCH=""; RED=""; BLD=""; DIM=""; RST=""
  fi

  # Glyphen nur bei UTF-8-Locale, sonst ASCII -- Statusmarken sind in beiden
  # Varianten 2 Spalten breit, damit die Nachrichtenspalte buendig bleibt.
  RULE=$(printf '%78s' '')
  # shellcheck disable=SC2034  # gemeinsame Glyphen der drei Skripte -- nicht jedes nutzt alle
  case "${LC_ALL:-${LC_CTYPE:-${LANG:-}}}" in
    *[Uu][Tt][Ff]-8*|*[Uu][Tt][Ff]8*)
      CHK='✓ '; WRN='! '; FLD='✗ '; SKP='· '; SEP='·'; ARR='→'; CUR='▊'; RULE=${RULE// /─} ;;
    *)
      CHK='ok'; WRN='! '; FLD='x '; SKP='- '; SEP='-'; ARR='->'; CUR=' '; RULE=${RULE// /-} ;;
  esac

  # Unterbefehle schreiben in ein Log, das nur im Fehlerfall gezeigt wird --
  # die Installation selbst bleibt ruhig.
  LOG=$(mktemp)
  trap 'rm -f "$LOG"' EXIT

  label()   { : >"$LOG"; printf '  %s%-10s%s ' "$BLU" "$1" "$RST"; }
  ok()      { printf '%s%s%s %s\n' "$GRN" "$CHK" "$RST" "$1"; }
  warn()    { printf '%s%s%s %s\n' "$PCH" "$WRN" "$RST" "$1"; }
  showlog() { if [ -s "$LOG" ]; then sed "s/^/                $DIM/;s/\$/$RST/" "$LOG"; fi; }
  fail()    { printf '%s%s%s %s\n' "$RED" "$FLD" "$RST" "$1"; showlog; exit 1; }
  # Gedimmte Folgezeile, buendig unter der Nachrichtenspalte (16 = 2 Rand
  # + 10 Label + 1 + 2 Statusmarke + 1)
  extra()   { printf '                %s%s%s\n' "$DIM" "$1" "$RST"; }

  # Vorhandenes still ins Backup verschieben (Pfad relativ zu $HOME
  # gespiegelt); gemeldet wird das Backup am Ende in einer Zeile.
  backup() {
    local path="$1"
    [ -e "$path" ] || [ -L "$path" ] || return 0
    local rel="${path#"$HOME"/}"
    mkdir -p "$BACKUP_DIR/$(dirname "$rel")"
    mv "$path" "$BACKUP_DIR/$rel"
  }

  # Kopf wie auf der Landing-Page: Name mit Block-Cursor, Quelle rechtsbuendig
  printf '\n  %svhstack install%s %s%s%s%44s%svhstack.github.io%s\n' \
    "$BLD" "$RST" "$PCH" "$CUR" "$RST" '' "$DIM" "$RST"
  printf '  %s%s%s\n\n' "$DIM" "$RULE" "$RST"

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

  # COLORTERM meldet Truecolor, wird von ssh aber nicht weitergereicht --
  # auf dem Server fehlt es daher fast immer, obwohl das lokale Terminal
  # Truecolor kann. Der Stack setzt moderne Terminals ohnehin voraus
  # (Nerd Font), also wird es hier angesagt.
  if ! grep -q "COLORTERM=truecolor" "$RC_FILE"; then
    {
      echo ""
      echo "# vhstack: advertise truecolor (not forwarded by ssh)"
      echo "export COLORTERM=truecolor"
    } >> "$RC_FILE"
  fi

  # Prompt init line
  if grep -q "oh-my-posh init" "$RC_FILE"; then
    ok "theme installed $SEP existing oh-my-posh init in ${RC_FILE/#$HOME/\~} left untouched"
  else
    {
      echo ""
      echo "# oh-my-posh vhstack/termpp theme"
      # shellcheck disable=SC2016  # $(...) soll woertlich in die rc-Datei
      echo 'eval "$('"$HOME"'/.local/bin/oh-my-posh init '"$SHELL_NAME"' --config ~/.config/ohmyposh/vhstack.omp.json)"'
    } >> "$RC_FILE"
    ok "theme installed $SEP init line added to ${RC_FILE/#$HOME/\~}"
  fi

  # --- 2. Tmux configuration (tmuxpp) ------------------------------------------

  label "tmux"
  backup "$HOME/.tmux.conf"
  backup "$HOME/.tmux"
  git clone --depth 1 --quiet https://github.com/vhstack/tmuxpp.git "$HOME/.tmux" 2>>"$LOG" ||
    fail "clone of vhstack/tmuxpp failed"
  rm -rf "$HOME/.tmux/.git" "$HOME/.tmux/assets" "$HOME/.tmux"/README*.md
  ln -s "$HOME/.tmux/tmux.conf" "$HOME/.tmux.conf"
  ok "~/.tmux installed $SEP ~/.tmux.conf linked"

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
      extra "retry later with: sh ~/.tmux/install_win32yank.sh"
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
    ok "~/.config/nvim installed $SEP plugins synchronized"
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
  ok "~/.local/bin/xssh"
  if ! command -v Xephyr &>/dev/null || ! command -v xdpyinfo &>/dev/null; then
    extra "needs: sudo apt install xserver-xephyr openbox x11-utils"
  fi

  # --- 5. vhstack-update: update command for later ------------------------------

  label "update"
  rm -f "$HOME/.local/bin/update-vhstack"   # old name (< 1.0.1)
  backup "$HOME/.local/bin/vhstack-update"
  if curl -fsSL https://raw.githubusercontent.com/vhstack/vhstack/main/update.sh \
       -o "$HOME/.local/bin/vhstack-update" 2>>"$LOG"; then
    chmod +x "$HOME/.local/bin/vhstack-update"
    ok "~/.local/bin/vhstack-update — updates everything with one command"
  else
    rm -f "$HOME/.local/bin/vhstack-update"
    warn "download failed — update later via: curl -sL https://raw.githubusercontent.com/vhstack/vhstack/main/update.sh | bash"
  fi

  # --- 6. Version manifest ------------------------------------------------------

  # Die Klone verlieren oben ihr .git und termpp wird gar nicht geklont --
  # 'git describe' ist beim Nutzer also nicht moeglich. Ein Manifest haelt
  # fest, was installiert wurde; update.sh liest es fuer die alt->neu-Meldung.
  # Angezeigt werden die Versionen unten in der Summary-Zeile.
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

  label "backup"
  ok "${BACKUP_DIR/#$HOME/\~}"

  # Hinweise als eigene Zeilen: nur zeigen, was wirklich ansteht. Fehlt
  # ~/.local/bin im PATH, wird es idempotent in die rc-Datei eingetragen
  # (Marker + genau eine Folgezeile, uninstall.sh baut das wieder ab).
  case ":$PATH:" in
    *":$HOME/.local/bin:"*) ;;
    *) printf '\n'
       label "path"
       if ! grep -qF '# vhstack: ~/.local/bin' "$RC_FILE"; then
         {
           echo ""
           echo "# vhstack: ~/.local/bin for xssh and vhstack-update"
           # shellcheck disable=SC2016  # $PATH soll woertlich in die rc-Datei
           echo 'case ":$PATH:" in *":$HOME/.local/bin:"*) ;; *) PATH="$HOME/.local/bin:$PATH" ;; esac'
         } >> "$RC_FILE"
       fi
       ok "~/.local/bin added to PATH in ${RC_FILE/#$HOME/\~} $SEP active in new shell sessions"
       PATH_HINTED=1 ;;
  esac

  # Ob das lokale Terminal eine Nerd Font hat, laesst sich serverseitig nicht
  # erkennen -- Glyphen-Probe ausgeben und den Nutzer selbst schauen lassen.
  [ -n "${PATH_HINTED:-}" ] || printf '\n'
  label "font"
  warn "          boxes instead of symbols? set 'Cascadia Code NF'"
  extra "font setup guide: github.com/vhstack/termpp"

  # --- Summary ------------------------------------------------------------------

  printf '\n  %s%s%s\n' "$DIM" "$RULE" "$RST"
  printf '  %sdone in %ss%s   vhstack %sv%s%s %s%s%s nvimpp %sv%s%s %s%s%s tmuxpp %sv%s%s %s%s%s termpp %sv%s%s\n' \
    "$BLD" "$SECONDS" "$RST" \
    "$BLU" "$V_VHSTACK" "$RST" "$DIM" "$SEP" "$RST" \
    "$BLU" "$V_NVIMPP" "$RST" "$DIM" "$SEP" "$RST" \
    "$BLU" "$V_TMUXPP" "$RST" "$DIM" "$SEP" "$RST" \
    "$BLU" "$V_TERMPP" "$RST"

  # Naechste Schritte wie die Command-Box der Landing-Page: $ peach, Befehl gruen
  step() { printf '  %s$%s %s%-20s%s %s%s%s\n' "$PCH" "$RST" "$GRN" "$1" "$RST" "$DIM" "$2" "$RST"; }
  printf '\n  %snext steps%s\n' "$PCH" "$RST"
  step "source ${RC_FILE/#$HOME/\~}" "reload your shell (or start a new $SHELL_NAME session)"
  step "tmux" "prefix = Ctrl+A"
  step "nvim" ":MasonInstall clangd cmake-language-server for C/C++ LSP"
}

main "$@"
