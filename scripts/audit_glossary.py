#!/usr/bin/env python3
"""核對 docs/glossary.md 的採用譯名在詞庫裡是否有來源支持。

由 scripts/audit-glossary.sh 呼叫，輸出兩類結果：

  A. 四來源皆無條目 —— 自訂譯法，詞彙表「備註」必須說明理由。
  B. 採用譯名不在任一來源 —— 與來源不一致，需要理由或改採來源用語。

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

LABEL = {"gnome": "GNOME", "kde": "KDE", "ms": "微軟", "naer": "樂詞網"}
ORDER = ["gnome", "kde", "ms", "naer"]
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

    missing, mismatch = [], []
    for english, chinese in rows:
        queries = [q.strip().lower() for q in SPLIT.split(PAREN.sub("", english)) if q.strip()]
        adopted = readings([chinese])
        found: dict[str, set[str]] = {}
        for query in queries:
            entry = terms.get(query)
            if not entry:
                continue
            for source, values in entry.items():
                found.setdefault(source, set()).update(values)
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
    print(f"\n### A. 四來源皆無條目（{len(missing)} 項）")
    for english, chinese in missing:
        print(f"  {english:26s} 採用「{chinese}」")
    print(f"\n### B. 採用譯名不在任一來源（{len(mismatch)} 項）")
    for english, chinese, detail in mismatch:
        print(f"  {english:26s} 採用「{chinese}」")
        print(f"      {detail}")
    print("\n兩類都不是錯誤，但都必須在詞彙表「備註」說明理由。")
    return 0


if __name__ == "__main__":
    sys.exit(main())
