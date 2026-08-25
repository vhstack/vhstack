# vhstack — „vhstack-update“ (Bonus-GIF)
# Ein Befehl bringt alles auf Stand — mit alt→neu-Report.

Output update.gif

Set Width 1000
Set Height 640
Set Framerate 15
Set FontSize 15
Set Padding 16
Set FontFamily "CaskaydiaCove Nerd Font Mono"
Set Theme "Catppuccin Mocha"
Set Shell bash
Set TypingSpeed 55ms

# ── Setup (unsichtbar): ältere Versionsstände simulieren, vh@stack-Shell ──
Hide
Type "SP=${VHS_DEMO_DIR:-$HOME/.cache/vhstack-demo}; FH=$SP/fakehome"
Enter
Type "git config --file $FH/.gitconfig user.name vh; git config --file $FH/.gitconfig user.email vh@stack.invalid"
Enter
Type "V=$FH/.local/state/vhstack/versions; sed -i 's/^VHSTACK=.*/VHSTACK=0.9.2/;s/^NVIMPP=.*/NVIMPP=1.4.1/;s/^TMUXPP=.*/TMUXPP=1.1.0/;s/^TERMPP=.*/TERMPP=1.1.2/' $V"
Enter
Type "export PATH=$SP/nvim-shim:$(echo $PATH | tr ':' '\n' | grep -vx $HOME/.local/bin | paste -sd:)"
Enter
Type "exec $SP/stackshell $FH"
Enter
Sleep 2s
Type "clear"
Enter
Sleep 500ms
Show

# ── Ein Befehl: vhstack-update ──
Sleep 2s
Type "vhstack-update"
Sleep 600ms
Enter
Wait+Screen@120s /done in \d+s/
Sleep 4.5s
