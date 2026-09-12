#!/usr/bin/env bash
#
# 依 docs/glossary.md 的順位查詢譯名詞庫（scripts/build-termbase.sh 建立）。
# 查不到就明說查不到，不要自行造詞。

set -euo pipefail

ROOT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
CACHE_DIR="${OMARCHY_TERMBASE_CACHE:-${XDG_CACHE_HOME:-$HOME/.cache}/omarchy-zh-tw}"
TERMBASE="${OMARCHY_TERMBASE:-$CACHE_DIR/termbase.json}"

usage() {
  cat <<'EOF'
用法：scripts/term-lookup.sh [--near] <英文詞彙>...

依順位輸出各來源的譯名：GNOME → KDE → 台灣微軟 → 樂詞網。
先列完全相符，再列含有該詞的鄰近條目。

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

TERMBASE="$TERMBASE" NEAR_ONLY="$NEAR_ONLY" python3 - "${args[@]}" <<'PY'
import json, os, sys

LABEL = {"gnome": "GNOME", "kde": "KDE", "ms": "台灣微軟", "naer": "樂詞網"}
ORDER = ["gnome", "kde", "ms", "naer"]

data = json.load(open(os.environ["TERMBASE"], encoding="utf-8"))
terms = data["terms"]
near_only = os.environ["NEAR_ONLY"] == "1"
meta = data.get("_meta", {})
print(f"# 詞庫建立於 {meta.get('built', '?')}，共 {len(terms)} 個詞條")

for query in sys.argv[1:]:
    key = query.lower()
    print(f"\n== {query} ==")
    entry = terms.get(key)
    if entry and not near_only:
        for source in ORDER:
            if source in entry:
                print(f"  {LABEL[source]:8s} {'、'.join(entry[source])}")
    elif not entry:
        print("  查無完全相符的條目。")

    near = [k for k in terms if k != key and key in k.split()]
    near.sort(key=len)
    if near:
        print("  -- 鄰近條目 --")
        for k in near[:6]:
            parts = [
                f"{LABEL[s]}：{'、'.join(terms[k][s])}" for s in ORDER if s in terms[k]
            ]
            print(f"  {k} → {'；'.join(parts)}")
PY
