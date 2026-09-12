#!/usr/bin/env python3
"""把各來源的譯名資料合併成單一查詢用 JSON。

由 scripts/build-termbase.sh 呼叫，不直接散布任何來源資料：每個來源都在
執行時從官方網址取得，輸出只留在本機快取。

輸出格式：

    {
      "_meta": {"built": "...", "sources": {...}},
      "terms": {
        "menu": {"gnome": ["選單"], "kde": ["選單"], "ms": ["功能表", "選單"]}
      }
    }

鍵一律是小寫英文詞彙；值依來源分組，方便依 docs/glossary.md 的順位裁決。
"""

from __future__ import annotations

import argparse
import collections
import json
import pathlib
import re
import sys
import xml.etree.ElementTree as ET
import zipfile
from datetime import date

XML_LANG = "{http://www.w3.org/XML/1998/namespace}lang"

# po 的 msgid 是完整介面字串，只有夠短、單行、不含標點的才算術語。
MAX_TERM_WORDS = 4
MAX_TERM_CHARS = 40
SKIP_MSGID = re.compile(r"[\n%{}<>|]|\.\.\.|^$")

PO_ESCAPES = {"n": "\n", "t": "\t", "r": "\r", '"': '"', "\\": "\\"}


def unescape_po(raw: str) -> str:
    out = []
    i = 0
    while i < len(raw):
        ch = raw[i]
        if ch == "\\" and i + 1 < len(raw):
            out.append(PO_ESCAPES.get(raw[i + 1], raw[i + 1]))
            i += 2
        else:
            out.append(ch)
            i += 1
    return "".join(out)


def parse_po(text: str) -> list[tuple[str, str]]:
    """回傳 po 檔中的 (msgid, msgstr) 對，略過 fuzzy、複數與表頭。"""
    pairs = []
    msgid = msgstr = None
    target = None
    fuzzy = False
    pending_fuzzy = False

    def flush():
        nonlocal msgid, msgstr, fuzzy
        if msgid and msgstr and not fuzzy:
            pairs.append((msgid, msgstr))
        msgid = msgstr = None
        fuzzy = False

    for line in text.splitlines():
        line = line.strip()
        if line.startswith("#,"):
            pending_fuzzy = "fuzzy" in line
            continue
        if line.startswith("#"):
            continue
        if line.startswith("msgid_plural") or line.startswith("msgstr["):
            target = None
            continue
        if line.startswith("msgid "):
            flush()
            fuzzy = pending_fuzzy
            pending_fuzzy = False
            msgid = unescape_po(line[6:].strip().strip('"'))
            target = "id"
            continue
        if line.startswith("msgstr "):
            msgstr = unescape_po(line[7:].strip().strip('"'))
            target = "str"
            continue
        if line.startswith('"') and target:
            chunk = unescape_po(line.strip().strip('"'))
            if target == "id":
                msgid = (msgid or "") + chunk
            else:
                msgstr = (msgstr or "") + chunk
            continue
        if not line:
            flush()
            target = None
    flush()
    return pairs


def is_term(msgid: str) -> bool:
    if SKIP_MSGID.search(msgid):
        return False
    if len(msgid) > MAX_TERM_CHARS:
        return False
    if len(msgid.split()) > MAX_TERM_WORDS:
        return False
    return any(c.isalpha() for c in msgid)


def collect_po(paths: list[pathlib.Path], terms: dict, source: str) -> int:
    added = 0
    for path in paths:
        try:
            text = path.read_text(encoding="utf-8", errors="replace")
        except OSError as exc:
            print(f"  略過 {path.name}：{exc}", file=sys.stderr)
            continue
        for msgid, msgstr in parse_po(text):
            if not is_term(msgid):
                continue
            terms[msgid.lower().rstrip(":")][source].add(msgstr.rstrip("："))
            added += 1
    return added


