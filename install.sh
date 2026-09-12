#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
SYNC_SOURCE="$ROOT_DIR/bin/omarchy-zh-tw-sync"
HOOK_SOURCE="$ROOT_DIR/hooks/omarchy-zh-tw-post-update"
UPDATE_SOURCE="$ROOT_DIR/bin/omarchy-update-zh-tw"
UPDATE_CONFIRM_SOURCE="$ROOT_DIR/bin/omarchy-update-confirm-zh-tw"
SYNC_TARGET="$HOME/.local/bin/omarchy-zh-tw-sync"
KEYBINDINGS_TARGET="$HOME/.local/bin/omarchy-menu-keybindings-zh-tw"
UPDATE_TARGET="$HOME/.local/bin/omarchy-update-zh-tw"
UPDATE_CONFIRM_DIR="$HOME/.local/share/omarchy-zh-tw/bin"
UPDATE_CONFIRM_TARGET="$UPDATE_CONFIRM_DIR/omarchy-update-confirm"
AGENTS_OVERLAY_SOURCE="$ROOT_DIR/agents-overlay"
AGENTS_OVERLAY_TARGET="$HOME/.local/share/omarchy-zh-tw/agents"
HOOK_TARGET="$HOME/.config/omarchy/hooks/post-update.d/omarchy-zh-tw-post-update"
PLUGIN_ROOT="$HOME/.config/omarchy/plugins"
MENU_FILE="$HOME/.config/omarchy/extensions/omarchy-menu.jsonc"
BINDINGS_FILE="$HOME/.config/hypr/bindings.lua"
SHELL_FILE="$HOME/.config/omarchy/shell.json"
STATE_DIR="$HOME/.local/state/omarchy-zh-tw"
BACKUP_DIR="$STATE_DIR/original"
DRY_RUN=0
ADOPT_EXISTING=0

PLUGIN_IDS=(
  omarchy.audio omarchy.bluetooth omarchy.clock omarchy.monitor
  omarchy.network omarchy.power omarchy.weather omarchy.agents
  omarchy.menu omarchy.notifications omarchy.tray omarchy.indicators
  omarchy.system-update omarchy.lock omarchy.polkit omarchy.clipboard
  omarchy.emojis omarchy.image-picker omarchy.reminders omarchy.speedtest
  omarchy.disk-speedtest omarchy.wifiqr
)

usage() {
  cat <<'EOF'
用法：./install.sh [--dry-run] [--adopt-existing]

安裝 Omarchy 4 繁體中文介面。
  --dry-run         只檢查環境並顯示將執行的操作
  --adopt-existing  接管使用者名稱下、來源相符的現有 Omarchy 外掛複製
EOF
}

while (($# > 0)); do
  case "$1" in
    --dry-run) DRY_RUN=1 ;;
    --adopt-existing) ADOPT_EXISTING=1 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "未知引數：$1" >&2; usage >&2; exit 2 ;;
  esac
  shift
done

for command_name in node jq gum omarchy omarchy-plugin-catalog omarchy-shell; do
  command -v "$command_name" >/dev/null || {
    echo "缺少指令：$command_name" >&2
    exit 1
  }
done

version=$(omarchy version 2>/dev/null || true)
[[ $version == 4.* ]] || {
  echo "目前僅支援 Omarchy 4，檢測到：${version:-未知版本}" >&2
  exit 1
}

user_name=${USER:-$(id -un)}
[[ $user_name =~ ^[A-Za-z0-9][A-Za-z0-9._-]*$ ]] || {
  echo "使用者名稱無法安全地用於外掛 ID：$user_name" >&2
  exit 1
}

[[ -f $SYNC_SOURCE && -f $HOOK_SOURCE && -f $UPDATE_SOURCE && -f $UPDATE_CONFIRM_SOURCE && -d $AGENTS_OVERLAY_SOURCE ]] || {
  echo "專案檔案不完整，請從儲存庫根目錄執行安裝器。" >&2
  exit 1
}

echo "Omarchy：$version"
echo "將安裝 ${#PLUGIN_IDS[@]} 個繁體中文外掛複製。"

if ((DRY_RUN)); then
  for source_id in "${PLUGIN_IDS[@]}"; do
    target_id="$user_name.${source_id#omarchy.}"
    if [[ -d $PLUGIN_ROOT/$target_id ]]; then
      echo "檢查現有外掛：$target_id"
    else
      echo "將複製：$source_id -> $target_id"
    fi
  done
  echo "將安裝：$SYNC_TARGET"
  echo "將安裝：$UPDATE_TARGET（繁體中文更新流程）"
  echo "將安裝：$AGENTS_OVERLAY_TARGET（Codex/Grok/Kimi 用量擴充套件與主題圖示）"
  echo "將安裝 post-update 自動同步掛鉤，並把 Super+K 指向繁體中文快捷鍵面板。"
  exit 0
fi

mkdir -p "$HOME/.local/bin" "$UPDATE_CONFIRM_DIR" "$PLUGIN_ROOT" "$BACKUP_DIR"

