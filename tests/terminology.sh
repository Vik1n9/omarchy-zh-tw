#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
cd "$ROOT_DIR"

fail=0
report() {
  echo "$*" >&2
  fail=1
}

if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  mapfile -t files < <(git grep -lIP '[\x{4e00}-\x{9fff}]' -- . ':!docs/glossary.md' ':!tests/terminology.sh')
else
  mapfile -t files < <(rg --files -g '*.md' -g '*.sh' -g '*.js' -g '*.json' -g '*.jsonc' -g '*.py' -g '*.lua' \
    | grep -v '^docs/glossary.md$' | grep -v '^tests/terminology.sh$')
fi

((${#files[@]})) || {
  echo "找不到可檢查的中文檔案。" >&2
  exit 1
}

banned=(
  網絡 軟件 硬件 屏幕 鼠標 打印機 視頻 音頻 默認 設置 搜索 文件夾 剪貼板 登錄 賬
  內存 硬盤 緩存 圖標 窗口 菜單 點擊 加載 刷新 重啟 服務器 數據 信息 保存 創建 用戶
  粘貼 剪切 字節 指針 數組 隊列 對象 文檔 光標 網關 激光 打印 自定義 芯片 光驅 優盤
  快捷方式 進程 後台 添加 博客 鏈接 端口 通過 獲取 接口 配置文件 命令行 解除安裝
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

if command -v opencc >/dev/null 2>&1; then
  normalize_stream() {
    sed -e 's/臺/台/g' -e 's/錶/表/g' -e 's/覈/核/g' -e 's/佈/布/g' -e 's/遊/游/g' \
      -e 's/羣/群/g' -e 's/妳/你/g' -e 's/佔/占/g' -e 's/祕/秘/g' -e 's/儘/盡/g' \
      -e 's/着/著/g' -e 's/週/周/g' -e 's/爲/為/g' -e 's/裏/裡/g' -e 's/麽/麼/g' \
      -e 's/啓/啟/g' -e 's/藉/借/g' -e 's/準/准/g'
  }
  for f in "${files[@]}"; do
    if ! cmp -s <(normalize_stream <"$f") <(opencc -c s2t.json <"$f" | normalize_stream); then
      report "發現疑似簡體字：$f"
    fi
  done
else
  echo "略過簡體字檢查：未安裝 opencc。" >&2
fi

rg -Fq 'Qt.locale("zh_TW")' bin/omarchy-zh-tw-sync || report "同步器缺少 zh_TW 地區設定"
rg -Fq '卸載' bin/omarchy-zh-tw-sync || report "同步器缺少「卸載」"
for preferred in 網路 檔案 預設 設定 搜尋 快取 剪貼簿 螢幕 裝置 套件; do
  rg -Fq -- "$preferred" bin/omarchy-zh-tw-sync || report "同步器缺少偏好詞「$preferred」"
done

if ((fail)); then
  echo "術語檢查失敗。" >&2
  exit 1
fi
echo "術語檢查透過。"
