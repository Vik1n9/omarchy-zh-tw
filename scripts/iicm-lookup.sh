#!/usr/bin/env bash

set -euo pipefail

IICM_TERMS_DIR="${IICM_TERMS_DIR:-$HOME/Documents/iicm-computer-terms}"

usage() {
  cat <<'EOF'
用法：scripts/iicm-lookup.sh <英文詞彙>...

查詢 IICM 電腦名詞譯名表，輸出「編號 | 原文 | 臺灣用語 | 大陸用語」。
查照結果請登錄到 docs/glossary.md。

環境變數：
  IICM_TERMS_DIR  對照表目錄（預設：$HOME/Documents/iicm-computer-terms）
EOF
}

(($# > 0)) || { usage >&2; exit 2; }

[[ -d $IICM_TERMS_DIR ]] || {
  echo "找不到 IICM 對照表目錄：$IICM_TERMS_DIR" >&2
  echo "請設定 IICM_TERMS_DIR 後再試。" >&2
  exit 1
}

for term in "$@"; do
  escaped=$(printf '%s' "$term" | sed 's/[][\\.*^$()+?{}|/]/\\&/g')
  echo "== $term =="
  rg -i --no-filename "^\\| *[0-9]+ *\\| *${escaped}\\b" "$IICM_TERMS_DIR"/*.md | head -8 || true
done
