#!/usr/bin/env python3
"""核對 docs/glossary.md 的採用譯名在詞庫裡是否有來源支持。

由 scripts/audit-glossary.sh 呼叫，輸出兩類結果：

  A. 四來源皆無條目，且未收錄於自訂詞庫 —— 需要查證或收錄。
  B. 採用譯名不在任一來源，且未收錄於自訂詞庫 —— 需要理由或改採來源用語。
  C. 已收錄於 docs/terms-local.json —— 專案已決議，僅列出供覆核。

自訂詞庫是第五順位，稽核時單獨計算：把它算進「有來源」會讓稽核永遠通過，
完全不算又會讓已定案的詞每次都被當成漏網詞重複提出。

比對規則刻意保守：
  * 只用詞彙表「原文」欄列出的詞查詢，不自動補複數或詞形變化。
    變體是獨立條目，語境往往不同，自動擴充會把別的語境的譯名當成定論。
  * 來源的多重譯名（「甲；乙」「甲、乙」）會拆開比對，避免整串比對造成誤判。
"""

from __future__ import annotations

import json
import os
import re
import sys

LABEL = {"gnome": "GNOME", "kde": "KDE", "ms": "微軟", "naer": "樂詞網", "local": "本專案"}
ORDER = ["gnome", "kde", "ms", "naer"]
LOCAL = "local"
SPLIT = re.compile(r"[；;、，,／/]")
PAREN = re.compile(r"（[^）]*）|\([^)]*\)")
ROW = re.compile(r"\|\s*([^|]+?)\s*\|\s*([^|]+?)\s*\|")


def readings(values) -> set[str]:
    out = set()
    for value in values:
        for part in SPLIT.split(PAREN.sub("", value)):
            part = part.strip().strip("*")
            if part:
                out.add(part)
    return out


def glossary_rows(path: str) -> list[tuple[str, str]]:
    rows = []
    inside = False
    for line in open(path, encoding="utf-8"):
        if line.startswith("## 採用譯名"):
            inside = True
            continue
        if inside and line.startswith("## "):
            break
        if not inside or line.startswith("| ---"):
            continue
        match = ROW.match(line)
        if match and "原文" not in match.group(1):
            rows.append((match.group(1), match.group(2)))
    return rows


def main() -> int:
    with open(os.environ["TERMBASE"], encoding="utf-8") as handle:
        terms = json.load(handle)["terms"]
    rows = glossary_rows(os.environ["GLOSSARY"])

    missing, mismatch, decided = [], [], []
    for english, chinese in rows:
        queries = [q.strip().lower() for q in SPLIT.split(PAREN.sub("", english)) if q.strip()]
        adopted = readings([chinese])
        found: dict[str, set[str]] = {}
        local: set[str] = set()
        for query in queries:
            entry = terms.get(query)
            if not entry:
                continue
            for source, values in entry.items():
                if source == LOCAL:
                    local |= readings(values)
                else:
                    found.setdefault(source, set()).update(values)
        if adopted & local:
            decided.append((english, chinese))
            continue
        if not found:
            missing.append((english, chinese))
            continue
        available = set()
        for values in found.values():
            available |= readings(values)
        if not adopted & available:
            detail = " | ".join(
                f"{LABEL[s]}:{'、'.join(sorted(found[s])[:5])}" for s in ORDER if s in found
            )
            mismatch.append((english, chinese, detail))

    print(f"詞彙表共 {len(rows)} 列")
    print(f"\n### A. 四來源皆無條目，且未收錄於自訂詞庫（{len(missing)} 項）")
    for english, chinese in missing:
        print(f"  {english:26s} 採用「{chinese}」")
    print(f"\n### B. 採用譯名不在任一來源，且未收錄於自訂詞庫（{len(mismatch)} 項）")
    for english, chinese, detail in mismatch:
        print(f"  {english:26s} 採用「{chinese}」")
        print(f"      {detail}")
    print(f"\n### C. 已收錄於 docs/terms-local.json（{len(decided)} 項）")
    for english, chinese in decided:
        print(f"  {english:26s} 採用「{chinese}」")

    if missing or mismatch:
        print("\nA、B 兩類請查證後改採來源用語，或收錄到 docs/terms-local.json 並寫明理由。")
    else:
        print("\n所有採用譯名都有來源支持或已收錄於自訂詞庫。")
    return 0


if __name__ == "__main__":
    sys.exit(main())
