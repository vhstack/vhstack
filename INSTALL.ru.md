<p align="right">
  <a href="INSTALL.md"><img src="assets/flag-de.png" width="16" height="12" alt="Deutsch" title="Zur deutschen Version wechseln" /></a>  
  <a href="INSTALL.en.md"><img src="assets/flag-gb.png" width="16" height="12" alt="English" title="Switch to English" /></a>  
  <a href="INSTALL.ru.md"><img src="assets/flag-ru.png" width="16" height="12" alt="Русский" title="Переключиться на русскую версию" /></a>
</p>

# Установка vhstack

Скрипт [`install.sh`](./install.sh) настраивает всю рабочую среду vhstack —
**Oh My Posh Prompt** ([`vhstack/termpp`](https://github.com/vhstack/termpp)),
**Tmux** ([`vhstack/tmuxpp`](https://github.com/vhstack/tmuxpp)) и **Neovim**
([`vhstack/nvimpp`](https://github.com/vhstack/nvimpp)) — за один шаг:

```bash
curl -sL https://raw.githubusercontent.com/vhstack/vhstack/main/install.sh | bash
```

Скрипт автоматически выполняет:

- **Резервное копирование** существующих конфигураций в
  `~/.vhstack-backup-<метка времени>` (`~/.tmux*`, `~/.config/nvim`, данные
  плагинов Neovim, тема Prompt, а также копия `~/.bashrc`/`~/.zshrc`)
- Установку **Oh My Posh** с темой `vhstack.omp.json` и строкой
  инициализации в `~/.bashrc` или `~/.zshrc`
- **Конфигурацию Tmux**
- Только в WSL: **win32yank.exe** для быстрого буфера обмена
  ([подробности в tmuxpp](https://github.com/vhstack/tmuxpp/blob/main/README.ru.md#win32yankexe-в-wsl))
- **Конфигурацию Neovim**, включая синхронизацию плагинов (headless)
- **Скрипт xssh** в `~/.local/bin` (X11 через Xephyr,
  [подробности в termpp](https://github.com/vhstack/termpp))
- **Команду vhstack-update** в `~/.local/bin` для последующих обновлений

**Обновление позже:** Существующую установку обновляет команда
`vhstack-update` (или [`update.sh`](./update.sh)) — тема, конфигурации Tmux
и Neovim вместе с плагинами Neovim, не затрагивая `~/.bashrc`/`~/.zshrc`.
Заменяемые конфигурации предварительно сохраняются в
`~/.vhstack-backup-update-<метка времени>`:

```bash
vhstack-update   # или:
curl -sL https://raw.githubusercontent.com/vhstack/vhstack/main/update.sh | bash
```

![Обновление vhstack — отчёт «было → стало»](assets/update.gif)

Требования: `git` и `curl`; также должны быть установлены `tmux` и `nvim`:

```bash
sudo apt update
sudo apt install tmux neovim unzip ripgrep clangd   # Debian/Ubuntu
brew install tmux neovim ripgrep llvm               # macOS
```

> **Совет:** После установки запустите новую оболочку (или `source ~/.bashrc`) и
> откройте `tmux` и `nvim` по одному разу. При необходимости выполните в
> Neovim `:MasonInstall clangd cmake-language-server` для C/C++ LSP.

## Устанавливаемые пути

| Компонент | Пути |
| --- | --- |
| Prompt | `~/.config/ohmyposh/vhstack.omp.json`, строки инициализации в `~/.bashrc`/`~/.zshrc`, при необходимости `~/.local/bin/oh-my-posh` |
| Tmux | `~/.tmux/`, символьная ссылка `~/.tmux.conf` |
| Буфер обмена (только WSL) | `%LOCALAPPDATA%\win32yank`, символьная ссылка в PATH, `~/.cache/tmuxpp/` |
| Neovim | `~/.config/nvim/`, данные плагинов в `~/.local/share/nvim`, `~/.local/state/nvim`, `~/.cache/nvim` |
| Инструменты | `~/.local/bin/xssh`, `~/.local/bin/vhstack-update` |

`install.sh` идемпотентен: повторный запуск обновляет установку, а всё существующее предварительно переносится в новый каталог резервных копий.

## Удаление

Одна команда удаляет все перечисленные выше компоненты ([`uninstall.sh`](./uninstall.sh)):

```bash
curl -sL https://raw.githubusercontent.com/vhstack/vhstack/main/uninstall.sh | bash
```

Скрипт сначала показывает, что он нашёл, и запрашивает подтверждение (без запроса: `... | bash -s -- --yes`). Каталоги резервных копий `~/.vhstack-backup-*` остаются на месте — в них хранится состояние до установки, и его можно вернуть вручную:

```bash
cp -a ~/.vhstack-backup-<метка времени>/.tmux ~/
```

Сама программа `oh-my-posh` остаётся установленной (`~/.local/bin/oh-my-posh`) — при необходимости удалите её вручную.
