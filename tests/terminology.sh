#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
cd "$ROOT_DIR"

fail=0
report() {
  echo "$*" >&2
  fail=1
}

# git grep 的 -P 需要 (*UTF) 才會把 \x{...} 當成 Unicode 碼位；缺少時會以
# 「character code point value in \x{} is too large」中止，導致整份檢查靜默跳過。
files=()
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  mapfile -t files < <(git grep -lIP '(*UTF)[\x{4e00}-\x{9fff}]' \
    -- . ':!docs/glossary.md' ':!tests/terminology.sh' 2>/dev/null || true)
fi
# 沒有 git 或 git 未編入 PCRE 時改用 ripgrep（依 Unicode 文字屬性，涵蓋無副檔名的腳本）。
if ((${#files[@]} == 0)); then
  mapfile -t files < <(rg -l --hidden \
    -g '!.git' -g '!*.webp' -g '!*.png' -g '!*.jpg' -g '!*.svg' \
    -g '!docs/glossary.md' -g '!tests/terminology.sh' \
    '\p{Han}' . 2>/dev/null | sed 's|^\./||' | sort -u)
fi

((${#files[@]})) || {
  echo "找不到可檢查的中文檔案。" >&2
  exit 1
}

# 簡體字形的大陸用語。
banned=(
  網絡 軟件 硬件 屏幕 鼠標 打印機 視頻 音頻 默認 設置 搜索 文件夾 剪貼板 登錄 賬
  內存 硬盤 緩存 圖標 窗口 菜單 點擊 加載 刷新 重啟 服務器 數據 信息 保存 創建 用戶
  粘貼 剪切 字節 指針 數組 隊列 對象 文檔 光標 網關 激光 打印 自定義 芯片 光驅 優盤
  快捷方式 進程 後台 添加 博客 鏈接 端口 獲取 接口 配置文件 命令行
)
# 轉碼後字形已是繁體、但用詞仍為大陸慣例，或 OpenCC s2twp 的過度轉換產物。
# 「銷燬」「透過」是 销毁／通过 的誤轉；「通過」本身是正確用詞，不列入。
# 「解除安裝」雖然也是轉換結果，但同時是台灣微軟的正式用語，故不禁用。
banned+=(
  銷燬 檢查透過 測試透過 驗證透過
  丟包 倉庫 預裝 匹配 歷史記錄 始終 無需 按需 一條通知
)
for term in "${banned[@]}"; do
  if hits=$(rg -nF --no-heading -- "$term" "${files[@]}" 2>/dev/null) && [[ -n $hits ]]; then
    report "禁用詞「$term」：
$hits"
  fi
done

if punct_hits=$(rg -nF -e '“' -e '”' -e '‘' -e '’' "${files[@]}" 2>/dev/null \
  | grep -v '"No matches for “"' || true) && [[ -n $punct_hits ]]; then
  report "顯示引號請使用「」／『』：
$punct_hits"
fi

if ! command -v opencc >/dev/null 2>&1; then
  if [[ ${ALLOW_MISSING_OPENCC:-0} == 1 ]]; then
    echo "略過簡體字檢查：未安裝 opencc（ALLOW_MISSING_OPENCC=1）。" >&2
  else
    report "未安裝 opencc，無法檢查簡體字；請安裝 opencc，或設 ALLOW_MISSING_OPENCC=1 明確略過。"
  fi
else
  normalize_stream() {
    sed -e 's/臺/台/g' -e 's/錶/表/g' -e 's/覈/核/g' -e 's/佈/布/g' -e 's/遊/游/g' \
      -e 's/羣/群/g' -e 's/妳/你/g' -e 's/佔/占/g' -e 's/祕/秘/g' -e 's/儘/盡/g' \
      -e 's/着/著/g' -e 's/週/周/g' -e 's/爲/為/g' -e 's/裏/裡/g' -e 's/麽/麼/g' \
      -e 's/啓/啟/g' -e 's/藉/借/g' -e 's/準/准/g' -e 's/纔/才/g'
  }
  for f in "${files[@]}"; do
    if ! cmp -s <(normalize_stream <"$f") <(opencc -c s2t.json <"$f" | normalize_stream); then
      report "發現疑似簡體字：$f"
    fi
  done
fi

rg -Fq 'Qt.locale("zh_TW")' bin/omarchy-zh-tw-sync || report "同步器缺少 zh_TW 地區設定"
rg -Fq '解除安裝' bin/omarchy-zh-tw-sync || report "同步器缺少「解除安裝」"
for preferred in 網路 檔案 預設 設定 搜尋 快取 剪貼簿 螢幕 裝置 套件; do
  rg -Fq -- "$preferred" bin/omarchy-zh-tw-sync || report "同步器缺少偏好詞「$preferred」"
done

if ((fail)); then
  echo "術語檢查失敗。" >&2
  exit 1
fi
echo "術語檢查通過。"
