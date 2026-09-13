#!/usr/bin/env bash

set -euo pipefail

STATE_DIR="$HOME/.local/state/omarchy-zh-tw"
PLUGIN_ROOT="$HOME/.config/omarchy/plugins"
MENU_FILE="$HOME/.config/omarchy/extensions/omarchy-menu.jsonc"
BINDINGS_FILE="$HOME/.config/hypr/bindings.lua"
SHELL_FILE="$HOME/.config/omarchy/shell.json"
HOOK_FILE="$HOME/.config/omarchy/hooks/post-update.d/omarchy-zh-tw-post-update"
SYNC_TARGET="$HOME/.local/bin/omarchy-zh-tw-sync"
KEYBINDINGS_TARGET="$HOME/.local/bin/omarchy-menu-keybindings-zh-tw"
UPDATE_TARGET="$HOME/.local/bin/omarchy-update-zh-tw"
UPDATE_CONFIRM_DIR="$HOME/.local/share/omarchy-zh-tw/bin"
UPDATE_CONFIRM_TARGET="$UPDATE_CONFIRM_DIR/omarchy-update-confirm"
AGENTS_OVERLAY_TARGET="$HOME/.local/share/omarchy-zh-tw/agents"
UPDATE_HELPERS=(
  omarchy-update omarchy-update-pkg-prune omarchy-update-lock
  omarchy-update-requires-free-space omarchy-snapshot omarchy-update-keyring
  omarchy-pkg-add
  omarchy-update-system-pkgs
  omarchy-update-system-pkgs-when-conflicted omarchy-migrate
  omarchy-update-aur-pkgs omarchy-update-mise omarchy-update-orphan-pkgs
  omarchy-update-restart omarchy-update-dev omarchy-update-stay-awake
  omarchy-update-analyze-logs omarchy-hook omarchy-system-reboot
  omarchy-restart-shell
)
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
  read -r -p "解除安裝 Omarchy 繁體中文介面並還原原選單？[y/N] " answer
  [[ $answer == y || $answer == Y ]] || exit 0
fi

timestamp=$(date -u +%Y%m%d%H%M%S)
user_name=${USER:-$(id -un)}

if [[ -f $STATE_DIR/plugin-sources ]]; then
  mapfile -t plugin_sources <"$STATE_DIR/plugin-sources"
else
  plugin_sources=()
fi

for source_id in "${plugin_sources[@]}"; do
  [[ -n $source_id ]] || continue
  target_id="$user_name.${source_id#omarchy.}"
  manifest="$PLUGIN_ROOT/$target_id/manifest.json"
  if [[ -f $manifest ]] && [[ $(jq -r '.omarchy.zhTwManaged // false' "$manifest") == true ]]; then
    omarchy plugin remove "$target_id" --yes
  fi
done

if [[ -f $MENU_FILE ]]; then
  cp -a "$MENU_FILE" "$MENU_FILE.omarchy-zh-tw-uninstall-$timestamp.bak"
fi
if [[ -f $STATE_DIR/original/omarchy-menu.jsonc ]]; then
  mkdir -p "$(dirname "$MENU_FILE")"
  cp -a "$STATE_DIR/original/omarchy-menu.jsonc" "$MENU_FILE"
elif [[ -f $STATE_DIR/original/menu-was-absent ]]; then
  rm -f "$MENU_FILE"
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
  cp -a "$STATE_DIR/original/omarchy-update-zh-tw" "$UPDATE_TARGET"
else
  rm -f "$UPDATE_TARGET"
fi
for helper in "${UPDATE_HELPERS[@]}"; do
  rm -f "$UPDATE_CONFIRM_DIR/$helper"
done
if [[ -f $STATE_DIR/original/omarchy-update-confirm ]]; then
  mkdir -p "$UPDATE_CONFIRM_DIR"
  cp -a "$STATE_DIR/original/omarchy-update-confirm" "$UPDATE_CONFIRM_TARGET"
else
  rm -f "$UPDATE_CONFIRM_TARGET"
fi
if [[ -d $AGENTS_OVERLAY_TARGET ]]; then
  find "$AGENTS_OVERLAY_TARGET" -depth -delete
fi
rmdir "$UPDATE_CONFIRM_DIR" "$HOME/.local/share/omarchy-zh-tw" 2>/dev/null || true

if command -v hyprctl >/dev/null; then hyprctl reload >/dev/null || true; fi
omarchy restart shell >/dev/null || true

archive="$HOME/.local/state/omarchy-zh-tw-uninstalled-$timestamp"
mv "$STATE_DIR" "$archive"
echo "解除安裝完成。外掛和修改過的設定均保留了可還原備份。"
echo "解除安裝狀態備份：$archive"
