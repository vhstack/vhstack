#!/usr/bin/env bash
#
# update.sh — Update an existing vhstack terminal environment
#
# Brings an installation made by install.sh up to date:
#   1. Oh My Posh vhstack theme                    (vhstack/termpp)
#   2. Tmux configuration                          (vhstack/tmuxpp)
#   3. Neovim configuration + plugin sync          (vhstack/nvimpp)
#   4. xssh helper script                          (vhstack/termpp)
#
# Shell rc files (~/.bashrc / ~/.zshrc) are NOT touched — for a fresh
# setup use install.sh instead. Plugin data (~/.tmux/plugins,
# ~/.local/share/nvim) is kept; only the configurations are replaced.
# The replaced configurations are copied to a timestamped backup
# directory (~/.vhstack-backup-update-<timestamp>) first, in case you
# made local changes.
#
# Quick update (bash or zsh):
#
#   curl -sL https://raw.githubusercontent.com/vhstack/vhstack/main/update.sh | bash
#
# install.sh also installs this script as ~/.local/bin/vhstack-update,
# so after the initial install you can simply run: vhstack-update

set -euo pipefail

# shellcheck disable=SC2088  # Tilden in Meldungstexten sind reine Anzeige (~/...), keine Pfade

# Alles in main(): bash parst so das komplette Skript, bevor der erste
# Befehl laeuft. Bei 'curl | bash' kann sonst ein Kindprozess, der stdin
# liest (etwa cmd.exe/win32yank.exe ueber die WSL-Interop), den restlichen
# Skripttext verschlucken -- das Skript endet dann still mitten im Lauf.
main() {

  SECONDS=0
  BACKUP_DIR="$HOME/.vhstack-backup-update-$(date +%Y%m%d-%H%M%S)"
  TMP_DIR=$(mktemp -d)
  trap 'rm -rf "$TMP_DIR"' EXIT

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

  # Unterbefehle schreiben in ein Log, das nur im Fehlerfall gezeigt wird.
  LOG="$TMP_DIR/log"

  label()   { : >"$LOG"; printf '  %s%-10s%s ' "$BLU" "$1" "$RST"; }
  ok()      { printf '%s%s%s %s\n' "$GRN" "$CHK" "$RST" "$1"; }
  warn()    { printf '%s%s%s %s\n' "$PCH" "$WRN" "$RST" "$1"; }
  skip()    { printf '%s%s %s%s\n' "$DIM" "$SKP" "$1" "$RST"; }
  showlog() { if [ -s "$LOG" ]; then sed "s/^/                $DIM/;s/\$/$RST/" "$LOG"; fi; }
  fail()    { printf '%s%s%s %s\n' "$RED" "$FLD" "$RST" "$1"; showlog; exit 1; }
  # Gedimmte Folgezeile, buendig unter der Nachrichtenspalte (16 = 2 Rand
  # + 10 Label + 1 + 2 Statusmarke + 1)
  extra()   { printf '                %s%s%s\n' "$DIM" "$1" "$RST"; }

  # Download a file to the temp directory first and only replace the
  # target on success — a failed download must never clobber a working
  # file with an empty or HTML error body.
  fetch() {
    local url="$1" dest="$2"
    local tmp="$TMP_DIR/fetch.$$"
    if curl -fsSL "$url" -o "$tmp" 2>>"$LOG"; then
      mv "$tmp" "$dest"
      return 0
    fi
    rm -f "$tmp"
    return 1
  }

  # Copy an existing file/directory into the backup directory, mirroring
  # its path relative to $HOME (same layout as install.sh); reported as a
  # single line at the end.
  backup() {
    local path="$1"
    [ -e "$path" ] || [ -L "$path" ] || return 0
    local rel="${path#"$HOME"/}"
    mkdir -p "$BACKUP_DIR/$(dirname "$rel")"
    cp -a "$path" "$BACKUP_DIR/$rel"
  }

  # Kopf wie auf der Landing-Page: Name mit Block-Cursor, Quelle rechtsbuendig
  printf '\n  %svhstack update%s %s%s%s%45s%svhstack.github.io%s\n' \
    "$BLD" "$RST" "$PCH" "$CUR" "$RST" '' "$DIM" "$RST"
  printf '  %s%s%s\n\n' "$DIM" "$RULE" "$RST"

  # --- 0. Preconditions -------------------------------------------------------

  for tool in git curl; do
    command -v "$tool" &>/dev/null || {
      label "tools"
      fail "'$tool' is required but not installed."
    }
  done

  if [ ! -e "$HOME/.config/ohmyposh/vhstack.omp.json" ] \
     && [ ! -e "$HOME/.tmux/tmux.conf" ] \
     && [ ! -e "$HOME/.config/nvim/init.lua" ]; then
    label "vhstack"
    printf '%s%s%s no vhstack installation found — run install.sh first:\n' "$RED" "$FLD" "$RST"
    extra "curl -sL https://raw.githubusercontent.com/vhstack/vhstack/main/install.sh | bash"
    exit 1
  fi

  # --- Bisher installierte Versionen (fuer die alt->neu-Meldung am Ende) -------

  # Zeilenweise geparst, nicht 'source': die Datei wird nie ausgefuehrt.
  STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/vhstack"
  OLD_VHSTACK=unknown; OLD_NVIMPP=unknown
  OLD_TMUXPP=unknown;  OLD_TERMPP=unknown
  if [ -r "$STATE_DIR/versions" ]; then
    while IFS='=' read -r key val; do
      case "$key" in
        VHSTACK) OLD_VHSTACK="$val" ;;
        NVIMPP)  OLD_NVIMPP="$val"  ;;
        TMUXPP)  OLD_TMUXPP="$val"  ;;
        TERMPP)  OLD_TERMPP="$val"  ;;
      esac
    done <"$STATE_DIR/versions"
  fi

  # --- 1. Prompt theme (termpp) -------------------------------------------------

  label "prompt"
  if [ -e "$HOME/.config/ohmyposh/vhstack.omp.json" ]; then
    backup "$HOME/.config/ohmyposh/vhstack.omp.json"
    if fetch https://raw.githubusercontent.com/vhstack/termpp/main/vhstack.omp.json \
         "$HOME/.config/ohmyposh/vhstack.omp.json"; then
      ok "theme updated"
    else
      warn "download failed — existing theme kept"
    fi
  else
    skip "not installed"
  fi

  # --- 2. Tmux configuration (tmuxpp) ------------------------------------------

  label "tmux"
  if [ -e "$HOME/.tmux/tmux.conf" ]; then
    git clone --depth 1 --quiet https://github.com/vhstack/tmuxpp.git "$TMP_DIR/tmuxpp" 2>>"$LOG" ||
      fail "clone of vhstack/tmuxpp failed"
    rm -rf "$TMP_DIR/tmuxpp/.git" "$TMP_DIR/tmuxpp/assets" "$TMP_DIR/tmuxpp"/README*.md

    # Back up and replace the configuration files. ~/.tmux/plugins is kept —
    # the optional catppuccin theme lives there (manually cloned).
    for entry in "$HOME/.tmux"/* "$HOME/.tmux"/.[!.]*; do
      [ -e "$entry" ] || [ -L "$entry" ] || continue
      [ "$(basename "$entry")" = "plugins" ] && continue
      backup "$entry"
      rm -rf "$entry"
    done
    cp -a "$TMP_DIR/tmuxpp/." "$HOME/.tmux/"

    # Recreate the symlink in case it is missing or points elsewhere.
    if [ ! -L "$HOME/.tmux.conf" ] || [ "$(readlink "$HOME/.tmux.conf")" != "$HOME/.tmux/tmux.conf" ]; then
      backup "$HOME/.tmux.conf"
      rm -f "$HOME/.tmux.conf"
      ln -s "$HOME/.tmux/tmux.conf" "$HOME/.tmux.conf"
    fi

    if command -v tmux &>/dev/null && [ -n "${TMUX:-}" ]; then
      tmux source-file "$HOME/.tmux.conf" >/dev/null 2>&1 || true
      ok "~/.tmux updated $SEP running session reloaded"
    else
      ok "~/.tmux updated"
    fi
  else
    skip "not installed"
  fi

  # --- 3. Neovim configuration (nvimpp) ----------------------------------------

  label "neovim"
  if [ -e "$HOME/.config/nvim/init.lua" ]; then
    git clone --depth 1 --quiet https://github.com/vhstack/nvimpp "$TMP_DIR/nvimpp" 2>>"$LOG" ||
      fail "clone of vhstack/nvimpp failed"
    rm -rf "$TMP_DIR/nvimpp/.git" "$TMP_DIR/nvimpp/assets" "$TMP_DIR/nvimpp"/README*.md

    backup "$HOME/.config/nvim"
    rm -rf "$HOME/.config/nvim"
    cp -a "$TMP_DIR/nvimpp" "$HOME/.config/nvim"

    if ! command -v nvim &>/dev/null; then
      ok "~/.config/nvim updated (plugins update on next nvim start)"
    elif nvim --headless "+Lazy! sync" +qa >>"$LOG" 2>&1; then
      ok "~/.config/nvim updated $SEP plugins synchronized"
    else
      ok "~/.config/nvim updated (plugin sync failed — plugins update on next start)"
    fi
  else
    skip "not installed"
  fi

  # --- 4. xssh script (termpp) ---------------------------------------------------

  label "xssh"
  if [ -e "$HOME/.local/bin/xssh" ]; then
    backup "$HOME/.local/bin/xssh"
    if fetch https://raw.githubusercontent.com/vhstack/termpp/main/xssh \
         "$HOME/.local/bin/xssh"; then
      chmod +x "$HOME/.local/bin/xssh"
      ok "~/.local/bin/xssh updated"
    else
      warn "download failed — existing xssh kept"
    fi
  else
    skip "not installed"
  fi

  # --- 5. Self-update ------------------------------------------------------------

  # fetch() replaces via temp file + mv (atomic), so a possibly running
  # copy of this very script is never truncated in place.
  if [ -e "$HOME/.local/bin/vhstack-update" ]; then
    if fetch https://raw.githubusercontent.com/vhstack/vhstack/main/update.sh \
         "$HOME/.local/bin/vhstack-update"; then
      chmod +x "$HOME/.local/bin/vhstack-update"
    fi
  fi

  # --- 6. Version manifest ------------------------------------------------------

  label "version"
  mkdir -p "$STATE_DIR"

  read_version()  { if [ -r "$1" ]; then tr -d ' \t\n\r' <"$1"; else echo unknown; fi; }
  fetch_version() { curl -fsSL "https://raw.githubusercontent.com/vhstack/$1/main/VERSION" 2>>"$LOG" | tr -d ' \t\n\r'; }

  # Das '|| true' muss an den Aufruf: bei 'pipefail' reisst ein
  # fehlgeschlagenes curl die Pipe mit und beendet sonst das Skript.
  NEW_TMUXPP=$(read_version "$HOME/.tmux/VERSION")
  NEW_NVIMPP=$(read_version "$HOME/.config/nvim/VERSION")
  NEW_TERMPP=$(fetch_version termpp   || true); [ -n "$NEW_TERMPP" ]  || NEW_TERMPP=unknown
  NEW_VHSTACK=$(fetch_version vhstack || true); [ -n "$NEW_VHSTACK" ] || NEW_VHSTACK=unknown

  {
    echo "VHSTACK=$NEW_VHSTACK"
    echo "NVIMPP=$NEW_NVIMPP"
    echo "TMUXPP=$NEW_TMUXPP"
    echo "TERMPP=$NEW_TERMPP"
    echo "UPDATED=$(date +%Y-%m-%dT%H:%M:%S%z)"
  } >"$STATE_DIR/versions"
  ok "${STATE_DIR/#$HOME/\~}/versions"

  # Kein '&& return', sondern if/fi -- bei 'set -e' wuerde ein falscher Test
  # als letztes Kommando der Funktion das Skript beenden.
  report() {   # $1 Name  $2 alt  $3 neu
    if [ "$3" = unknown ]; then
      return 0
    elif [ "$2" = unknown ]; then
      printf '                %-7s %sv%s%s %s(first recorded)%s\n' "$1" "$BLU" "$3" "$RST" "$DIM" "$RST"
    elif [ "$2" = "$3" ]; then
      printf '                %s%-7s v%s unchanged%s\n' "$DIM" "$1" "$3" "$RST"
    else
      printf '                %-7s %sv%s%s %s %sv%s%s\n' "$1" "$DIM" "$2" "$RST" "$ARR" "$BLU" "$3" "$RST"
    fi
  }
  # vhstack zuerst: das Skript ersetzt sich oben selbst, die neue Fassung
  # greift also erst beim naechsten Aufruf.
  report vhstack "$OLD_VHSTACK" "$NEW_VHSTACK"
  report nvimpp "$OLD_NVIMPP" "$NEW_NVIMPP"
  report tmuxpp "$OLD_TMUXPP" "$NEW_TMUXPP"
  report termpp "$OLD_TERMPP" "$NEW_TERMPP"

  # --- Summary ------------------------------------------------------------------

  if [ -d "$BACKUP_DIR" ]; then
    label "backup"
    ok "${BACKUP_DIR/#$HOME/\~}"
  fi

  printf '\n  %s%s%s\n' "$DIM" "$RULE" "$RST"
  printf '  %sdone in %ss%s   %stmux reloads with prefix + r (Ctrl+A) %s nvim plugins are in sync%s\n' \
    "$BLD" "$SECONDS" "$RST" "$DIM" "$SEP" "$RST"
}

main "$@"
