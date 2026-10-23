# Omarchy Taiwan Usage (zh-TW)

[繁體中文](README.md) | **English**

Omarchy 4.5 ships its own Traditional Chinese translation. This unofficial project switches the Omarchy interface language to zh-TW and layers **Taiwan-usage overrides** on top of the official translation: it corrects wording that conflicts with the project [glossary](docs/glossary.md) and fills in strings the official catalog has not translated yet.

- It never modifies `/usr/share/omarchy` and does not redistribute Omarchy source code.
- Only the strings that need changing are overridden; everything else comes from the official translation and follows Omarchy updates.
- It resynchronizes automatically after Omarchy updates. If upstream makes an incompatible structural change, it fails explicitly and keeps the last working version.

This project is derived from [QueedWen/omarchy-zh-cn](https://github.com/QueedWen/omarchy-zh-cn) (MIT).

## Quick Start

```bash
git clone https://github.com/Vik1n9/omarchy-zh-tw.git
cd omarchy-zh-tw
./install.sh --dry-run   # see what it will do first
./install.sh
```

Requirements:

- Omarchy `4.5` or later (needs the built-in `default/i18n/zh-TW`); for earlier 4.x, use the [last version that supports 4.0](https://github.com/Vik1n9/omarchy-zh-tw/tree/7e582e5)
- Node.js and jq (provided by the default Omarchy environment)
- A running Omarchy Shell

The installer only switches the Omarchy interface language. To switch the system locale (`LANG`) as well, run `omarchy language zh-TW`. For fonts and the Fcitx 5/Rime input method, see the [Chinese system environment and input method guide](docs/system-setup.md) (Chinese).

## What Gets Overridden

The override catalogs live in [`i18n/zh-TW/`](i18n/zh-TW) and hold three kinds of strings:

| Kind | Examples |
| --- | --- |
| Wording that conflicts with the glossary | QR 碼→QR Code, 通行密碼→密語, 螢幕錄影→螢幕錄製, 夜光→夜燈, 剪貼簿紀錄→剪貼簿歷程記錄, 預先安裝→預安裝軟體, 介面卡→配接器, 重新開機→重新啟動 |
| Strings the official catalog has not translated | About 90 notification-center strings (snooze, Do Not Disturb, display placement, stepping aside for fullscreen), the world clock, the CJK glyph menu, the "move window to monitor" keybindings |
| Deliberate design choices | Brightness levels named after the course of the sun: 日正當中, 豔陽高照 … 夜深人靜 |

Official translations that already match the glossary are not overridden. When Fcitx 5/Rime emoji annotations are present, the emoji picker also gains Traditional Chinese search keywords, and weather uses metric units.

## How It Works

Omarchy translates through three entry points, and each is overridden differently:

- **Menu**: overrides go into the user extension `~/.config/omarchy/extensions/omarchy-menu.jsonc`, which takes precedence over the official translation. The menu expands every extension entry into a whole item, so each override carries the current default icon and action. Items you add or edit yourself are kept.
- **Shell panels**: Omarchy's I18n reads only the system catalogs and has no user override layer. So only the 9 plugins that show an overridden string are cloned (notifications, world clock, indicators, network, Wi-Fi QR code, Bluetooth, clipboard, display, emoji), and their `I18n.t` calls are routed through the override table. When the interface language is not zh-TW, these clones behave exactly like the official plugins.
- **Keybindings panel**: `Super + K` opens a copy of the panel that reads the merged official + override catalog.

The synchronizer, `omarchy-zh-tw-sync`, rebuilds all of this from the Omarchy sources currently installed, and a `post-update` hook runs it after every system update. It warns when an override targets a string that upstream has removed or that no cloned plugin uses.

## Installation Details

The installer will:

1. Check the Omarchy version, its built-in zh-TW translation, and dependencies.
2. Set the interface language to zh-TW (`~/.config/omarchy/language`), recording the previous value for uninstallation.
3. Create the 9 plugin clones with the official `omarchy plugin clone` command, and remove clones left by earlier releases that are no longer needed (the official remover keeps a backup).
4. Install the synchronizer and override catalogs, rebuild the clones, and write the menu and keybindings overrides.
5. Point `Super + K` at the overridden keybindings panel and install the `post-update` hook.

If clones with the same name already exist, the installer stops instead of overwriting your changes. Use the following only after confirming those clones were created by this project:

```bash
./install.sh --adopt-existing
```

### Install with an AI Assistant

If your AI assistant can read local files and run terminal commands, give it this prompt in full:

```text
Please install this Taiwan-usage project on the current Omarchy 4.5 (or later) system:
https://github.com/Vik1n9/omarchy-zh-tw

Requirements:
1. Read README.md and install.sh first, and check that the system, Omarchy version, and dependencies are compatible.
2. Clone the repository into a suitable user directory. If the target directory already exists, do not overwrite it; inspect it first.
3. Run ./install.sh --dry-run first. Run ./install.sh only after the dry run succeeds.
4. Do not modify /usr/share/omarchy, and do not overwrite existing user plugins or personal settings.
5. If you find same-named plugin clones or any other conflict, stop immediately and tell me the details. Do not use --adopt-existing without my explicit confirmation.
6. Ask for my explicit confirmation before any operation that needs a password, elevated privileges, or overwriting files.
7. After installation, run the project tests, check the sync result and Hyprland config errors, and tell me what was changed, the test results, and how to uninstall.
```

## Upgrading from 0.2

Run the new `./install.sh` on Omarchy 4.5. The installer will:

- Remove the plugin clones 0.2 created that are no longer needed (keeping backups).
- Save the full menu dump 0.2 wrote as `omarchy-menu.jsonc.omarchy-zh-tw-0.2-*.bak`, then rewrite the extension so it holds only overrides.
- Remove the localized update flow and the Grok/Kimi Agents extension that 0.2 maintained. Omarchy 4.5 has these built in; Kimi usage now uses `KIMI_API_KEY` or `kimi login`.

## Manual Synchronization

```bash
omarchy-zh-tw-sync [--quiet] [--no-restart] [--adopt-existing]
```

```text
--quiet           Only print output on failure
--no-restart      Do not restart Omarchy Shell after synchronization
--adopt-existing  Adopt existing clones whose source matches
```

## Uninstallation

```bash
./uninstall.sh
```

The uninstaller removes the plugin clones managed by this project and restores the pre-installation menu, interface language, and `Super + K` binding. Both the Omarchy plugin remover and this uninstaller keep timestamped backups.

## Modification Scope

The project writes only to these user paths; `/usr/share/omarchy` always stays read-only:

```text
~/.config/omarchy/language
~/.config/omarchy/plugins/
~/.config/omarchy/extensions/omarchy-menu.jsonc
~/.config/omarchy/hooks/post-update.d/
~/.config/omarchy/shell.json
~/.config/hypr/bindings.lua
~/.local/bin/
~/.local/share/omarchy-zh-tw/
~/.local/state/omarchy-zh-tw/
```

The installer does not collect or upload notification history, network information, location data, tokens, or other user data.

## Known Limitations

- CLI notifications (`omarchy-i18n`) have no user override layer and keep the official translation.
- Plugins that are not cloned use the official translation; overriding their strings means adding the plugin to the clone list.
- After an Omarchy update, the clones keep the previous code until synchronization finishes.

## Preview

These screenshots date from 0.2.0 (Omarchy 4.0). From 4.5 on, most interface text comes from the official translation, so details may differ; wallpapers, themes, and weather data also vary by environment.

| Main menu | Keybindings panel |
| --- | --- |
| ![Main menu](docs/images/menu.webp) | ![Keybindings panel](docs/images/shortcuts.webp) |

| Weather | Calendar | Display |
| --- | --- | --- |
| ![Weather panel](docs/images/weather.webp) | ![Calendar panel](docs/images/calendar.webp) | ![Display panel](docs/images/display.webp) |

## Development and Checks

```bash
./tests/smoke.sh
```

The tests check the override catalogs' format, keys, and placeholders, plus terminology. On an Omarchy machine they also build plugin clones in a temporary `HOME` and run a full install and uninstall cycle without touching real user settings.

### Checking terminology

Translations are decided, in order, by the GNOME/KDE zh-TW community consensus, Microsoft Taiwan, and NAER's computer terminology dictionary, then by this project's own choice or by keeping the original. Look terms up before choosing a translation; do not guess:

```bash
./scripts/build-termbase.sh          # build the term base from each source's official endpoint
./scripts/term-lookup.sh menu        # list each source's translation and provenance, in rank order
./scripts/audit-glossary.sh          # report glossary entries that no source supports
```

The term base is downloaded at run time and is not redistributed in this repository. Translations that none of the four sources cover are recorded in [docs/terms-local.json](docs/terms-local.json), each with its rationale. See [docs/glossary.md](docs/glossary.md) for the full policy and [CONTRIBUTING.md](CONTRIBUTING.md) before contributing.

## Acknowledgements and Disclaimer

- Thanks to [QueedWen](https://github.com/QueedWen) for creating the [omarchy-zh-cn](https://github.com/QueedWen/omarchy-zh-cn) Simplified Chinese localization, from which this project is derived (MIT).
- A tip of the hat to [DHH](https://github.com/dhh) and the Omarchy team for building this beautiful, fun, and agentic Linux distribution, and for shipping it in 50 languages with 4.5.

This is a community project and is not affiliated with the official Omarchy project. The Taiwan-usage adjustments were kick-started by [Vik1n9](https://github.com/Vik1n9); Vik1n9 does not guarantee ongoing maintenance or updates, and anyone is welcome to take over or contribute.

Omarchy and its source code are governed by their upstream licenses. This repository contains only the installation logic, synchronization logic, and override catalogs written for this project, and is licensed under the MIT License.
