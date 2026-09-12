#!/usr/bin/env bash

set -euo pipefail

NAER_TERMS_JSON="${NAER_TERMS_JSON:-$HOME/Documents/電子計算機名詞.json}"

usage() {
  cat <<'EOF'
用法：scripts/naer-lookup.sh <英文詞彙>...

查詢國家教育研究院樂詞網《電子計算機名詞》，輸出「原文 → 譯名（詞條編號）」。
先列完全相符的條目，再列含有該詞的其他條目。
查照結果請記錄到 docs/glossary.md。

資料格式為詞條物件，鍵是英文詞彙：

  {"cache": {"zh": "快取", "id": "20271234", "updated": "2024-12-30"}}

環境變數：
  NAER_TERMS_JSON  詞庫 JSON 路徑（預設：$HOME/Documents/電子計算機名詞.json）
EOF
}

(($# > 0)) || {
  usage >&2
  exit 2
}

[[ $1 == --help || $1 == -h ]] && {
  usage
  exit 0
}

command -v jq >/dev/null 2>&1 || {
  echo "找不到 jq，請先安裝。" >&2
  exit 1
}

[[ -f $NAER_TERMS_JSON ]] || {
  echo "找不到樂詞網詞庫：$NAER_TERMS_JSON" >&2
  echo "請設定 NAER_TERMS_JSON 後再試。" >&2
  exit 1
}

for term in "$@"; do
  echo "== $term =="
  jq -r --arg term "$term" '
    ($term | ascii_downcase) as $q
    | to_entries
    | map(select((.key | ascii_downcase) == $q))
    | if length == 0 then empty
      else .[] | "  [完全相符] \(.key) → \(.value | if type == "array" then map(.zh) | join("；") else .zh end)"
      end
  ' "$NAER_TERMS_JSON"
  jq -r --arg term "$term" '
    ($term | ascii_downcase) as $q
    | to_entries
    | map(select((.key | ascii_downcase) != $q and (.key | ascii_downcase | contains($q))))
    | sort_by(.key | length)
    | .[:8][]
    | "  \(.key) → \(.value | if type == "array" then map(.zh) | join("；") else .zh end)"
  ' "$NAER_TERMS_JSON"
done
