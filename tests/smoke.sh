#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)

bash -n "$ROOT_DIR/install.sh"
bash -n "$ROOT_DIR/uninstall.sh"
bash -n "$ROOT_DIR/hooks/omarchy-zh-post-update"
bash -n "$ROOT_DIR/bin/omarchy-update-zh"
bash -n "$ROOT_DIR/bin/omarchy-update-confirm-zh"
node --check "$ROOT_DIR/bin/omarchy-zh-sync"
"$ROOT_DIR/bin/omarchy-zh-sync" --help >/dev/null

if rg -n '/home/[[:alnum:]_.-]+|/Users/[[:alnum:]_.-]+' "$ROOT_DIR" \
  -g '!tests/smoke.sh' -g '!tests/integration.sh'; then
  echo "发现个人路径或用户名。" >&2
  exit 1
fi

for expected in \
  '"scrolling": "滚动布局"' \
  '"dwindle": "螺旋平铺"' \
  '"WIND": "风速"' \
  'omarchy-menu-select '\''快捷键'\''' \
  '系统更新插件结构已变化：更新入口'; do
  rg -Fq "$expected" "$ROOT_DIR/bin/omarchy-zh-sync" || {
    echo "缺少关键翻译：$expected" >&2
    exit 1
  }
done

rg -Fq '准备更新吗？' "$ROOT_DIR/bin/omarchy-update-confirm-zh"
rg -Fq -- '--affirmative "是"' "$ROOT_DIR/bin/omarchy-update-confirm-zh"
rg -Fq -- '--negative "否"' "$ROOT_DIR/bin/omarchy-update-confirm-zh"

echo "静态检查通过。"
"$ROOT_DIR/tests/integration.sh"
"$ROOT_DIR/tests/install-cycle.sh"
