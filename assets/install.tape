# vhstack — „Ein Befehl“ (Hero-GIF)
# Frische Maschine (Fake-HOME) → curl-Einzeiler → Prompt/Tmux/Neovim verwandelt.

Output install.gif

Set Width 1000
Set Height 640
Set Framerate 15
Set FontSize 15
Set Padding 16
Set FontFamily "CaskaydiaCove Nerd Font Mono"
Set Theme "Catppuccin Mocha"
Set Shell bash
Set TypingSpeed 55ms

# ── Setup (unsichtbar): Fake-HOME, Demo-nvim im PATH, vh@stack-Namespace ──
Hide
Type "SP=${VHS_DEMO_DIR:-$HOME/.cache/vhstack-demo}"
Enter
Type "FH=$SP/fakehome; rm -rf $FH; mkdir -p $FH/.local/share; cp /etc/skel/.bashrc /etc/skel/.profile $FH/; touch $FH/.hushlogin"
Enter
Type "git config --file $FH/.gitconfig user.name vh; git config --file $FH/.gitconfig user.email vh@stack.invalid"
Enter
Type "export PATH=$SP/nvim-shim:$(echo $PATH | tr ':' '\n' | grep -vx $HOME/.local/bin | paste -sd:)"
Enter
Type "tmux -L vhsdemo kill-server 2>/dev/null"
Enter
Type "exec $SP/stackshell $FH"
Enter
Sleep 2s
Type "alias tmux='tmux -L vhsdemo'"
Enter
Type "clear"
Enter
Sleep 500ms
Show

# ── Szene 1: der Vorher-Zustand ──
Sleep 2.5s

# ── Szene 2+3: der Einzeiler, getippt — Installer läuft ──
Type "curl -sL https://raw.githubusercontent.com/vhstack/vhstack/main/install.sh | bash"
Sleep 900ms
Enter
Wait+Screen@90s /done in \d+s/
Sleep 3s

# ── Szene 4: Prompt verwandelt sich ──
Type "source ~/.bashrc"
Sleep 500ms
Enter
Sleep 3.5s

# ── Szene 5: tmux — Statusleiste erscheint ──
Type "tmux"
Sleep 500ms
Enter
Sleep 4s

# ── Szene 6: nvim — Dashboard ──
Type "nvim"
Sleep 500ms
Enter
Sleep 5s

# ── Szene 7: zurück zum Report, Schlussframe auf „done in Xs“ ──
Type ":q"
Sleep 300ms
Enter
Sleep 1.5s
Type "exit"
Sleep 300ms
Enter
Sleep 4s