if [[ ! -e $STATE_DIR/install.version ]]; then
  printf '1\n' >"$STATE_DIR/install.version"
  if [[ -f $MENU_FILE ]]; then
    cp -a "$MENU_FILE" "$BACKUP_DIR/omarchy-menu.jsonc"
  else
    : >"$BACKUP_DIR/menu-was-absent"
  fi
  [[ -f $SHELL_FILE ]] && cp -a "$SHELL_FILE" "$BACKUP_DIR/shell.json"
  [[ -f $SYNC_TARGET ]] && cp -a "$SYNC_TARGET" "$BACKUP_DIR/omarchy-zh-tw-sync"
  [[ -f $KEYBINDINGS_TARGET ]] && cp -a "$KEYBINDINGS_TARGET" "$BACKUP_DIR/omarchy-menu-keybindings-zh-tw"
  [[ -f $HOOK_TARGET ]] && cp -a "$HOOK_TARGET" "$BACKUP_DIR/omarchy-zh-tw-post-update"
fi

backup_once() {
  local current=$1
  local backup=$2
  local absent_marker=$3
  if [[ ! -e $backup && ! -e $absent_marker ]]; then
    if [[ -f $current ]]; then
      cp -a "$current" "$backup"
    else
      : >"$absent_marker"
    fi
  fi
}

backup_once "$UPDATE_TARGET" "$BACKUP_DIR/omarchy-update-zh-tw" "$BACKUP_DIR/omarchy-update-zh-tw-was-absent"
backup_once "$UPDATE_CONFIRM_TARGET" "$BACKUP_DIR/omarchy-update-confirm" "$BACKUP_DIR/omarchy-update-confirm-was-absent"

install -m 755 "$SYNC_SOURCE" "$SYNC_TARGET"
install -m 755 "$UPDATE_SOURCE" "$UPDATE_TARGET"
install -m 755 "$UPDATE_CONFIRM_SOURCE" "$UPDATE_CONFIRM_TARGET"
mkdir -p "$AGENTS_OVERLAY_TARGET/bin" "$AGENTS_OVERLAY_TARGET/assets"
cp -a "$AGENTS_OVERLAY_SOURCE/bin/." "$AGENTS_OVERLAY_TARGET/bin/"
cp -a "$AGENTS_OVERLAY_SOURCE/assets/." "$AGENTS_OVERLAY_TARGET/assets/"
install -m 644 "$AGENTS_OVERLAY_SOURCE/README.md" "$AGENTS_OVERLAY_TARGET/README.md"

mark_managed() {
  local manifest=$1
  local source_id=$2
  local temporary="$manifest.zh-new-$$"
  jq --arg source "$source_id" '
    .omarchy = ((.omarchy // {}) + {clonedFrom: $source, zhTwManaged: true})
  ' "$manifest" >"$temporary"
  mv "$temporary" "$manifest"
}

for source_id in "${PLUGIN_IDS[@]}"; do
  target_id="$user_name.${source_id#omarchy.}"
  target_dir="$PLUGIN_ROOT/$target_id"
  manifest="$target_dir/manifest.json"

  if [[ ! -e $target_dir ]]; then
    omarchy plugin clone "$source_id"
    mark_managed "$manifest" "$source_id"
    continue
  fi

  [[ -f $manifest ]] || {
    echo "現有路徑不是有效外掛，拒絕覆蓋：$target_dir" >&2
    exit 1
  }

  managed=$(jq -r '.omarchy.zhTwManaged // false' "$manifest")
  cloned_from=$(jq -r '.omarchy.clonedFrom // empty' "$manifest")
  if [[ $managed == true ]]; then
    [[ $cloned_from == "$source_id" ]] || {
      echo "受管理外掛的來源不符：$target_id" >&2
      exit 1
    }
  elif ((ADOPT_EXISTING)) && [[ $cloned_from == "$source_id" ]]; then
    mark_managed "$manifest" "$source_id"
  else
    echo "發現非本專案管理的同名外掛：$target_dir" >&2
    echo "如確認它是此前的繁體化複製，請重新執行：./install.sh --adopt-existing" >&2
    exit 1
  fi
done

mkdir -p "$(dirname "$BINDINGS_FILE")"
[[ -f $BINDINGS_FILE ]] || : >"$BINDINGS_FILE"
if ! grep -Fq -- '-- >>> omarchy-zh-tw' "$BINDINGS_FILE" && \
   ! grep -Fq 'omarchy-menu-keybindings-zh-tw' "$BINDINGS_FILE"; then
  cat >>"$BINDINGS_FILE" <<'EOF'

-- >>> omarchy-zh-tw
-- 將 Omarchy 預設的英文快捷鍵面板替換為繁體中文面板。
hl.unbind("SUPER + K")
o.bind("SUPER + K", "快捷鍵", os.getenv("HOME") .. "/.local/bin/omarchy-menu-keybindings-zh-tw")
-- <<< omarchy-zh-tw
EOF
fi

"$SYNC_TARGET" --adopt-existing
omarchy hook install post-update "$HOOK_SOURCE"

if command -v hyprctl >/dev/null; then
  hyprctl reload >/dev/null
  config_errors=$(hyprctl configerrors)
  [[ -z $config_errors ]] || {
    echo "$config_errors" >&2
    exit 1
  }
fi

printf '%s\n' "${PLUGIN_IDS[@]}" >"$STATE_DIR/plugin-sources"
echo "安裝完成。按 Super+K 可開啟繁體中文快捷鍵面板；系統更新流程也已繁體中文化。"
