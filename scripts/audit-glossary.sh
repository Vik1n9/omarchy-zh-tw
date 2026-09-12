#!/usr/bin/env bash
#
# 用詞庫核對 docs/glossary.md，列出沒有來源支持的採用譯名。
# 不修改任何檔案，只輸出報告；結果請據以補上「備註」或改採來源用語。

set -euo pipefail

ROOT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
CACHE_DIR="${OMARCHY_TERMBASE_CACHE:-${XDG_CACHE_HOME:-$HOME/.cache}/omarchy-zh-tw}"
TERMBASE="${OMARCHY_TERMBASE:-$CACHE_DIR/termbase.json}"

[[ ${1:-} != --help && ${1:-} != -h ]] || {
  cat <<'EOF'
用法：scripts/audit-glossary.sh

以詞庫核對 docs/glossary.md 的採用譯名，分兩類列出：
  A. 四來源皆無條目
  B. 採用譯名不在任一來源

環境變數：
  OMARCHY_TERMBASE  詞庫路徑（預設 $XDG_CACHE_HOME/omarchy-zh-tw/termbase.json）
EOF
  exit 0
}

[[ -f $TERMBASE ]] || {
  echo "找不到詞庫：$TERMBASE" >&2
  echo "請先執行 scripts/build-termbase.sh 建立。" >&2
  exit 1
}

TERMBASE="$TERMBASE" GLOSSARY="$ROOT_DIR/docs/glossary.md" \
  python3 "$ROOT_DIR/scripts/audit_glossary.py"
