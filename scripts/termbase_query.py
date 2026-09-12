#!/usr/bin/env python3
"""查詢 scripts/build-termbase.sh 建立的譯名詞庫。

由 scripts/term-lookup.sh 呼叫。輸出刻意帶上出處：GNOME／KDE 的譯名附上
「模組:原始 msgid」，因為同一個英文詞在不同語境常有不同譯法，例如
GNOME 的 Screenshots 是 ~/Pictures 底下的資料夾名稱（螢幕快照），而動作
語境的 Take a screenshot 作「擷取螢幕畫面」——只看譯名會選錯。

查詢一律精確比對，不自動補複數或詞形變化：變體是獨立條目，要分別查詢，
否則容易把別的語境的條目當成本詞的定論。
"""

from __future__ import annotations

import json
import os
import sys

LABEL = {"gnome": "GNOME", "kde": "KDE", "ms": "台灣微軟", "naer": "樂詞網"}
ORDER = ["gnome", "kde", "ms", "naer"]
PO_SOURCES = ("gnome", "kde")


def show(key: str, entry: dict, indent: str = "  ") -> None:
    for source in ORDER:
        readings = entry.get(source)
        if not readings:
            continue
        for zh, origins in readings.items():
            hint = ""
            if source in PO_SOURCES:
                # 原始 msgid 與查詢鍵不同的出處最能說明語境，優先顯示。
                distinct = [o for o in origins if o.split(":", 1)[-1].lower() != key]
                shown = (distinct or list(origins))[:2]
                if shown:
                    hint = "  ← " + "；".join(shown)
            print(f"{indent}{LABEL[source]:8s} {zh}{hint}")


def main() -> int:
    path = os.environ["TERMBASE"]
    near_only = os.environ.get("NEAR_ONLY") == "1"
    with open(path, encoding="utf-8") as handle:
        data = json.load(handle)
    terms = data["terms"]
    meta = data.get("_meta", {})
    print(f"# 詞庫建立於 {meta.get('built', '?')}，共 {len(terms)} 個詞條")

    for query in sys.argv[1:]:
        key = query.lower()
        print(f"\n== {query} ==")
        entry = terms.get(key)
        if entry and not near_only:
            show(key, entry)
        elif not entry:
            print("  查無完全相符的條目。")
            print("  變體（複數、動詞片語）是獨立條目，請分別查詢後再判斷。")

        near = sorted(
            (k for k in terms if k != key and key in k.split()), key=len
        )
        if near:
            print("  -- 鄰近條目（語境可能不同，採用前請確認出處）--")
            for near_key in near[:6]:
                print(f"  {near_key}")
                show(near_key, terms[near_key], indent="    ")
    return 0


if __name__ == "__main__":
    sys.exit(main())
