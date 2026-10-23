#!/usr/bin/env bash

set -euo pipefail

STATE_DIR="$HOME/.local/state/omarchy-zh-tw"
PLUGIN_ROOT="$HOME/.config/omarchy/plugins"
MENU_FILE="$HOME/.config/omarchy/extensions/omarchy-menu.jsonc"
BINDINGS_FILE="$HOME/.config/hypr/bindings.lua"
SHELL_FILE="$HOME/.config/omarchy/shell.json"
LANGUAGE_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/omarchy/language"
HOOK_FILE="$HOME/.config/omarchy/hooks/post-update.d/omarchy-zh-tw-post-update"
SYNC_TARGET="$HOME/.local/bin/omarchy-zh-tw-sync"
KEYBINDINGS_TARGET="$HOME/.local/bin/omarchy-menu-keybindings-zh-tw"
DATA_DIR="$HOME/.local/share/omarchy-zh-tw"
# 0.2 及更早版本的更新流程，升級後若仍殘留一併清除。
LEGACY_UPDATE_TARGET="$HOME/.local/bin/omarchy-update-zh-tw"
ASSUME_YES=0

while (($# > 0)); do
  case "$1" in
    --yes|-y) ASSUME_YES=1 ;;
    -h|--help) echo "用法：./uninstall.sh [--yes]"; exit 0 ;;
    *) echo "未知引數：$1" >&2; exit 2 ;;
  esac
  shift
done

[[ -f $STATE_DIR/install.version ]] || {
  echo "沒有找到 omarchy-zh-tw 的安裝狀態，停止解除安裝。" >&2
  exit 1
}

if ((!ASSUME_YES)); then
  read -r -p "解除安裝 Omarchy 台灣用語覆蓋，並還原原本的選單與介面語言？[y/N] " answer
  [[ $answer == y || $answer == Y ]] || exit 0
fi

timestamp=$(date -u +%Y%m%d%H%M%S)

# 依清單外再掃一次，連同舊版留下、標記為受管理的複製一併移除。
if [[ -d $PLUGIN_ROOT ]]; then
  while IFS= read -r manifest; do
    [[ $(jq -r '.omarchy.zhTwManaged // false' "$manifest") == true ]] || continue
    omarchy plugin remove "$(basename "$(dirname "$manifest")")" --yes
  done < <(find "$PLUGIN_ROOT" -mindepth 2 -maxdepth 2 -name manifest.json | sort)
fi

if [[ -f $MENU_FILE ]]; then
  cp -a "$MENU_FILE" "$MENU_FILE.omarchy-zh-tw-uninstall-$timestamp.bak"
fi
if [[ -f $STATE_DIR/original/omarchy-menu.jsonc ]]; then
  mkdir -p "$(dirname "$MENU_FILE")"
  cp -a "$STATE_DIR/original/omarchy-menu.jsonc" "$MENU_FILE"
elif [[ -f $STATE_DIR/original/menu-was-absent ]]; then
  rm -f "$MENU_FILE"
fi

if [[ -f $STATE_DIR/original/language ]]; then
  mkdir -p "$(dirname "$LANGUAGE_FILE")"
  cp -a "$STATE_DIR/original/language" "$LANGUAGE_FILE"
elif [[ -f $STATE_DIR/original/language-was-absent ]]; then
  rm -f "$LANGUAGE_FILE"
fi

if [[ -f $BINDINGS_FILE ]] && grep -Fq -- '-- >>> omarchy-zh-tw' "$BINDINGS_FILE"; then
  cp -a "$BINDINGS_FILE" "$BINDINGS_FILE.omarchy-zh-tw-uninstall-$timestamp.bak"
  temporary="$BINDINGS_FILE.zh-new-$$"
  awk '
    $0 == "-- >>> omarchy-zh-tw" { managed = 1; next }
    $0 == "-- <<< omarchy-zh-tw" { managed = 0; next }
    !managed { print }
  ' "$BINDINGS_FILE" >"$temporary"
  mv "$temporary" "$BINDINGS_FILE"
fi

if [[ -f $STATE_DIR/original/shell.json && -f $SHELL_FILE ]]; then
  original_unit=$(jq -r '
    [.bar.layout[][] | select(.id | endswith(".weather")) | (.unit // "__missing__")][0] // "__missing__"
  ' "$STATE_DIR/original/shell.json")
  temporary="$SHELL_FILE.zh-new-$$"
  jq --arg unit "$original_unit" '
    .bar.layout |= with_entries(
      .value |= map(
        if (.id | endswith(".weather")) then
          if $unit == "__missing__" then del(.unit) else .unit = $unit end
        else . end
      )
    )
  ' "$SHELL_FILE" >"$temporary"
  mv "$temporary" "$SHELL_FILE"
fi

if [[ -f $STATE_DIR/original/omarchy-zh-tw-post-update ]]; then
  mkdir -p "$(dirname "$HOOK_FILE")"
  cp -a "$STATE_DIR/original/omarchy-zh-tw-post-update" "$HOOK_FILE"
elif [[ -f $HOOK_FILE ]]; then
  mv "$HOOK_FILE" "$HOOK_FILE.uninstalled-$timestamp.bak"
fi

if [[ -f $STATE_DIR/original/omarchy-zh-tw-sync ]]; then
  cp -a "$STATE_DIR/original/omarchy-zh-tw-sync" "$SYNC_TARGET"
else
  rm -f "$SYNC_TARGET"
fi
if [[ -f $STATE_DIR/original/omarchy-menu-keybindings-zh-tw ]]; then
  cp -a "$STATE_DIR/original/omarchy-menu-keybindings-zh-tw" "$KEYBINDINGS_TARGET"
else
  rm -f "$KEYBINDINGS_TARGET"
fi
if [[ -f $STATE_DIR/original/omarchy-update-zh-tw ]]; then
  cp -a "$STATE_DIR/original/omarchy-update-zh-tw" "$LEGACY_UPDATE_TARGET"
else
  rm -f "$LEGACY_UPDATE_TARGET"
fi
if [[ -d $DATA_DIR ]]; then
  find "$DATA_DIR" -depth -delete
fi

if command -v hyprctl >/dev/null; then hyprctl reload >/dev/null || true; fi
omarchy restart shell >/dev/null || true

archive="$HOME/.local/state/omarchy-zh-tw-uninstalled-$timestamp"
mv "$STATE_DIR" "$archive"
echo "解除安裝完成。外掛和修改過的設定均保留了可還原備份。"
echo "解除安裝狀態備份：$archive"
