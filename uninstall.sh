#!/usr/bin/env bash
#
# uninstall.sh — Remove the vhstack terminal environment
#
# Removes what install.sh set up:
#   - Tmux configuration (~/.tmux, ~/.tmux.conf), on WSL incl. win32yank.exe
#   - Neovim configuration (~/.config/nvim) and its plugin data
#   - vhstack prompt theme and the init lines in ~/.bashrc / ~/.zshrc
#     (the oh-my-posh binary itself is kept)
#   - xssh and update-vhstack from ~/.local/bin
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

  info()  { echo "ℹ️  $*"; }
  ok()    { echo "✅ $*"; }
  warn()  { echo "⚠️  $*"; }
  step()  { echo; echo "==> $*"; }

  is_wsl() {
    [ -n "${WSL_DISTRO_NAME:-}" ] && return 0
    grep -qi microsoft /proc/version 2>/dev/null
  }

  rc_has_markers() {
    [ -f "$1" ] && grep -Eq \
      "^# (vhstack: true color support|oh-my-posh vhstack/termpp theme)$" "$1"
  }

  # --- What is installed? -----------------------------------------------------

  step "Looking for vhstack components"

  found=no
  have_tmux=no; have_wy=no; have_nvim=no; have_theme=no; have_rc=no
  have_xssh=no; have_update=no

  if [ -e "$HOME/.tmux/clipboard.sh" ] || [ -L "$HOME/.tmux.conf" ]; then
    have_tmux=yes; found=yes
    echo "  - Tmux configuration (~/.tmux, ~/.tmux.conf)"
  fi
  if [ -r "$POINTER" ]; then
    have_wy=yes; found=yes
    echo "  - win32yank.exe (WSL clipboard)"
  fi
  if [ -e "$HOME/.config/nvim/init.lua" ]; then
    have_nvim=yes; found=yes
    echo "  - Neovim configuration (~/.config/nvim + plugin data)"
  fi
  if [ -e "$HOME/.config/ohmyposh/vhstack.omp.json" ]; then
    have_theme=yes; found=yes
    echo "  - Prompt theme (~/.config/ohmyposh/vhstack.omp.json)"
  fi
  for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
    if rc_has_markers "$rc"; then
      have_rc=yes; found=yes
    fi
  done
  if [ "$have_rc" = yes ]; then
    echo "  - vhstack init lines in ~/.bashrc / ~/.zshrc"
  fi
  if [ -e "$HOME/.local/bin/xssh" ]; then
    have_xssh=yes; found=yes
    echo "  - xssh (~/.local/bin/xssh)"
  fi
  if [ -e "$HOME/.local/bin/update-vhstack" ]; then
    have_update=yes; found=yes
    echo "  - update-vhstack (~/.local/bin/update-vhstack)"
  fi

  if [ "$found" = no ]; then
    ok "Nothing to do — no vhstack installation found."
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
      printf "Remove these components? Backups (~/.vhstack-backup-*) are kept. [y/N] " >/dev/tty
      IFS= read -r answer </dev/tty || answer=""
      case "$answer" in
        y|Y|yes|j|J) ;;
        *) echo "Aborted — nothing changed."; exit 0 ;;
      esac
    else
      warn "No terminal available for the confirmation prompt."
      warn "Run non-interactively with:"
      warn "  curl -sL https://raw.githubusercontent.com/vhstack/vhstack/main/uninstall.sh | bash -s -- --yes"
      exit 1
    fi
  fi

  # --- 1. win32yank (must run BEFORE ~/.tmux disappears) ------------------------

  if [ "$have_wy" = yes ] || { is_wsl && [ -f "$HOME/.tmux/install_win32yank.sh" ]; }; then
    step "Removing win32yank.exe"
    if [ -f "$HOME/.tmux/install_win32yank.sh" ]; then
      sh "$HOME/.tmux/install_win32yank.sh" --remove </dev/null ||
        warn "win32yank removal reported a problem — continuing."
    elif [ -r "$POINTER" ]; then
      # ~/.tmux ist schon weg — Restbestaende anhand der Pfad-Datei aufraeumen.
      exe=$(cat "$POINTER" 2>/dev/null || true)
      case "$exe" in
        */win32yank/win32yank.exe)
          rm -rf "${exe%/win32yank.exe}"
          info "Removed: ${exe%/win32yank.exe}"
          ;;
      esac
      rm -f "$POINTER"
      for d in "$HOME/.local/bin" "$HOME/bin"; do
        f="$d/win32yank.exe"
        if [ -L "$f" ]; then
          case "$(readlink "$f" 2>/dev/null)" in
            */win32yank/win32yank.exe) rm -f "$f"; info "Removed: $f" ;;
          esac
        fi
      done
    fi
    rmdir "$(dirname "$POINTER")" 2>/dev/null || true
  fi

  # --- 2. Tmux -------------------------------------------------------------------

  if [ "$have_tmux" = yes ]; then
    step "Removing Tmux configuration"
    if [ -e "$HOME/.tmux/.git" ]; then
      warn "~/.tmux is a git repository — leaving it untouched (not an install.sh setup)."
    elif [ -e "$HOME/.tmux/clipboard.sh" ]; then
      rm -rf "$HOME/.tmux"
      ok "Removed: ~/.tmux"
    elif [ -d "$HOME/.tmux" ]; then
      warn "~/.tmux does not look like a vhstack installation — leaving it untouched."
    fi
    if [ -L "$HOME/.tmux.conf" ] &&
       [ "$(readlink "$HOME/.tmux.conf" 2>/dev/null)" = "$HOME/.tmux/tmux.conf" ]; then
      rm -f "$HOME/.tmux.conf"
      ok "Removed: ~/.tmux.conf (symlink)"
    fi
  fi

  # --- 3. Neovim -------------------------------------------------------------------

  if [ "$have_nvim" = yes ]; then
    step "Removing Neovim configuration"
    if [ -e "$HOME/.config/nvim/.git" ]; then
      warn "~/.config/nvim is a git repository — leaving it untouched."
    else
      rm -rf "$HOME/.config/nvim"
      ok "Removed: ~/.config/nvim"
      rm -rf "$HOME/.local/share/nvim" "$HOME/.local/state/nvim" "$HOME/.cache/nvim"
      ok "Removed: Neovim plugin data (~/.local/share, ~/.local/state, ~/.cache)"
    fi
  fi

  # --- 4. Prompt: theme and shell init lines ---------------------------------------

  if [ "$have_theme" = yes ] || [ "$have_rc" = yes ]; then
    step "Removing prompt theme and shell init lines"
    if [ "$have_theme" = yes ]; then
      rm -f "$HOME/.config/ohmyposh/vhstack.omp.json"
      rmdir "$HOME/.config/ohmyposh" 2>/dev/null || true
      ok "Removed: ~/.config/ohmyposh/vhstack.omp.json"
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
          /^# vhstack: true color support$/      { skip = 2 }
          /^# oh-my-posh vhstack\/termpp theme$/ { skip = 2 }
          skip > 0 { skip--; next }
          { print }
        ' "$rc" > "$tmp"
        cat "$tmp" > "$rc"   # cat statt mv: Rechte und Inode der rc-Datei bleiben
        rm -f "$tmp"
        info "Cleaned $rc (copy saved to $BACKUP_DIR/$(basename "$rc"))"
      fi
    done
    info "The oh-my-posh binary is kept (~/.local/bin/oh-my-posh) — delete it manually if unwanted."
  fi

  # --- 5. Helper commands ------------------------------------------------------------

  if [ "$have_xssh" = yes ] || [ "$have_update" = yes ]; then
    step "Removing helper commands"
    if [ "$have_xssh" = yes ]; then
      rm -f "$HOME/.local/bin/xssh"
      ok "Removed: ~/.local/bin/xssh"
    fi
    if [ "$have_update" = yes ]; then
      rm -f "$HOME/.local/bin/update-vhstack"
      ok "Removed: ~/.local/bin/update-vhstack"
    fi
  fi

  # --- Summary --------------------------------------------------------------------

  echo
  echo "══════════════════════════════════════════════════════════════"
  ok "vhstack environment removed."
  if ls -d "$HOME"/.vhstack-backup-* >/dev/null 2>&1; then
    echo
    echo "Backup directories were kept — they hold your configurations from"
    echo "before the installation:"
    ls -d "$HOME"/.vhstack-backup-* | sed 's/^/  /'
    echo "Restore by hand if needed, e.g.:  cp -a <backup>/.tmux ~/"
  fi
  echo
  echo "Start a new shell session for a clean prompt."
}

main "$@"
