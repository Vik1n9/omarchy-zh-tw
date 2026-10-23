#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)

if [[ ! -d /usr/share/omarchy/shell || ! -f /usr/share/omarchy/default/i18n/zh-TW/shell.json ]]; then
  echo "非 Omarchy 4.5 以上環境，跳過整合檢查。"
  exit 0
fi

sandbox_home=$(mktemp -d)
# 測試只能寫沙箱；XDG_CONFIG_HOME 若指向真實目錄，語言檔會寫到使用者的設定裡。
export XDG_CONFIG_HOME="$sandbox_home/.config"
cleanup() {
  [[ -n ${sandbox_home:-} && -d $sandbox_home && $sandbox_home == /tmp/* ]] && rm -rf -- "$sandbox_home"
}
trap cleanup EXIT

mkdir -p "$sandbox_home/.local/share/fcitx5/rime/opencc"
printf '笑臉\t笑臉 😀\n汽車\t汽車 🚗\n' \
  >"$sandbox_home/.local/share/fcitx5/rime/opencc/emoji.txt"

plugin_root="$sandbox_home/.config/omarchy/plugins"
plugins=(notifications elsewhen indicators network wifiqr bluetooth clipboard monitor emojis)
# 安裝器以 `omarchy plugin clone` 建立這些複製；這裡只放受管理的清單，讓同步器重建內容。
for plugin in "${plugins[@]}"; do
  mkdir -p "$plugin_root/testuser.$plugin"
  jq -n --arg id "testuser.$plugin" --arg source "omarchy.$plugin" \
    '{id: $id, omarchy: {clonedFrom: $source, zhTwManaged: true}}' \
    >"$plugin_root/testuser.$plugin/manifest.json"
done

# 0.2 留下的整份選單傾印，必須被換成只含覆蓋的擴充檔。
mkdir -p "$sandbox_home/.config/omarchy/extensions"
printf '%s\n%s\n' '// Omarchy 4 繁體中文選單：動作來自目前系統版本，文字由本地繁體化流程保留。' \
  '{"update.omarchy": {"label": "更新", "action": "old-update-zh-tw"}}' \
  >"$sandbox_home/.config/omarchy/extensions/omarchy-menu.jsonc"

output=$(HOME="$sandbox_home" USER=testuser \
  "$ROOT_DIR/bin/omarchy-zh-tw-sync" --no-restart 2>&1)
if grep -F '注意：' <<<"$output"; then
  echo "同步器回報警告，覆蓋詞庫與目前的 Omarchy 不一致。" >&2
  exit 1
fi

for plugin in "${plugins[@]}"; do
  dir="$plugin_root/testuser.$plugin"
  jq -e --arg source "omarchy.$plugin" \
    '.omarchy.zhTwManaged == true and .omarchy.clonedFrom == $source' "$dir/manifest.json" >/dev/null
  test -f "$dir/ZhTwI18n.js"
  rg -q 'ZhTwI18n\.(t|tn|bindT|bindTn)\(' "$dir" -g '*.qml'
  if rg -n '(^|[^\w.$])(Commons\.)?I18n\.tn?\b' "$dir" -g '*.qml' | rg -v '^\S+:\d+:\s*//'; then
    echo "testuser.$plugin 仍有未接到覆蓋表的 I18n 呼叫。" >&2
    exit 1
  fi
done

# 每個改寫過的 QML 都要匯入覆蓋表，且相對路徑指向外掛根目錄。
while IFS= read -r file; do
  import=$(rg -o 'import "([^"]+ZhTwI18n\.js)" as ZhTwI18n' -r '$1' "$file") || {
    echo "缺少覆蓋表匯入：$file" >&2
    exit 1
  }
  test -f "$(dirname "$file")/$import"
done < <(rg -l 'ZhTwI18n\.' "$plugin_root" -g '*.qml')

node - "$plugin_root/testuser.network/ZhTwI18n.js" <<'NODE'
const fs = require("fs")
const vm = require("vm")
const source = fs.readFileSync(process.argv[2], "utf8").replace(/^\.pragma library\n/, "")
const sandbox = {}
vm.runInNewContext(source, sandbox)
const official = { language: "zh-TW", t: (key, fallback) => `官方:${key}`, tn: (key, count) => `官方:${key}:${count}` }
const english = { ...official, language: "en" }
const check = (actual, expected) => { if (actual !== expected) throw new Error(`覆蓋表結果 ${actual}，預期 ${expected}`) }
check(sandbox.t(official, "network.passphrase"), "密語")
check(sandbox.t(official, "network.ssid"), "官方:network.ssid")
check(sandbox.t(english, "network.passphrase"), "官方:network.passphrase")
check(sandbox.tn(official, "notifications.hours", 3), "%1 小時")
check(sandbox.bindT(official)("monitor.level.nightOwl", "Night owl"), "夜深人靜")
NODE

menu_file="$sandbox_home/.config/omarchy/extensions/omarchy-menu.jsonc"
node - "$menu_file" "$sandbox_home" <<'NODE'
const fs = require("fs")
const [menuPath, home] = process.argv.slice(2)
const raw = fs.readFileSync(menuPath, "utf8")
if (!raw.startsWith("// omarchy-zh-tw：")) throw new Error("選單擴充檔缺少標頭")
const menu = JSON.parse(raw.replace(/^\s*\/\/[^\n]*(\n|$)/gm, ""))
if (menu["update.omarchy"]) throw new Error("0.2 的選單傾印未清除")
if (menu["system.reboot"]?.label !== "重新啟動") throw new Error("重新啟動覆蓋缺失")
if (!menu["system.reboot"].searchTerms.includes("Reboot")) throw new Error("英文標籤未保留為搜尋詞")
if (menu["trigger.capture.qr"]?.label !== "QR Code") throw new Error("QR Code 覆蓋缺失")
if (menu["style.font.cjk"]?.title !== "中日韓字形") throw new Error("中日韓字形標題缺失")
if (menu["learn.keybindings"]?.action !== home + "/.local/bin/omarchy-menu-keybindings-zh-tw") {
  throw new Error("快捷鍵入口路徑不正確")
}
// 選單會把擴充條目正規化成完整項目，缺的欄位一律清空；覆蓋條目必須帶齊目前預設的其他欄位。
const defaults = JSON.parse(fs.readFileSync("/usr/share/omarchy/default/omarchy/omarchy-menu.jsonc", "utf8")
  .replace(/^\s*\/\/[^\n]*(\n|$)/gm, "")
  .replace(/,(\s*[}\]])/g, "$1"))
for (const [id, item] of Object.entries(menu)) {
  for (const [field, value] of Object.entries(defaults[id] || {})) {
    if (["label", "title", "searchTerms"].includes(field)) continue
    if (id === "learn.keybindings" && field === "action") continue
    if (JSON.stringify(item[field]) !== JSON.stringify(value)) throw new Error(`${id} 的 ${field} 與預設不符`)
  }
}
if (menu["trigger.capture.qr"].action !== "omarchy-capture-qr") throw new Error("QR Code 項目的動作遺失")
NODE

# 再同步一次：使用者自訂的標籤要保留，上次寫入的覆蓋要換成新的而不是累加。
node - "$menu_file" <<'NODE'
const fs = require("fs")
const file = process.argv[2]
const raw = fs.readFileSync(file, "utf8")
const menu = JSON.parse(raw.replace(/^\s*\/\/[^\n]*(\n|$)/gm, ""))
menu["system.reboot"].label = "我的重開"
menu["personal"] = { label: "個人" }
fs.writeFileSync(file, raw.split("\n")[0] + "\n" + JSON.stringify(menu, null, 2) + "\n")
NODE
HOME="$sandbox_home" USER=testuser "$ROOT_DIR/bin/omarchy-zh-tw-sync" --quiet --no-restart
node - "$menu_file" <<'NODE'
const fs = require("fs")
const menu = JSON.parse(fs.readFileSync(process.argv[2], "utf8").replace(/^\s*\/\/[^\n]*(\n|$)/gm, ""))
if (menu["system.reboot"].label !== "我的重開") throw new Error("使用者自訂標籤被覆寫")
if (!menu["system.reboot"].action || !menu["system.reboot"].icon) throw new Error("使用者改過標籤的項目缺少預設欄位")
if (menu["personal"]?.label !== "個人") throw new Error("使用者新增的項目遺失")
if (menu["trigger.capture.qr"]?.label !== "QR Code") throw new Error("第二次同步後覆蓋遺失")
NODE

node - "$plugin_root/testuser.emojis/emojis.json" <<'NODE'
const items = require(process.argv[2])
const byEmoji = new Map(items.map(item => [item.e, item.k]))
if (!byEmoji.get("😀")?.includes("笑臉")) throw new Error("笑臉繁體中文關鍵字缺失")
if (!byEmoji.get("🚗")?.includes("汽車")) throw new Error("汽車繁體中文關鍵字缺失")
if (!byEmoji.get("🧑")?.includes("人物")) throw new Error("人物後備關鍵字缺失")
NODE

keybindings="$sandbox_home/.local/bin/omarchy-menu-keybindings-zh-tw"
test -x "$keybindings"
bash -n "$keybindings"
rg -Fq 'catalog="$HOME/.local/share/omarchy-zh-tw/i18n/keybindings.json"' "$keybindings"
jq -e '.Screenshot == "截圖" and .Agent == "代理程式" and (."Switch to workspace %1" | type == "string")' \
  "$sandbox_home/.local/share/omarchy-zh-tw/i18n/keybindings.json" >/dev/null

if rg -n '/home/[[:alnum:]_.-]+|/Users/[[:alnum:]_.-]+' "$sandbox_home"; then
  echo "產生結果包含開發機器資訊。" >&2
  exit 1
fi

echo "Omarchy 隔離整合檢查通過。"