def collect_tbx(archive: pathlib.Path, member: str, terms: dict, source: str) -> int:
    """抽出微軟術語集，只採標記 TWN（台灣）或未標地區的譯名。"""
    added = 0
    with zipfile.ZipFile(archive) as zf, zf.open(member) as handle:
        for _, element in ET.iterparse(handle, events=("end",)):
            if element.tag != "termEntry":
                continue
            english, chinese = [], []
            for lang_set in element.findall("langSet"):
                lang = lang_set.get(XML_LANG, "")
                found = [(t.text or "").strip() for t in lang_set.iter("term")]
                if lang == "en-US":
                    english += found
                elif lang.startswith("zh"):
                    geo = " ".join(
                        note.text or ""
                        for note in lang_set.iter("termNote")
                        if note.get("type") == "geographicalUsage"
                    )
                    if "TWN" in geo or not geo.strip():
                        chinese += found
            for en in english:
                for zh in chinese:
                    if en and zh:
                        terms[en.lower()][source].add(zh)
                        added += 1
            element.clear()
    return added


def naer_readings(entry) -> list[str]:
    """樂詞網同一詞彙可能是單一物件、物件陣列，或直接是字串。"""
    if isinstance(entry, str):
        return [entry]
    if isinstance(entry, dict):
        return naer_readings(entry.get("zh"))
    if isinstance(entry, list):
        out = []
        for item in entry:
            out += naer_readings(item)
        return out
    return []


def collect_naer(path: pathlib.Path, terms: dict, source: str) -> int:
    data = json.loads(path.read_text(encoding="utf-8"))
    added = 0
    for english, entry in data.items():
        if not english:
            continue
        for chinese in naer_readings(entry):
            if chinese:
                terms[english.lower()][source].add(chinese)
                added += 1
    return added


def main() -> int:
    parser = argparse.ArgumentParser(description="合併譯名來源為單一查詢 JSON")
    parser.add_argument("--out", required=True, type=pathlib.Path)
    parser.add_argument("--gnome-dir", type=pathlib.Path)
    parser.add_argument("--kde-dir", type=pathlib.Path)
    parser.add_argument("--ms-zip", type=pathlib.Path)
    parser.add_argument("--ms-member", default="CHINESE (TRADITIONAL).tbx")
    parser.add_argument("--naer-json", type=pathlib.Path)
    parser.add_argument("--source-note", action="append", default=[])
    args = parser.parse_args()

    terms: dict = collections.defaultdict(lambda: collections.defaultdict(set))
    counts = {}

    if args.gnome_dir and args.gnome_dir.is_dir():
        counts["gnome"] = collect_po(sorted(args.gnome_dir.glob("*.po")), terms, "gnome")
    if args.kde_dir and args.kde_dir.is_dir():
        counts["kde"] = collect_po(sorted(args.kde_dir.glob("*.po")), terms, "kde")
    if args.ms_zip and args.ms_zip.is_file():
        counts["ms"] = collect_tbx(args.ms_zip, args.ms_member, terms, "ms")
    if args.naer_json and args.naer_json.is_file():
        counts["naer"] = collect_naer(args.naer_json, terms, "naer")

    if not counts:
        print("沒有任何可用的來源。", file=sys.stderr)
        return 1

    payload = {
        "_meta": {
            "built": date.today().isoformat(),
            "entries": counts,
            "sources": args.source_note,
            "order": ["gnome", "kde", "ms", "naer"],
        },
        "terms": {
            key: {src: sorted(vals) for src, vals in sorted(by_source.items())}
            for key, by_source in sorted(terms.items())
        },
    }
    args.out.parent.mkdir(parents=True, exist_ok=True)
    args.out.write_text(
        json.dumps(payload, ensure_ascii=False, separators=(",", ":")), encoding="utf-8"
    )
    total = len(payload["terms"])
    print(f"詞庫已寫入 {args.out}：{total} 個詞條")
    for src, n in sorted(counts.items()):
        print(f"  {src}: {n} 筆")
    return 0


if __name__ == "__main__":
    sys.exit(main())
