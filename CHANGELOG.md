# Changelog

Dieses Projekt folgt [Semantic Versioning](https://semver.org/lang/de/).

Für eine Konfigurationssammlung gilt:

- **major** — Update braucht Handarbeit (Pfade, Keybindings, Breaking Change)
- **minor** — neue Funktionen, abwärtskompatibel
- **patch** — Fehlerbehebungen, Feinschliff

## [1.0.2] — 2026-09-04

Wartungsrelease ohne funktionale Änderung an Installation oder Update.

### Komponenten zum Zeitpunkt des Release

| Komponente | Version |
| ---------- | ------- |
| nvimpp     | v1.5.3  |
| tmuxpp     | v1.3.1  |
| termpp     | v1.4.0  |

### Geändert

- `install.sh`: Leerzeile nach der Abschlussübersicht und nach einer
  Fehlermeldung, damit der Prompt nicht direkt an der Ausgabe klebt
- Dokumentation: neues vhstack-Logo als SVG mit Titelgrafik für hellen und
  dunklen Modus (`assets/title-*.svg`), Generator `assets/gen_vhstack_logo.py`;
  Projektkarten der drei Komponenten neu formuliert, einheitlicher Footer,
  Badge-Farben angepasst — in allen drei README-Sprachen
- `LICENSE` (MIT) ergänzt
- `assets/record.sh`: Demo-Aufnahmen nutzen `vhstack-update` und die
  Demo-App stacktop statt orbit (`VHS_APP_DIR`, `VHS_VLIB_DIR`)

## [1.0.1] — 2026-08-25

- Update-Befehl von `update-vhstack` in `vhstack-update` umbenannt
  (Projektname als Präfix, bessere Tab-Vervollständigung). `install.sh`
  entfernt den alten Befehl automatisch, `uninstall.sh` räumt beide Namen ab.

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
  die Shell-Startdateien anzufassen; wird als `update-vhstack` mitinstalliert (seit 1.0.1: `vhstack-update`)
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

[1.0.2]: https://github.com/vhstack/vhstack/releases/tag/v1.0.2
[1.0.1]: https://github.com/vhstack/vhstack/releases/tag/v1.0.1
[1.0.0]: https://github.com/vhstack/vhstack/releases/tag/v1.0.0
