#!/usr/bin/env bash
#
# uninstall.sh — Remove the vhstack terminal environment
#
# Removes what install.sh set up:
#   - Tmux configuration (~/.tmux, ~/.tmux.conf), on WSL incl. win32yank.exe
#   - Neovim configuration (~/.config/nvim) and its plugin data
#   - vhstack prompt theme and the init lines in ~/.bashrc / ~/.zshrc
#     (the oh-my-posh binary itself is kept)
#   - xssh and vhstack-update from ~/.local/bin
#
# The backup directories (~/.vhstack-backup-*) are kept untouched — they
# hold your configurations from before the installation. Restore by hand
# if needed, e.g.:  cp -a ~/.vhstack-backup-<timestamp>/.tmux ~/
#
# Quick uninstall (asks for confirmation on the terminal):
#
#   curl -sL https://raw.githubusercontent.com/vhstack/vhstack/main/uninstall.sh | bash
#
# Non-interactive (no confirmation, e.g. for automation):
#
#   curl -sL https://raw.githubusercontent.com/vhstack/vhstack/main/uninstall.sh | bash -s -- --yes

set -euo pipefail

# shellcheck disable=SC2088  # Tilden in Meldungstexten sind reine Anzeige (~/...), keine Pfade

# Alles in main(): bash parst so das komplette Skript, bevor der erste
# Befehl laeuft — bei 'curl | bash' darf kein Kindprozess den restlichen
# Skripttext von stdin verschlucken (siehe install.sh).
main() {

  assumeyes=no
  case "${1:-}" in
    -y|--yes) assumeyes=yes ;;
    "") ;;
    *) echo "usage: uninstall.sh [--yes]" >&2; exit 2 ;;
  esac

  BACKUP_DIR="$HOME/.vhstack-backup-uninstall-$(date +%Y%m%d-%H%M%S)"
  POINTER="${XDG_CACHE_HOME:-$HOME/.cache}/tmuxpp/win32yank.path"

  # --- Ausgabe im Stil der Landing-Page (vhstack.github.io): Module blau,
  # Erfolg gruen, Hinweise peach, Nebensaechliches gedimmt. Catppuccin-
  # Truecolor wo das Terminal es meldet, sonst die 16 Standardfarben;
  # ohne Terminal (Pipe) oder mit NO_COLOR bleibt alles schmucklos.
  # shellcheck disable=SC2034  # RED gehoert zur gemeinsamen Palette der drei Skripte
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

  # Unterbefehle schreiben in ein Log, das nur bei Problemen gezeigt wird.
  LOG=$(mktemp)
  trap 'rm -f "$LOG"' EXIT

  label()   { : >"$LOG"; printf '  %s%-10s%s ' "$BLU" "$1" "$RST"; }
  ok()      { printf '%s%s%s %s\n' "$GRN" "$CHK" "$RST" "$1"; }
  warn()    { printf '%s%s%s %s\n' "$PCH" "$WRN" "$RST" "$1"; }
  showlog() { if [ -s "$LOG" ]; then sed "s/^/                $DIM/;s/\$/$RST/" "$LOG"; fi; }
  # Gedimmte Folgezeile, buendig unter der Nachrichtenspalte (16 = 2 Rand
  # + 10 Label + 1 + 2 Statusmarke + 1)
  extra()   { printf '                %s%s%s\n' "$DIM" "$1" "$RST"; }

  is_wsl() {
    [ -n "${WSL_DISTRO_NAME:-}" ] && return 0
    grep -qi microsoft /proc/version 2>/dev/null
  }

  # Alle '# vhstack: ...'-Marker (TERM, COLORTERM, PATH) plus der omp-Marker;
  # jeder Block ist Marker-Zeile + genau eine Folgezeile (siehe install.sh).
  rc_has_markers() {
    [ -f "$1" ] && grep -Eq \
      "^# (vhstack: |oh-my-posh vhstack/termpp theme$)" "$1"
  }

  # Kopf wie auf der Landing-Page: Name mit Block-Cursor, Quelle rechtsbuendig
  printf '\n  %svhstack uninstall%s %s%s%s%42s%svhstack.github.io%s\n' \
    "$BLD" "$RST" "$PCH" "$CUR" "$RST" '' "$DIM" "$RST"
  printf '  %s%s%s\n\n' "$DIM" "$RULE" "$RST"

  # --- What is installed? -----------------------------------------------------

  found=no
  have_tmux=no; have_wy=no; have_nvim=no; have_theme=no; have_rc=no
  have_xssh=no; have_update=no

  printf '  %sfound components%s\n' "$PCH" "$RST"
  if [ -e "$HOME/.tmux/clipboard.sh" ] || [ -L "$HOME/.tmux.conf" ]; then
    have_tmux=yes; found=yes
    echo "    - Tmux configuration (~/.tmux, ~/.tmux.conf)"
  fi
  if [ -r "$POINTER" ]; then
    have_wy=yes; found=yes
    echo "    - win32yank.exe (WSL clipboard)"
  fi
  if [ -e "$HOME/.config/nvim/init.lua" ]; then
    have_nvim=yes; found=yes
    echo "    - Neovim configuration (~/.config/nvim + plugin data)"
  fi
  if [ -e "$HOME/.config/ohmyposh/vhstack.omp.json" ]; then
    have_theme=yes; found=yes
    echo "    - prompt theme (~/.config/ohmyposh/vhstack.omp.json)"
  fi
  for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
    if rc_has_markers "$rc"; then
      have_rc=yes; found=yes
    fi
  done
  if [ "$have_rc" = yes ]; then
    echo "    - vhstack init lines in ~/.bashrc / ~/.zshrc"
  fi
  if [ -e "$HOME/.local/bin/xssh" ]; then
    have_xssh=yes; found=yes
    echo "    - xssh (~/.local/bin/xssh)"
  fi
  if [ -e "$HOME/.local/bin/vhstack-update" ] || [ -e "$HOME/.local/bin/update-vhstack" ]; then
    have_update=yes; found=yes
    echo "    - vhstack-update (~/.local/bin/vhstack-update)"
  fi

  if [ "$found" = no ]; then
    printf '  %s(none)%s\n\nnothing to do — no vhstack installation found.\n' "$DIM" "$RST"
    exit 0
  fi

  # --- Confirmation -------------------------------------------------------------

  # Bei 'curl | bash' ist stdin das Skript selbst — die Rueckfrage muss
  # deshalb vom Terminal (/dev/tty) gelesen werden. Ob ein steuerndes
  # Terminal existiert, zeigt nur ein Probe-Open ('-r /dev/tty' waere auch
  # ohne Terminal wahr, weil die Geraetedatei immer existiert).
  echo
  if [ "$assumeyes" != yes ]; then
    if { : </dev/tty; } 2>/dev/null; then
      printf "remove these components? backups (~/.vhstack-backup-*) are kept. [y/N] " >/dev/tty
      IFS= read -r answer </dev/tty || answer=""
      case "$answer" in
        y|Y|yes|j|J) echo ;;
        *) echo "aborted — nothing changed."; exit 0 ;;
      esac
    else
      label "confirm"
      warn "no terminal available for the confirmation prompt — run non-interactively with:"
      extra "curl -sL https://raw.githubusercontent.com/vhstack/vhstack/main/uninstall.sh | bash -s -- --yes"
      exit 1
    fi
  fi

  # --- 1. win32yank (must run BEFORE ~/.tmux disappears) ------------------------

  if [ "$have_wy" = yes ] || { is_wsl && [ -f "$HOME/.tmux/install_win32yank.sh" ]; }; then
    label "clipboard"
    if [ -f "$HOME/.tmux/install_win32yank.sh" ]; then
      if sh "$HOME/.tmux/install_win32yank.sh" --remove </dev/null >>"$LOG" 2>&1; then
        ok "win32yank.exe removed"
      else
        warn "win32yank removal reported a problem — continuing"
        showlog
      fi
    elif [ -r "$POINTER" ]; then
      # ~/.tmux ist schon weg — Restbestaende anhand der Pfad-Datei aufraeumen.
      exe=$(cat "$POINTER" 2>/dev/null || true)
      case "$exe" in
        */win32yank/win32yank.exe) rm -rf "${exe%/win32yank.exe}" ;;
      esac
      rm -f "$POINTER"
      for d in "$HOME/.local/bin" "$HOME/bin"; do
        f="$d/win32yank.exe"
        if [ -L "$f" ]; then
          case "$(readlink "$f" 2>/dev/null)" in
            */win32yank/win32yank.exe) rm -f "$f" ;;
          esac
        fi
      done
      ok "win32yank.exe leftovers removed"
    fi
    rmdir "$(dirname "$POINTER")" 2>/dev/null || true
  fi

  # --- 2. Tmux -------------------------------------------------------------------

  if [ "$have_tmux" = yes ]; then
    label "tmux"
    if [ -e "$HOME/.tmux/.git" ]; then
      warn "~/.tmux is a git repository — left untouched (not an install.sh setup)"
    elif [ -e "$HOME/.tmux/clipboard.sh" ] || [ ! -d "$HOME/.tmux" ]; then
      removed=""
      if [ -e "$HOME/.tmux/clipboard.sh" ]; then
        rm -rf "$HOME/.tmux"
        removed="~/.tmux"
      fi
      if [ -L "$HOME/.tmux.conf" ] &&
         [ "$(readlink "$HOME/.tmux.conf" 2>/dev/null)" = "$HOME/.tmux/tmux.conf" ]; then
        rm -f "$HOME/.tmux.conf"
        removed="${removed:+$removed, }~/.tmux.conf"
      fi
      ok "removed: $removed"
    else
      warn "~/.tmux does not look like a vhstack installation — left untouched"
    fi
  fi

  # --- 3. Neovim -------------------------------------------------------------------

  if [ "$have_nvim" = yes ]; then
    label "neovim"
    if [ -e "$HOME/.config/nvim/.git" ]; then
      warn "~/.config/nvim is a git repository — left untouched"
    else
      rm -rf "$HOME/.config/nvim"
      rm -rf "$HOME/.local/share/nvim" "$HOME/.local/state/nvim" "$HOME/.cache/nvim"
      ok "removed: ~/.config/nvim and plugin data"
    fi
  fi

  # --- 4. Prompt: theme and shell init lines ---------------------------------------

  if [ "$have_theme" = yes ] || [ "$have_rc" = yes ]; then
    label "prompt"
    parts=""
    if [ "$have_theme" = yes ]; then
      rm -f "$HOME/.config/ohmyposh/vhstack.omp.json"
      rmdir "$HOME/.config/ohmyposh" 2>/dev/null || true
      parts="theme removed"
    fi
    for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
      if rc_has_markers "$rc"; then
        mkdir -p "$BACKUP_DIR"
        cp "$rc" "$BACKUP_DIR/$(basename "$rc")"
        # Nur die vom Installer gesetzten Bloecke entfernen: Marker-Zeile
        # plus die eine Folgezeile. awk statt sed, damit es auch auf macOS
        # laeuft (BSD-sed kennt kein ',+1d').
        tmp=$(mktemp)
        awk '
          /^# vhstack: /                         { skip = 2 }
          /^# oh-my-posh vhstack\/termpp theme$/ { skip = 2 }
          skip > 0 { skip--; next }
          { print }
        ' "$rc" > "$tmp"
        cat "$tmp" > "$rc"   # cat statt mv: Rechte und Inode der rc-Datei bleiben
        rm -f "$tmp"
        parts="${parts:+$parts, }${rc/#$HOME/\~} cleaned"
      fi
    done
    ok "$parts"
    extra "the oh-my-posh binary is kept (~/.local/bin/oh-my-posh) — delete it manually if unwanted"
  fi

  # --- 5. Helper commands ------------------------------------------------------------

  if [ "$have_xssh" = yes ]; then
    label "xssh"
    rm -f "$HOME/.local/bin/xssh"
    ok "removed: ~/.local/bin/xssh"
  fi
  if [ "$have_update" = yes ]; then
    label "update"
    rm -f "$HOME/.local/bin/vhstack-update" "$HOME/.local/bin/update-vhstack"
    ok "removed: ~/.local/bin/vhstack-update"
  fi

  # Das Versionsmanifest von install.sh/update.sh mit abraeumen -- sonst
  # bleibt ~/.local/state/vhstack liegen und beschreibt nichts mehr.
  STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/vhstack"
  if [ -d "$STATE_DIR" ]; then
    label "version"
    rm -rf "$STATE_DIR"
    ok "removed: ${STATE_DIR/#$HOME/\~}"
  fi

  # --- Summary --------------------------------------------------------------------

  printf '\n  %s%s%s\n' "$DIM" "$RULE" "$RST"
  printf '  %sdone%s   vhstack environment removed %s%s start a new shell session%s\n' \
    "$BLD" "$RST" "$DIM" "$SEP" "$RST"
  backups=("$HOME"/.vhstack-backup-*)
  if [ -e "${backups[0]}" ]; then
    echo
    printf '  %sbackups kept%s %s— your configurations from before the installation:%s\n' \
      "$PCH" "$RST" "$DIM" "$RST"
    for b in "${backups[@]}"; do
      printf '  %s\n' "${b/#$HOME/\~}"
    done
    printf '  %srestore by hand if needed, e.g.: cp -a <backup>/.tmux ~/%s\n' "$DIM" "$RST"
  fi
}

main "$@"
