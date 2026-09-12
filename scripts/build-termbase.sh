#!/usr/bin/env bash
#
# 從官方來源建立譯名查詢詞庫。本儲存庫不散布任何來源資料，每次執行都重新下載；
# 產出只留在本機快取，不進版本控制。
#
# 來源與 docs/glossary.md 的順位一致：
#   1. GNOME zh_TW  gitlab.gnome.org 各模組 po/zh_TW.po（GPL／LGPL）
#   2. KDE zh_TW    websvn.kde.org trunk/l10n-kf6/zh_TW（GPL）
#   3. 台灣微軟     Microsoft Terminology Collection 的 CHINESE (TRADITIONAL).tbx
#                   只採 geographicalUsage 標記 TWN 或未標地區的譯名
#   4. 樂詞網       國家教育研究院《電子計算機名詞》JSON，需自行下載後指定路徑

set -euo pipefail

ROOT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)

CACHE_DIR="${OMARCHY_TERMBASE_CACHE:-${XDG_CACHE_HOME:-$HOME/.cache}/omarchy-zh-tw}"
OUT="${OMARCHY_TERMBASE:-$CACHE_DIR/termbase.json}"
NAER_TERMS_JSON="${NAER_TERMS_JSON:-$HOME/Documents/電子計算機名詞.json}"

MS_URL="https://download.microsoft.com/download/b/2/d/b2db7a7c-8d33-47f3-b2c1-ee5e6445cf45/MicrosoftTermCollection.zip"
GNOME_RAW="https://gitlab.gnome.org/GNOME"
KDE_RAW="https://websvn.kde.org/trunk/l10n-kf6/zh_TW/messages"

GNOME_MODULES=(
  gnome-shell gnome-control-center gnome-settings-daemon gnome-desktop
  nautilus gtk gnome-system-monitor gnome-disk-utility gnome-calculator
  gnome-text-editor gnome-calendar gnome-weather loupe file-roller gnome-tweaks
)
KDE_MODULES=(
  "dolphin/dolphin.po"
  "kio/kio6.po"
  "plasma-desktop/plasma-desktop._desktop_.po"
  "plasma-workspace/plasmashell.po"
  "plasma-workspace/plasma-workspace._desktop_.po"
  "systemsettings/systemsettings.po"
  "plasma-nm/plasmanetworkmanagement-libs.po"
  "plasma-pa/plasma_applet_org.kde.plasma.volume.po"
  "kdeplasma-addons/plasma_applet_org.kde.plasma.weather.po"
)

SKIP_MS=0
usage() {
  cat <<'EOF'
用法：scripts/build-termbase.sh [--skip-ms] [--out PATH]

建立 scripts/term-lookup.sh 使用的譯名詞庫。

選項：
  --skip-ms     略過微軟術語集（該檔約 176 MB，下載較久）
  --out PATH    輸出路徑

環境變數：
  OMARCHY_TERMBASE        輸出路徑（預設 $XDG_CACHE_HOME/omarchy-zh-tw/termbase.json）
  OMARCHY_TERMBASE_CACHE  下載暫存目錄
  NAER_TERMS_JSON         樂詞網《電子計算機名詞》JSON 路徑
EOF
}

while (($#)); do
  case $1 in
  --skip-ms) SKIP_MS=1 ;;
  --out)
    shift
    OUT=${1:?--out 需要路徑}
    ;;
  --help | -h)
    usage
    exit 0
    ;;
  *)
    echo "未知選項：$1" >&2
    usage >&2
    exit 2
    ;;
  esac
  shift
done

for tool in curl python3; do
  command -v "$tool" >/dev/null 2>&1 || {
    echo "找不到 $tool，請先安裝。" >&2
    exit 1
  }
done

mkdir -p "$CACHE_DIR/gnome" "$CACHE_DIR/kde"
notes=()

fetch() {
  local url=$1 dest=$2
  curl -sS -L --fail --max-time 180 -o "$dest" "$url" 2>/dev/null
}

echo "下載 GNOME zh_TW 翻譯…"
gnome_ok=0
for module in "${GNOME_MODULES[@]}"; do
  got=0
  # 各模組的預設分支不一致，main 與 master 都試。
  for branch in main master; do
    if fetch "$GNOME_RAW/$module/-/raw/$branch/po/zh_TW.po" "$CACHE_DIR/gnome/$module.po"; then
      got=1
      break
    fi
  done
  if ((got)); then
    gnome_ok=$((gnome_ok + 1))
  else
    rm -f "$CACHE_DIR/gnome/$module.po"
    echo "  取不到 $module，略過。" >&2
  fi
done
echo "  取得 $gnome_ok／${#GNOME_MODULES[@]} 個模組"
notes+=("gnome: $GNOME_RAW/<module>/-/raw/main/po/zh_TW.po ($gnome_ok modules)")

echo "下載 KDE zh_TW 翻譯…"
kde_ok=0
for path in "${KDE_MODULES[@]}"; do
  name=${path//\//_}
  if fetch "$KDE_RAW/$path?view=co" "$CACHE_DIR/kde/$name" &&
    grep -q '^msgid' "$CACHE_DIR/kde/$name"; then
    kde_ok=$((kde_ok + 1))
  else
    rm -f "$CACHE_DIR/kde/$name"
    echo "  取不到 $path，略過。" >&2
  fi
done
echo "  取得 $kde_ok／${#KDE_MODULES[@]} 個模組"
notes+=("kde: $KDE_RAW/<module>?view=co ($kde_ok modules)")

ms_args=()
if ((SKIP_MS)); then
  echo "略過微軟術語集（--skip-ms）。"
else
  if [[ ! -f $CACHE_DIR/MicrosoftTermCollection.zip ]]; then
    echo "下載微軟術語集（約 176 MB，請稍候）…"
    curl -sS -L --fail --max-time 1800 -o "$CACHE_DIR/MicrosoftTermCollection.zip" "$MS_URL"
  else
    echo "沿用已下載的微軟術語集。"
  fi
  ms_args=(--ms-zip "$CACHE_DIR/MicrosoftTermCollection.zip")
  notes+=("ms: $MS_URL (CHINESE (TRADITIONAL).tbx, geographicalUsage TWN)")
fi

naer_args=()
if [[ -f $NAER_TERMS_JSON ]]; then
  naer_args=(--naer-json "$NAER_TERMS_JSON")
  notes+=("naer: $NAER_TERMS_JSON")
else
  echo "找不到樂詞網詞庫（$NAER_TERMS_JSON），略過該來源。" >&2
fi

note_args=()
for note in "${notes[@]}"; do
  note_args+=(--source-note "$note")
done

python3 "$ROOT_DIR/scripts/termbase_build.py" \
  --out "$OUT" \
  --gnome-dir "$CACHE_DIR/gnome" \
  --kde-dir "$CACHE_DIR/kde" \
  "${ms_args[@]}" \
  "${naer_args[@]}" \
  "${note_args[@]}"
