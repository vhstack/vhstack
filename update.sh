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
# install.sh also installs this script as ~/.local/bin/update-vhstack,
# so after the initial install you can simply run: update-vhstack

set -euo pipefail

# Alles in main(): bash parst so das komplette Skript, bevor der erste
# Befehl laeuft. Bei 'curl | bash' kann sonst ein Kindprozess, der stdin
# liest (etwa cmd.exe/win32yank.exe ueber die WSL-Interop), den restlichen
# Skripttext verschlucken -- das Skript endet dann still mitten im Lauf.
main() {

  SECONDS=0
  BACKUP_DIR="$HOME/.vhstack-backup-update-$(date +%Y%m%d-%H%M%S)"
  TMP_DIR=$(mktemp -d)
  trap 'rm -rf "$TMP_DIR"' EXIT

  # --- Ausgabe: feste Label-Spalte, Status dezent farbig (nur am Terminal).
  # Unterbefehle schreiben in ein Log, das nur im Fehlerfall gezeigt wird.
  if [ -t 1 ]; then
    BLD=$'\033[1m'; DIM=$'\033[2m'; GRN=$'\033[32m'; YEL=$'\033[33m'
    RED=$'\033[31m'; RST=$'\033[0m'
  else
    BLD=""; DIM=""; GRN=""; YEL=""; RED=""; RST=""
  fi
  LOG="$TMP_DIR/log"

  label()   { : >"$LOG"; printf '  %-10s ' "$1"; }
  ok()      { printf '%sok%s      %s\n' "$GRN" "$RST" "$1"; }
  warn()    { printf '%swarn%s    %s\n' "$YEL" "$RST" "$1"; }
  skip()    { printf '%s--      %s%s\n' "$DIM" "$1" "$RST"; }
  showlog() { if [ -s "$LOG" ]; then sed "s/^/          $DIM/;s/\$/$RST/" "$LOG"; fi; }
  fail()    { printf '%sfail%s    %s\n' "$RED" "$RST" "$1"; showlog; exit 1; }
  note()    { printf '  %-10s %s\n' "$1" "$2"; }

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

  printf '%svhstack update%s  %s·  vhstack.github.io%s\n\n' "$BLD" "$RST" "$DIM" "$RST"

  # --- 0. Preconditions -------------------------------------------------------

  for tool in git curl; do
    command -v "$tool" &>/dev/null || {
      printf '  %sfail%s    '\''%s'\'' is required but not installed.\n' "$RED" "$RST" "$tool"
      exit 1
    }
  done

  if [ ! -e "$HOME/.config/ohmyposh/vhstack.omp.json" ] \
     && [ ! -e "$HOME/.tmux/tmux.conf" ] \
     && [ ! -e "$HOME/.config/nvim/init.lua" ]; then
    printf '  %sfail%s    no vhstack installation found — run install.sh first:\n' "$RED" "$RST"
    echo   "          curl -sL https://raw.githubusercontent.com/vhstack/vhstack/main/install.sh | bash"
    exit 1
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
      ok "~/.tmux updated, running session reloaded"
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
      ok "~/.config/nvim updated, plugins synchronized"
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
  if [ -e "$HOME/.local/bin/update-vhstack" ]; then
    if fetch https://raw.githubusercontent.com/vhstack/vhstack/main/update.sh \
         "$HOME/.local/bin/update-vhstack"; then
      chmod +x "$HOME/.local/bin/update-vhstack"
    fi
  fi

  # --- Summary ------------------------------------------------------------------

  if [ -d "$BACKUP_DIR" ]; then
    label "backup"
    ok "${BACKUP_DIR/#$HOME/\~}"
  fi
  printf '\n%sdone in %ss.%s tmux reloads with prefix + r (Ctrl+A), nvim plugins are in sync.\n' "$BLD" "$SECONDS" "$RST"
}

main "$@"
