#!/usr/bin/env bash
#
# 依 docs/glossary.md 的順位查詢譯名詞庫（scripts/build-termbase.sh 建立）。
# 查不到就明說查不到，不要自行造詞；查到也要看出處，同一個詞在不同語境可能有不同譯法。

set -euo pipefail

CACHE_DIR="${OMARCHY_TERMBASE_CACHE:-${XDG_CACHE_HOME:-$HOME/.cache}/omarchy-zh-tw}"
TERMBASE="${OMARCHY_TERMBASE:-$CACHE_DIR/termbase.json}"

usage() {
  cat <<'EOF'
用法：scripts/term-lookup.sh [--near] <英文詞彙>...

依順位輸出各來源的譯名：GNOME → KDE → 台灣微軟 → 樂詞網。
GNOME 與 KDE 的譯名會標出「模組:原始 msgid」，供判斷語境是否適用。

選項：
  --near   只列鄰近條目，不列完全相符

環境變數：
  OMARCHY_TERMBASE  詞庫路徑（預設 $XDG_CACHE_HOME/omarchy-zh-tw/termbase.json）

詞庫尚未建立時，先執行 scripts/build-termbase.sh。
EOF
}

NEAR_ONLY=0
args=()
while (($#)); do
  case $1 in
  --near) NEAR_ONLY=1 ;;
  --help | -h)
    usage
    exit 0
    ;;
  *) args+=("$1") ;;
  esac
  shift
done

((${#args[@]})) || {
  usage >&2
  exit 2
}

[[ -f $TERMBASE ]] || {
  echo "找不到詞庫：$TERMBASE" >&2
  echo "請先執行 scripts/build-termbase.sh 建立。" >&2
  exit 1
}

TERMBASE="$TERMBASE" NEAR_ONLY="$NEAR_ONLY" python3 "$(dirname -- "${BASH_SOURCE[0]}")/termbase_query.py" "${args[@]}"
