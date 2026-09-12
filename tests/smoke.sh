#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)

bash -n "$ROOT_DIR/install.sh"
bash -n "$ROOT_DIR/uninstall.sh"
bash -n "$ROOT_DIR/hooks/omarchy-zh-tw-post-update"
bash -n "$ROOT_DIR/bin/omarchy-update-zh-tw"
bash -n "$ROOT_DIR/bin/omarchy-update-confirm-zh-tw"
for script in codex usage-update; do
  bash -n "$ROOT_DIR/agents-overlay/bin/$script"
done
bash -n "$ROOT_DIR/scripts/build-termbase.sh"
bash -n "$ROOT_DIR/scripts/term-lookup.sh"
bash -n "$ROOT_DIR/scripts/naer-lookup.sh"
bash -n "$ROOT_DIR/scripts/iicm-lookup.sh"
python -c 'import ast, pathlib, sys; [ast.parse(pathlib.Path(item).read_text()) for item in sys.argv[1:]]' \
  "$ROOT_DIR/scripts/termbase_build.py" \
  "$ROOT_DIR/agents-overlay/bin/codex-collector" \
  "$ROOT_DIR/agents-overlay/bin/grok-collector" \
  "$ROOT_DIR/agents-overlay/bin/kimi-collector"
python -B -m unittest "$ROOT_DIR/agents-overlay/tests/test_collectors.py"
node --check "$ROOT_DIR/bin/omarchy-zh-tw-sync"
"$ROOT_DIR/bin/omarchy-zh-tw-sync" --help >/dev/null

if rg -n '/home/[[:alnum:]_.-]+|/Users/[[:alnum:]_.-]+' "$ROOT_DIR" \
  -g '!tests/smoke.sh' -g '!tests/integration.sh'; then
  echo "發現個人路徑或使用者名稱。" >&2
  exit 1
fi

for expected in \
  '"scrolling": "捲動版面配置"' \
  '"dwindle": "Dwindle 平鋪"' \
  '"WIND": "風速"' \
  'omarchy-menu-select '\''快捷鍵'\''' \
  '系統更新外掛結構已變化：更新入口'; do
  rg -Fq "$expected" "$ROOT_DIR/bin/omarchy-zh-tw-sync" || {
    echo "缺少關鍵翻譯：$expected" >&2
    exit 1
  }
done

rg -Fq '準備更新嗎？' "$ROOT_DIR/bin/omarchy-update-confirm-zh-tw"
rg -Fq -- '--affirmative "是"' "$ROOT_DIR/bin/omarchy-update-confirm-zh-tw"
rg -Fq -- '--negative "否"' "$ROOT_DIR/bin/omarchy-update-confirm-zh-tw"

echo "靜態檢查通過。"
"$ROOT_DIR/tests/terminology.sh"
"$ROOT_DIR/tests/integration.sh"
"$ROOT_DIR/tests/install-cycle.sh"
