#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)

bash -n "$ROOT_DIR/install.sh"
bash -n "$ROOT_DIR/uninstall.sh"
bash -n "$ROOT_DIR/hooks/omarchy-zh-tw-post-update"
bash -n "$ROOT_DIR/scripts/audit-glossary.sh"
bash -n "$ROOT_DIR/scripts/build-termbase.sh"
bash -n "$ROOT_DIR/scripts/term-lookup.sh"
bash -n "$ROOT_DIR/scripts/naer-lookup.sh"
bash -n "$ROOT_DIR/scripts/iicm-lookup.sh"
python -c 'import ast, pathlib, sys; [ast.parse(pathlib.Path(item).read_text()) for item in sys.argv[1:]]' \
  "$ROOT_DIR/scripts/audit_glossary.py" \
  "$ROOT_DIR/scripts/termbase_build.py" \
  "$ROOT_DIR/scripts/termbase_query.py"
python -c 'import json, sys; json.load(open(sys.argv[1]))' "$ROOT_DIR/docs/terms-local.json"
node --check "$ROOT_DIR/bin/omarchy-zh-tw-sync"
"$ROOT_DIR/bin/omarchy-zh-tw-sync" --help >/dev/null

# 覆蓋詞庫：必須是合法 JSON；shell 字串保留原文的 %1 等占位符號，選單項目只能有 label／title。
node - "$ROOT_DIR/i18n/zh-TW" <<'NODE'
const fs = require("fs")
const path = require("path")
const dir = process.argv[2]
const load = name => JSON.parse(fs.readFileSync(path.join(dir, `${name}.json`), "utf8"))
const shell = load("shell")
const menu = load("menu")
const keybindings = load("keybindings")
for (const [key, value] of Object.entries(shell)) {
  const forms = typeof value === "string" ? [value] : Object.values(value || {})
  if (!forms.length || forms.some(form => typeof form !== "string" || !form)) throw new Error(`shell 覆蓋格式錯誤：${key}`)
  if (typeof value === "object" && typeof value.other !== "string") throw new Error(`shell 複數覆蓋缺少 other：${key}`)
}
for (const [id, value] of Object.entries(menu)) {
  const fields = Object.keys(value || {})
  if (!fields.length || fields.some(field => !["label", "title"].includes(field))) throw new Error(`選單覆蓋格式錯誤：${id}`)
}
for (const [key, value] of Object.entries(keybindings)) {
  if (typeof value !== "string" || !value) throw new Error(`快捷鍵覆蓋格式錯誤：${key}`)
}
NODE

# 有 Omarchy 時，再對照內建英文目錄核對鍵名與占位符號。
english=/usr/share/omarchy/default/i18n/en
if [[ -d $english ]]; then
  node - "$ROOT_DIR/i18n/zh-TW" "$english" <<'NODE'
const fs = require("fs")
const path = require("path")
const [dir, english] = process.argv.slice(2)
const load = (base, name) => JSON.parse(fs.readFileSync(path.join(base, `${name}.json`), "utf8"))
const holes = text => (String(text).match(/%\d+/g) || []).sort().join(",")
for (const name of ["shell", "menu", "keybindings"]) {
  const ours = load(dir, name)
  const theirs = load(english, name)
  for (const [key, value] of Object.entries(ours)) {
    if (!(key in theirs)) throw new Error(`${name} 覆蓋的鍵不在 Omarchy 英文目錄：${key}`)
    if (name === "menu") continue
    const source = typeof theirs[key] === "string" ? theirs[key] : theirs[key].other
    const target = typeof value === "string" ? value : value.other
    if (holes(source) !== holes(target)) throw new Error(`${name} 覆蓋的占位符號與原文不符：${key}`)
  }
}
NODE
fi

if rg -n '/home/[[:alnum:]_.-]+|/Users/[[:alnum:]_.-]+' "$ROOT_DIR" \
  -g '!tests/smoke.sh' -g '!tests/integration.sh'; then
  echo "發現個人路徑或使用者名稱。" >&2
  exit 1
fi

echo "靜態檢查通過。"
"$ROOT_DIR/tests/terminology.sh"
"$ROOT_DIR/tests/integration.sh"
"$ROOT_DIR/tests/install-cycle.sh"
