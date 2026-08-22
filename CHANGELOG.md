# Changelog

Dieses Projekt folgt [Semantic Versioning](https://semver.org/lang/de/).

Für eine Konfigurationssammlung gilt:

- **major** — Update braucht Handarbeit (Pfade, Keybindings, Breaking Change)
- **minor** — neue Funktionen, abwärtskompatibel
- **patch** — Fehlerbehebungen, Feinschliff

## [1.0.0] — 2026-08-22

Erstes getaggtes Release des Installers. Der Stand entspricht der bisherigen
Entwicklung auf `main` (seit 2025-04-14).

### Komponenten in diesem Release

| Komponente | Version |
| ---------- | ------- |
| nvimpp     | v1.5.0  |
| tmuxpp     | v1.2.0  |
| termpp     | v1.2.0  |

`install.sh` klont weiterhin `main` — diese Tabelle dokumentiert den Stand zum
Zeitpunkt des Release, sie legt ihn nicht fest.

### Enthalten

- `install.sh` richtet Prompt, tmux, Neovim und `xssh` in einem Lauf ein und
  legt vorhandene Konfigurationen vorher nach `~/.vhstack-backup-<Zeitstempel>`
- `update.sh` bringt eine bestehende Installation auf den neuesten Stand, ohne
  die Shell-Startdateien anzufassen; wird als `update-vhstack` mitinstalliert
- `uninstall.sh` entfernt die Umgebung und lässt die Backups stehen

### Neu in diesem Release

- Versionsmanifest unter `${XDG_STATE_HOME:-~/.local/state}/vhstack/versions`.
  Es hält fest, welche Komponentenversionen installiert sind — nötig, weil
  `install.sh` das `.git` der Klone entfernt und termpp gar nicht geklont wird,
  `git describe` beim Nutzer also ausfällt.
- `update.sh` meldet je Komponente `alt → neu`. Da sich das Skript erst am Ende
  selbst ersetzt, erscheint diese Meldung erstmals beim zweiten Aufruf.
- `uninstall.sh` räumt das Manifest mit ab.

### Hinweis

Vor diesem Tag wurde nicht versioniert.

[1.0.0]: https://github.com/vhstack/vhstack/releases/tag/v1.0.0
