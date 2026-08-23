#!/usr/bin/env bash
# Rendert die Demo-GIFs dieses Repos reproduzierbar neu:  bash assets/record.sh
# Voraussetzungen: vhs, ttyd, ffmpeg im PATH · Nerd Font „CaskaydiaCove Nerd Font Mono“
# (github.com/ryanoasis/nerd-fonts, CascadiaCode.zip) · git, curl, cmake, g++, tmux.
set -euo pipefail
cd "$(dirname "$0")"

DEMO="${VHS_DEMO_DIR:-$HOME/.cache/vhstack-demo}"
export VHS_DEMO_DIR="$DEMO"
mkdir -p "$DEMO"

# --- Demo-Shell: läuft als vh@stack (User+UTS-Namespace), optional mit Fake-HOME ---
cat >"$DEMO/stackshell" <<'EOF'
#!/usr/bin/env bash
H="${1:-$HOME}"; U=$(id -u); G=$(id -g)
exec unshare -r --uts /bin/bash -c \
  "hostname stack; cd '$H'; exec env HOME='$H' unshare --user --map-user=$U --map-group=$G /bin/bash -i"
EOF
chmod +x "$DEMO/stackshell"

# --- nvim-Tarball: snap-nvim funktioniert nicht im User-Namespace ---
if [ ! -x "$DEMO/nvim-demo/bin/nvim" ]; then
  echo "record: lade Neovim-Tarball nach $DEMO/nvim-demo"
  curl -sL -o "$DEMO/nvim.tgz" \
    https://github.com/neovim/neovim/releases/download/stable/nvim-linux-x86_64.tar.gz
  rm -rf "$DEMO/nvim-demo" "$DEMO/nvim-linux-x86_64"
  tar xzf "$DEMO/nvim.tgz" -C "$DEMO" && mv "$DEMO/nvim-linux-x86_64" "$DEMO/nvim-demo"
fi

# --- nvim-Shim: Headless-Sync sofort quittieren (Plugins sind synchron), ---
# --- interaktiv echtes nvim mit den synchronen Plugins des Host-Users.   ---
mkdir -p "$DEMO/nvim-shim"
cat >"$DEMO/nvim-shim/nvim" <<EOF
#!/usr/bin/env bash
for a in "\$@"; do [ "\$a" = "--headless" ] && exit 0; done
export XDG_DATA_HOME=$HOME/.local/share
exec $DEMO/nvim-demo/bin/nvim "\$@"
EOF
chmod +x "$DEMO/nvim-shim/nvim"

# --- Fake-HOME („frische Maschine“ nach vhstack-Install) für Tapes, ---
# --- die es fertig erwarten. install.tape baut es stets selbst neu. ---
if [ ! -e "$DEMO/fakehome/.tmux.conf" ] && [ ! -e install.tape ]; then
  echo "record: installiere vhstack ins Fake-HOME"
  FH="$DEMO/fakehome"; mkdir -p "$FH/.local/share"
  cp /etc/skel/.bashrc /etc/skel/.profile "$FH/" 2>/dev/null || true
  touch "$FH/.hushlogin"
  CLEANPATH=$(echo "$PATH" | tr ':' '\n' | grep -vx "$HOME/.local/bin" | paste -sd:)
  HOME="$FH" PATH="$DEMO/nvim-shim:$CLEANPATH" bash -c \
    'curl -sL https://raw.githubusercontent.com/vhstack/vhstack/main/install.sh | bash' >/dev/null
fi

# --- orbit (C++-Demo-Projekt aus nvimpp) für termpp/tmuxpp/nvimpp-Tapes ---
if [ -e prompt.tape ] || [ -e sessions.tape ] || [ -e ide.tape ]; then
  ORBIT="${VHS_ORBIT_DIR:-}"
  [ -n "$ORBIT" ] || { [ -d demo/orbit ] && ORBIT="$PWD/demo/orbit"; } || true
  [ -n "$ORBIT" ] || { [ -d ../../nvimpp/assets/demo/orbit ] && ORBIT="$(cd ../../nvimpp/assets/demo/orbit && pwd)"; } || true
  if [ -z "$ORBIT" ]; then
    [ -d "$DEMO/nvimpp-src" ] || git clone -q --depth 1 https://github.com/vhstack/nvimpp "$DEMO/nvimpp-src"
    ORBIT="$DEMO/nvimpp-src/assets/demo/orbit"
  fi
  if [ ! -x "$ORBIT/build/orbit" ]; then
    echo "record: baue orbit"
    cmake -S "$ORBIT" -B "$ORBIT/build" >/dev/null && cmake --build "$ORBIT/build" >/dev/null
  fi
  export VHS_ORBIT_DIR="$ORBIT"
fi

# --- Rendern ---
for t in *.tape; do
  echo "record: rendere $t"
  vhs "$t"
done
