<p align="right">
  <a href="README.md"><img src="assets/flag-de.png" width="16" height="12" alt="Deutsch" title="Zur deutschen Version wechseln" /></a>  
  <a href="README.en.md"><img src="assets/flag-gb.png" width="16" height="12" alt="English" title="Switch to English" /></a>  
  <a href="README.ru.md"><img src="assets/flag-ru.png" width="16" height="12" alt="Русский" title="Переключиться на русскую версию" /></a>
</p>

<p align="center">
  <img src="assets/vhstack.svg" width="160" alt="vhstack" />
</p>

# nvimpp, tmuxpp, termpp – dein Terminal, dein Code, dein Stil

[![Version](https://img.shields.io/github/v/tag/vhstack/vhstack?label=version&sort=semver&color=8aadf4)](https://github.com/vhstack/vhstack/tags)

[![CI](https://github.com/vhstack/vhstack/actions/workflows/ci.yml/badge.svg)](https://github.com/vhstack/vhstack/actions/workflows/ci.yml)

Hallo, ich bin **vhstack** 👋

Willkommen auf meinem GitHub-Profil!  

Hier findest du meine persönlich kuratierten Projekte, die dir helfen, dein Terminal-Erlebnis, 
deinen Code und deinen individuellen Stil zu optimieren. Anders als viele einzelne Setups, die man im Netz findet, 
sind diese Projekte bewusst aufeinander abgestimmt. Sie ergänzen sich sinnvoll – visuell, funktional 
und mit Fokus auf den täglichen Workflow.

## ⚡ Schnellstart

Auf einem frischen System zuerst die Pakete installieren:

```bash
sudo apt update
sudo apt install tmux neovim unzip ripgrep clangd
```

Dann installiert ein Befehl die komplette Arbeitsumgebung (Prompt, Tmux,
Neovim) auf dem Server:

```bash
curl -sL https://raw.githubusercontent.com/vhstack/vhstack/main/install.sh | bash
```

![vhstack install – ein Befehl richtet alles ein](assets/install.gif)

Was das Skript im Einzelnen tut, steht in der
[Installationsanleitung](./INSTALL.md).

Später bringt ein Befehl alles auf den aktuellen Stand:

```bash
vhstack-update
```

## 🔧 Meine Projekte

### <img src="assets/vhstack.svg" width="20" height="20" style="vertical-align:middle; margin-right: 6px;" /> [nvimpp](https://github.com/vhstack/nvimpp)
**Neovim als C/C++-IDE:**  
clangd, Telescope, Treesitter, Neo-tree und Outline, lazy geladen und in unter 100 ms startklar.

### <img src="assets/vhstack.svg" width="20" height="20" style="vertical-align:middle; margin-right: 6px;" /> [tmuxpp](https://github.com/vhstack/tmuxpp)
**Tmux, das einfach funktioniert:**  
Kopieren und Einfügen mit der Maus in die System-Zwischenablage, auch über SSH per OSC 52. Sinnvolle Tasten, drei Themes, kein Plugin-Manager.

### <img src="assets/vhstack.svg" width="20" height="20" style="vertical-align:middle; margin-right: 6px;" /> [termpp](https://github.com/vhstack/termpp)
**Terminal, Nerd Font und Prompt:**  
Windows Terminal mit Catppuccin und Cascadia Code NF. Der Oh-My-Posh-Prompt zeigt Git-Status, Fehler und Laufzeit, True Color reicht bis zum Server.

## ✨ Über mich

Ich verbringe seit Jahren mehr Zeit im Terminal als auf Social Media – und habe dabei gelernt, dass gute Software-Entwicklung mit einer richtig 
eingerichteten Umgebung beginnt. Mit diesen Projekten möchte ich anderen helfen, effizient und mit Freude im Terminal zu arbeiten – sei es in der Shell 
oder in Tools wie Neovim.

---

*„Der Code, den wir schreiben, ist ein Ausdruck unseres Selbst – mach ihn so individuell wie du.“*

MIT-Lizenz · [vhstack.github.io](https://vhstack.github.io)
