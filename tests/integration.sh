#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)

if [[ ! -d /usr/share/omarchy/shell || ! -x /usr/share/omarchy/bin/omarchy-menu-keybindings ]]; then
  echo "非 Omarchy 環境，跳過整合檢查。"
  exit 0
fi

sandbox_home=$(mktemp -d)
cleanup() {
  [[ -n ${sandbox_home:-} && -d $sandbox_home && $sandbox_home == /tmp/* ]] && rm -rf -- "$sandbox_home"
}
trap cleanup EXIT

mkdir -p "$sandbox_home/.local/share/fcitx5/rime/opencc"
printf '笑臉\t笑臉 😀\n汽車\t汽車 🚗\n' \
  >"$sandbox_home/.local/share/fcitx5/rime/opencc/emoji.txt"

HOME="$sandbox_home" USER=testuser \
  "$ROOT_DIR/bin/omarchy-zh-tw-sync" --quiet --no-restart

plugin_root="$sandbox_home/.config/omarchy/plugins"
plugin_count=$(find "$plugin_root" -mindepth 2 -maxdepth 2 -name manifest.json | wc -l)
[[ $plugin_count -eq 22 ]] || {
  echo "產生的外掛數量不正確：$plugin_count" >&2
  exit 1
}

while IFS= read -r manifest; do
  jq -e '.omarchy.zhTwManaged == true and (.omarchy.clonedFrom | startswith("omarchy."))' \
    "$manifest" >/dev/null
done < <(find "$plugin_root" -mindepth 2 -maxdepth 2 -name manifest.json | sort)

menu_file="$sandbox_home/.config/omarchy/extensions/omarchy-menu.jsonc"
node - "$menu_file" "$sandbox_home" <<'NODE'
const fs = require("fs")
const [menuPath, home] = process.argv.slice(2)
const raw = fs.readFileSync(menuPath, "utf8")
  .replace(/^\s*\/\/[^\n]*(\n|$)/gm, "")
  .replace(/,(\s*[}\]])/g, "$1")
const menu = JSON.parse(raw)
if (Object.keys(menu).length < 318) throw new Error("選單項目數量不足")
for (const [id, label] of Object.entries({
  apps: "應用程式",
  setup: "設定",
  install: "安裝",
  remove: "移除",
  system: "系統"
})) {
  if (menu[id].label !== label) throw new Error(`${id} 選單未繁體化`)
}
if (menu["learn.keybindings"].label !== "快捷鍵") throw new Error("快捷鍵選單未繁體化")
if (menu["learn.keybindings"].action !== home + "/.local/bin/omarchy-menu-keybindings-zh-tw") {
  throw new Error("快捷鍵入口路徑不正確")
}
if (menu["update.omarchy"].action !== "omarchy-launch-floating-terminal-with-presentation " + home + "/.local/bin/omarchy-update-zh-tw") {
  throw new Error("系統更新入口路徑不正確")
}
NODE

rg -Fq '"scrolling": "捲動版面配置"' \
  "$plugin_root/testuser.notifications/components/NotificationLocalization.js"
rg -Fq 'Qt.locale("zh_TW")' "$plugin_root/testuser.weather/Panel.qml"
rg -Fq '"power-saver": "節能", "balanced": "平衡", "performance": "效能"' \
  "$plugin_root/testuser.power/Panel.qml"
rg -Fq 'text: rowRoot.isPinned ? "取消釘選" : "釘選"' "$plugin_root/testuser.tray/Tray.qml"
rg -Fq 'text: rowRoot.isHidden ? "顯示" : "隱藏"' "$plugin_root/testuser.tray/Tray.qml"
rg -Fq '搜尋剪貼簿…' "$plugin_root/testuser.clipboard/Clipboard.qml"
rg -Fq 'cancelText: "取消"' "$plugin_root/testuser.clipboard/Clipboard.qml"
rg -Fq ' 個檔案' "$plugin_root/testuser.clipboard/ClipboardHistory.js"
rg -Fq '，時間：' "$plugin_root/testuser.clipboard/ClipboardHistory.js"
rg -Fq '搜尋表情…' "$plugin_root/testuser.emojis/Emojis.qml"
node - "$plugin_root/testuser.emojis/emojis.json" <<'NODE'
const items = require(process.argv[2])
const byEmoji = new Map(items.map(item => [item.e, item.k]))
if (!byEmoji.get("😀")?.includes("笑臉")) throw new Error("笑臉繁體中文關鍵字缺失")
if (!byEmoji.get("🚗")?.includes("汽車")) throw new Error("汽車繁體中文關鍵字缺失")
if (!byEmoji.get("🧑")?.includes("人物")) throw new Error("人物兜底關鍵字缺失")
if (!byEmoji.get("🚊")?.includes("有軌電車")) throw new Error("交通工具兜底關鍵字缺失")
NODE
rg -Fq '關閉無線網路' "$plugin_root/testuser.network/Panel.qml"
rg -Fq '隱藏網路' "$plugin_root/testuser.network/Panel.qml"
rg -Fq 'return "自動"' "$plugin_root/testuser.network/Model.js"
rg -Fq '正在連線…' "$plugin_root/testuser.network/Panel.qml"
rg -Fq '正在掃描裝置…' "$plugin_root/testuser.bluetooth/Panel.qml"
rg -Fq '|| "裝置"' "$plugin_root/testuser.bluetooth/Panel.qml"
rg -Fq '正在驗證…' "$plugin_root/testuser.lock/LockView.qml"
rg -Fq "$plugin_root/testuser.agents/bin/usage-update" "$plugin_root/testuser.agents/Main.qml"
jq -e '.barWidget.defaults.providers.grok.enabled == true and .barWidget.defaults.providers.kimi.enabled == true' \
  "$plugin_root/testuser.agents/manifest.json" >/dev/null
for collector in codex codex-collector grok-collector kimi-collector usage-update; do
  test -x "$plugin_root/testuser.agents/bin/$collector"
done
test -f "$plugin_root/testuser.agents/assets/grok.svg"
test -f "$plugin_root/testuser.agents/assets/grok-light.svg"
test -f "$plugin_root/testuser.agents/assets/kimi.svg"
test -f "$plugin_root/testuser.agents/assets/kimi-light.svg"
rg -Fq ' · 目前' "$plugin_root/testuser.monitor/Panel.qml"
rg -Fq 'return "烈日當空"' "$plugin_root/testuser.monitor/Model.js"
rg -Fq 'return "夜深人靜"' "$plugin_root/testuser.monitor/Model.js"
for speed_plugin in speedtest disk-speedtest; do
  rg -Fq 'text: "再次測試"' "$plugin_root/testuser.$speed_plugin/SpeedTestOverlay.qml"
done
rg -Fq '無法取得測速節點' "$plugin_root/testuser.speedtest/Panel.qml"
rg -Fq '測速未完成' "$plugin_root/testuser.disk-speedtest/Panel.qml"
rg -Fq 'function localizedCommandError' "$plugin_root/testuser.wifiqr/Panel.qml"
rg -Fq '沒有正在使用的無線網路連線' "$plugin_root/testuser.wifiqr/Panel.qml"
rg -Fq '拒絕使用不安全的顯示器名稱' \
  "$plugin_root/testuser.notifications/components/NotificationLocalization.js"
rg -Fq '設定指紋辨識器' \
  "$plugin_root/testuser.notifications/components/NotificationLocalization.js"
rg -Fq '你的新主題是 ' \
  "$plugin_root/testuser.notifications/components/NotificationLocalization.js"
rg -Fq '未找到 " + match[1] + " 在工作區 "' \
  "$plugin_root/testuser.notifications/components/NotificationLocalization.js"
rg -Fq "$sandbox_home/.local/bin/omarchy-update-zh-tw" \
  "$plugin_root/testuser.system-update/SystemUpdate.qml"
test -x "$sandbox_home/.local/bin/omarchy-menu-keybindings-zh-tw"
bash -n "$sandbox_home/.local/bin/omarchy-menu-keybindings-zh-tw"

update_helpers=(
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
for helper in "${update_helpers[@]}"; do
  test -x "$sandbox_home/.local/share/omarchy-zh-tw/bin/$helper"
  bash -n "$sandbox_home/.local/share/omarchy-zh-tw/bin/$helper"
done
rg -Fq '更新過程中出現錯誤！' "$sandbox_home/.local/share/omarchy-zh-tw/bin/omarchy-update"
rg -Fq '建立系統快照' "$sandbox_home/.local/share/omarchy-zh-tw/bin/omarchy-snapshot"
rg -Fq '清理套件快取' "$sandbox_home/.local/share/omarchy-zh-tw/bin/omarchy-update-pkg-prune"
rg -Fq '更新 Arch 簽章金鑰' "$sandbox_home/.local/share/omarchy-zh-tw/bin/omarchy-update-keyring"
rg -Fq '錯誤：套件「' "$sandbox_home/.local/share/omarchy-zh-tw/bin/omarchy-pkg-add"
rg -Fq 'echo -e "\e[32m\n更新系統套件\e[0m"' \
  "$sandbox_home/.local/share/omarchy-zh-tw/bin/omarchy-update-system-pkgs"
rg -Fq 'echo -e "\e[32m\n更新 AUR 套件\e[0m"' \
  "$sandbox_home/.local/share/omarchy-zh-tw/bin/omarchy-update-aur-pkgs"
rg -Fq '正在執行遷移' "$sandbox_home/.local/share/omarchy-zh-tw/bin/omarchy-migrate"
rg -Fq '更新 mise 管理的工具' "$sandbox_home/.local/share/omarchy-zh-tw/bin/omarchy-update-mise"
rg -Fq '重新啟動前請檢查日誌' "$sandbox_home/.local/share/omarchy-zh-tw/bin/omarchy-update-analyze-logs"
rg -Fq '掛鉤執行失敗：' "$sandbox_home/.local/share/omarchy-zh-tw/bin/omarchy-hook"
rg -Fq '正在重新啟動' "$sandbox_home/.local/share/omarchy-zh-tw/bin/omarchy-system-reboot"
rg -Fq 'Omarchy Shell 重新啟動後未能就緒' "$sandbox_home/.local/share/omarchy-zh-tw/bin/omarchy-restart-shell"
rg -Fq -- '--affirmative "是" --negative "否" --no-show-help' \
  "$sandbox_home/.local/share/omarchy-zh-tw/bin/omarchy-update-restart"
! rg -Fq 'Omarchy update in progress' \
  "$sandbox_home/.local/share/omarchy-zh-tw/bin/omarchy-update-stay-awake"

if rg -n '/home/[[:alnum:]_.-]+|/Users/[[:alnum:]_.-]+' "$sandbox_home"; then
  echo "產生結果包含開發機器資訊。" >&2
  exit 1
fi

echo "Omarchy 隔離整合檢查透過。"
