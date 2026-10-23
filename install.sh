#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
SYNC_SOURCE="$ROOT_DIR/bin/omarchy-zh-tw-sync"
HOOK_SOURCE="$ROOT_DIR/hooks/omarchy-zh-tw-post-update"
I18N_SOURCE="$ROOT_DIR/i18n/zh-TW"
SYNC_TARGET="$HOME/.local/bin/omarchy-zh-tw-sync"
KEYBINDINGS_TARGET="$HOME/.local/bin/omarchy-menu-keybindings-zh-tw"
DATA_DIR="$HOME/.local/share/omarchy-zh-tw"
I18N_TARGET="$DATA_DIR/i18n/zh-TW"
HOOK_TARGET="$HOME/.config/omarchy/hooks/post-update.d/omarchy-zh-tw-post-update"
PLUGIN_ROOT="$HOME/.config/omarchy/plugins"
MENU_FILE="$HOME/.config/omarchy/extensions/omarchy-menu.jsonc"
BINDINGS_FILE="$HOME/.config/hypr/bindings.lua"
SHELL_FILE="$HOME/.config/omarchy/shell.json"
LANGUAGE_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/omarchy/language"
OMARCHY_I18N="${OMARCHY_PATH:-/usr/share/omarchy}/default/i18n"
STATE_DIR="$HOME/.local/state/omarchy-zh-tw"
BACKUP_DIR="$STATE_DIR/original"
DRY_RUN=0
ADOPT_EXISTING=0

PLUGIN_IDS=(
  omarchy.notifications omarchy.elsewhen omarchy.indicators
  omarchy.network omarchy.wifiqr omarchy.bluetooth
  omarchy.clipboard omarchy.monitor omarchy.emojis
)

# 0.2 及更早版本自行產生的更新流程與 Agents 擴充；4.5 起由 Omarchy 內建取代。
LEGACY_FILES=(
  "$HOME/.local/bin/omarchy-update-zh-tw"
  "$DATA_DIR/bin"
  "$DATA_DIR/agents"
)

usage() {
  cat <<'EOF'
用法：./install.sh [--dry-run] [--adopt-existing]

在 Omarchy 4.5 內建的繁體中文上，安裝台灣用語覆蓋。
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

for command_name in node jq omarchy omarchy-plugin-catalog omarchy-shell; do
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
[[ -f $OMARCHY_I18N/zh-TW/shell.json && -f $OMARCHY_I18N/zh-TW/menu.json ]] || {
  echo "這個 Omarchy 沒有內建繁體中文翻譯（檢測到 $version）。本版需要 Omarchy 4.5 以上；" >&2
  echo "更早的 4.x 請改用支援 4.0 的最後一個版本：git checkout 7e582e5" >&2
  exit 1
}

user_name=${USER:-$(id -un)}
[[ $user_name =~ ^[A-Za-z0-9][A-Za-z0-9._-]*$ ]] || {
  echo "使用者名稱無法安全地用於外掛 ID：$user_name" >&2
  exit 1
}

[[ -f $SYNC_SOURCE && -f $HOOK_SOURCE && -f $I18N_SOURCE/shell.json ]] || {
  echo "專案檔案不完整，請從儲存庫根目錄執行安裝器。" >&2
  exit 1
}

current_language=$(head -n 1 "$LANGUAGE_FILE" 2>/dev/null | tr -d '[:space:]' || true)

echo "Omarchy：$version"
echo "將安裝 ${#PLUGIN_IDS[@]} 個台灣用語外掛複製。"

if ((DRY_RUN)); then
  if [[ $current_language != zh-TW ]]; then
    echo "將把 Omarchy 介面語言從 ${current_language:-en} 設為 zh-TW（$LANGUAGE_FILE）。"
  fi
  for source_id in "${PLUGIN_IDS[@]}"; do
    target_id="$user_name.${source_id#omarchy.}"
    if [[ -d $PLUGIN_ROOT/$target_id ]]; then
      echo "檢查現有外掛：$target_id"
    else
      echo "將複製：$source_id -> $target_id"
    fi
  done
  if [[ -d $PLUGIN_ROOT ]]; then
    while IFS= read -r manifest; do
      [[ $(jq -r '.omarchy.zhTwManaged // false' "$manifest") == true ]] || continue
      cloned_from=$(jq -r '.omarchy.clonedFrom // empty' "$manifest")
      [[ " ${PLUGIN_IDS[*]} " == *" $cloned_from "* ]] && continue
      echo "將移除舊版留下的複製並還原官方外掛：$(basename "$(dirname "$manifest")")"
    done < <(find "$PLUGIN_ROOT" -mindepth 2 -maxdepth 2 -name manifest.json | sort)
  fi
  for legacy in "${LEGACY_FILES[@]}"; do
    [[ -e $legacy ]] && echo "將移除舊版檔案：$legacy"
  done
  echo "將安裝：$SYNC_TARGET 與覆蓋詞庫 $I18N_TARGET"
  echo "將安裝 post-update 自動同步勾點，並把 Super+K 指向台灣用語快捷鍵面板。"
  exit 0
fi

mkdir -p "$HOME/.local/bin" "$PLUGIN_ROOT" "$BACKUP_DIR"

if [[ ! -e $STATE_DIR/install.version ]]; then
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
printf '2\n' >"$STATE_DIR/install.version"

# 介面語言是使用者自己的選擇；只在第一次切換時記下原值，供解除安裝還原。
if [[ ! -e $BACKUP_DIR/language && ! -e $BACKUP_DIR/language-was-absent ]]; then
  if [[ -f $LANGUAGE_FILE ]]; then
    cp -a "$LANGUAGE_FILE" "$BACKUP_DIR/language"
  else
    : >"$BACKUP_DIR/language-was-absent"
  fi
fi
if [[ $current_language != zh-TW ]]; then
  mkdir -p "$(dirname "$LANGUAGE_FILE")"
  printf 'zh-TW\n' >"$LANGUAGE_FILE"
fi

for legacy in "${LEGACY_FILES[@]}"; do
  [[ -e $legacy ]] && rm -rf -- "$legacy"
done

install -m 755 "$SYNC_SOURCE" "$SYNC_TARGET"
mkdir -p "$I18N_TARGET"
install -m 644 "$I18N_SOURCE"/*.json "$I18N_TARGET/"

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
-- 將 Omarchy 預設的快捷鍵面板替換為套用台灣用語覆蓋的面板。
hl.unbind("SUPER + K")
o.bind("SUPER + K", "快捷鍵", os.getenv("HOME") .. "/.local/bin/omarchy-menu-keybindings-zh-tw")
-- <<< omarchy-zh-tw
EOF
fi

# 同步器會移除不在清單內的舊複製，並重建清單內的複製。
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
echo "安裝完成。Omarchy 介面語言已設為 zh-TW，並套用台灣用語覆蓋；按 Super+K 可開啟快捷鍵面板。"
echo "如需同時切換系統地區設定（LANG），請執行：omarchy language zh-TW"
