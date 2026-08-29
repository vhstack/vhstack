<p align="right">
  <a href="README.md"><img src="assets/flag-de.png" width="16" height="12" alt="Deutsch" title="Zur deutschen Version wechseln" /></a>  
  <a href="README.en.md"><img src="assets/flag-gb.png" width="16" height="12" alt="English" title="Switch to English" /></a>  
  <a href="README.ru.md"><img src="assets/flag-ru.png" width="16" height="12" alt="Русский" title="Переключиться на русскую версию" /></a>
</p>

<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="assets/title-dark.svg">
    <source media="(prefers-color-scheme: light)" srcset="assets/title-light.svg">
    <img src="assets/title-dark.svg" width="300" height="64" alt="vhstack" />
  </picture>
</p>

# nvimpp, tmuxpp, termpp – твой терминал, твой код, твой стиль

[![Version](https://img.shields.io/github/v/tag/vhstack/vhstack?label=version&sort=semver&color=8b8fd9)](https://github.com/vhstack/vhstack/tags)

[![CI](https://github.com/vhstack/vhstack/actions/workflows/ci.yml/badge.svg)](https://github.com/vhstack/vhstack/actions/workflows/ci.yml)

Привет, я **vhstack** 👋

Добро пожаловать на мой профиль GitHub!  

Здесь ты найдёшь мои тщательно отобранные проекты, которые помогут оптимизировать твой опыт работы в терминале, 
твой код и твой индивидуальный стиль. В отличие от множества отдельных сетапов в интернете, 
эти проекты сознательно согласованы между собой. Они дополняют друг друга как визуально, так и функционально, 
с фокусом на ежедневный рабочий процесс.

## ⚡ Быстрый старт

На чистой системе сначала установите пакеты:

```bash
sudo apt update
sudo apt install tmux neovim unzip ripgrep clangd
```

Затем одна команда устанавливает полную рабочую среду (Prompt, Tmux, Neovim)
на сервере:

```bash
curl -sL https://raw.githubusercontent.com/vhstack/vhstack/main/install.sh | bash
```

![Установка vhstack — одна команда настраивает всё](assets/install.gif)

Что именно делает скрипт, описано в
[руководстве по установке](./INSTALL.ru.md).

Позже одна команда обновляет всё до актуального состояния:

```bash
vhstack-update
```

## 🔧 Мои проекты

### <img src="assets/vhstack.svg" width="20" height="20" style="vertical-align:middle; margin-right: 6px;" /> [nvimpp](https://github.com/vhstack/nvimpp)
**Neovim как C/C++ IDE:**  
clangd, Telescope, Treesitter, Neo-tree и Outline, ленивая загрузка и старт быстрее 100 мс.

### <img src="assets/vhstack.svg" width="20" height="20" style="vertical-align:middle; margin-right: 6px;" /> [tmuxpp](https://github.com/vhstack/tmuxpp)
**tmux, который просто работает:**  
Копирование и вставка мышью прямо в системный буфер обмена, в том числе по SSH через OSC 52. Удобные клавиши, три темы, без менеджера плагинов.

### <img src="assets/vhstack.svg" width="20" height="20" style="vertical-align:middle; margin-right: 6px;" /> [termpp](https://github.com/vhstack/termpp)
**Терминал, Nerd Font и prompt:**  
Windows Terminal с Catppuccin и Cascadia Code NF. Prompt Oh My Posh показывает статус git, ошибки и время выполнения, а True Color работает вплоть до сервера.

## ✨ Обо мне

Я провожу в терминале больше времени, чем в социальных сетях, и за эти годы убедился, что хорошая 
разработка начинается с правильно настроенной среды. С помощью этих проектов я хочу помочь другим 
работать эффективно и с удовольствием в терминале — будь то в оболочке 
или в таких инструментах, как Neovim.

---

*«Код, который мы пишем, — это выражение нас самих. Сделай его таким же уникальным, как и ты.»*

Лицензия MIT · [vhstack.github.io](https://vhstack.github.io)
