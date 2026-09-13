# Omarchy 繁體中文（台灣）介面

**繁體中文** | [English](README.en.md)

面向 Omarchy 4 的非官方台灣繁體中文本地化專案。它從本機目前安裝的 Omarchy 原始檔產生使用者級外掛複製，不修改 `/usr/share/omarchy`，也不在儲存庫中重新散布 Omarchy 的外掛原始碼。

本專案衍生自 [QueedWen/omarchy-zh-cn](https://github.com/QueedWen/omarchy-zh-cn) 的簡體中文版（MIT 授權），將其翻譯與介面調整為台灣用語（zh-TW）。

## 效果預覽

以下截圖來自實際安裝本專案的 Omarchy 4 桌面。具體桌布、主題和天氣資料會因使用者環境而異。

### 繁體中文主選單

![Omarchy 繁體中文主選單](docs/images/menu.webp)

### 繁體中文快捷鍵面板

![Omarchy 繁體中文快捷鍵面板](docs/images/shortcuts.webp)

### 天氣與日期

| 攝氏、`km/h` 與繁體中文天氣欄位 | 繁體中文日期、月份和星期 |
| --- | --- |
| ![Omarchy 繁體中文天氣面板](docs/images/weather.webp) | ![Omarchy 繁體中文行事曆面板](docs/images/calendar.webp) |

### 顯示器面板

![Omarchy 繁體中文顯示器面板](docs/images/display.webp)

### AI 助理用量狀態列

在官方 Agents 狀態列的基礎上，本專案增加了 Grok Build 與 Kimi Code，並修復新版 Codex CLI 與舊版收集器之間的核准策略相容問題。小工具會依目前 Omarchy 主題自動切換淺色／深色圖示；未登入或沒有有效資料的服務會自動隱藏。

| 服務 | 用量來源 | 啟用方式 |
| --- | --- | --- |
| Codex | Codex app-server 與本機工作階段 | 登入 Codex CLI；相容指令碼不會讀取或複製權杖 |
| Grok | Grok Build 帳戶限額與餘額介面 | 執行 `grok login` |
| Kimi | Kimi Coding Plan 週額度與 5 小時視窗 | 設定 `KIMI_API_KEY`，或使用權限為 `0600` 的設定檔 |

Kimi 設定檔位於 `~/.config/omarchy/agents/kimi.json`：

```json
{
  "apiKey": "你的 API Key",
  "region": "cn"
}
```

`region` 可設為 `cn`（`api.kimi.com`）或 `global`（`api.kimi.ai`）。如果未來 Kimi Code CLI 在 `~/.kimi-code/` 寫入登入資訊，收集器也會自動辨識。憑證僅用於伺服器端用量查詢，不會寫入狀態列讀取的用量 JSON。

## 已繁體中文化內容

- Omarchy 主選單及 300 多個選單項目
- 狀態列、外掛設定和常用面板
- AI 助理狀態列新增 Grok、Kimi，用量限額顯示和隨主題切換的淺色／深色圖示
- 修復新版 Codex CLI 不再接受舊 `untrusted` 核准策略時導致的 `initialize` 錯誤
- 音訊、藍牙、網路、顯示器、電源和天氣
- 日期、月份、星期及行事曆
- 天氣使用攝氏，風速使用 `km/h`，地名保持資料來源原文
- 提醒、通知歷程和 Omarchy 動態通知
- 系統匣、剪貼簿、表情符號、圖片選擇器、測速和 Wi-Fi QR Code
- 偵測到 Fcitx 5/Rime 表情符號註解檔時，為表情符號選擇器補充繁體中文搜尋關鍵字
- 鎖定畫面、權限驗證，以及 Omarchy 更新過程中的快照、套件、遷移、錯誤與重新啟動提示
- `Super + K` 快捷鍵面板及功能說明
- Omarchy 更新後的自動重新同步

專有名稱、指令、真實檔案路徑和第三方應用程式內容不會強制翻譯，例如 Omarchy、Hyprland、Codex、DNS、Docker 和 `Downloads`。

## 相容性

- Omarchy `4.x`
- Node.js、jq、gum（Omarchy 4 預設環境已提供）
- 需要正在執行的 Omarchy Shell

本專案跟隨系統已安裝的外掛結構產生繁體化複製。Omarchy 更新改變介面原始碼時，同步器會重新產生外掛；如果上游結構發生不相容變化，同步會明確失敗並保留上一份可用版本。

## 安裝

### 使用 AI 助理安裝

如果你的 AI 助理能夠在本機讀取檔案並執行終端機指令，可以把下面的提示詞完整發送給它：

```text
請幫我在目前這台 Omarchy 4 系統上安裝這個台灣繁體中文本地化專案：
https://github.com/Vik1n9/omarchy-zh-tw

要求：
1. 先閱讀儲存庫的 README.md 和 install.sh，並檢查目前系統、Omarchy 版本及依賴是否相容。
2. 將儲存庫複製到合適的使用者目錄；如果目標目錄已經存在，不要覆蓋，先檢查現狀。
3. 先執行 ./install.sh --dry-run。只有 dry-run 成功後，才執行 ./install.sh。
4. 不要修改 /usr/share/omarchy，也不要覆蓋現有使用者外掛或個人設定。
5. 如果發現同名外掛複製或其他衝突，立即停止並告訴我具體情況；未經我明確確認，不要使用 --adopt-existing。
6. 任何需要密碼、提權或覆蓋檔案的操作，都要先徵得我的明確確認。
7. 安裝完成後執行專案測試，檢查同步結果和 Hyprland 設定錯誤，並告訴我修改了哪些位置、測試結果以及如何解除安裝。
```

### 手動安裝

```bash
git clone https://github.com/Vik1n9/omarchy-zh-tw.git
cd omarchy-zh-tw
./install.sh --dry-run
./install.sh
```

安裝器會：

1. 檢查 Omarchy 版本和依賴。
2. 使用官方 `omarchy plugin clone` 建立 22 個使用者外掛複製。
3. 安裝本地化同步器並產生繁體中文外掛。
4. 為 Agents 外掛安裝 Codex/Grok/Kimi 用量收集擴充套件及主題圖示。
5. 將天氣單位設為公制。
6. 將 `Super + K` 指向繁體中文快捷鍵面板。
7. 從本機目前版本產生繁體中文更新指令碼，並將 Omarchy 選單和狀態列的系統更新入口接入繁體中文更新流程。
8. 安裝 `post-update` 勾點，以便系統更新後自動同步。

如果你已經有相同使用者名稱和外掛字尾的複製，安裝器會停止，避免覆蓋個人修改。只有確認這些複製就是此前的繁體化版本時，才使用：

```bash
./install.sh --adopt-existing
```

## 手動同步

```bash
omarchy-zh-tw-sync
```

可用引數：

```text
--quiet           僅在失敗時輸出
--no-restart      同步後不重新啟動 Omarchy Shell
--adopt-existing  接管來源相符的現有外掛複製
```

## 系統語言與輸入法

安裝器不會自動修改系統地區設定或安裝套件。需要繁體中文系統地區、字型或 Fcitx 5/Rime 輸入法時，請參閱 [系統中文環境與輸入法](docs/system-setup.md)。

## 解除安裝

```bash
./uninstall.sh
```

解除安裝程式會還原安裝前的選單和更新指令，移除受本專案管理的外掛複製，並還原 `Super + K` 設定。Omarchy 的外掛移除指令和解除安裝程式都會保留帶時間戳的備份，不會直接銷毀使用者設定。

## 修改範圍

專案只寫入以下使用者目錄：

```text
~/.config/omarchy/plugins/
~/.config/omarchy/extensions/omarchy-menu.jsonc
~/.config/omarchy/hooks/post-update.d/
~/.config/omarchy/shell.json
~/.config/hypr/bindings.lua
~/.local/bin/
~/.local/share/omarchy-zh-tw/
~/.local/state/omarchy-zh-tw/
```

`/usr/share/omarchy` 全程維持唯讀。安裝器不會收集或上傳通知歷程、網路資訊、位置、權杖或其他使用者資料。

## 開發與檢查

```bash
./tests/smoke.sh
```

在 Omarchy 機器上，測試還會使用臨時 `HOME` 從系統目前外掛產生一套隔離副本；不會觸碰真實使用者設定。

### 譯名查證

譯名依序取決於 GNOME／KDE 的 zh-TW 社群定論、台灣微軟、樂詞網《電子計算機名詞》，
再來才是本專案自訂或保留原文。決定譯名前請先查詞庫，不要憑印象造詞：

```bash
./scripts/build-termbase.sh          # 從各來源官方端點建立詞庫
./scripts/term-lookup.sh menu        # 依順位列出各來源譯名與出處
./scripts/audit-glossary.sh          # 核對詞彙表有哪些譯名缺乏依據
```

詞庫在執行時下載，不隨本儲存庫散布；查詢結果會標出 GNOME／KDE 的原始 msgid，
供判斷語境是否適用。四個來源都查不到的譯名收錄在 [docs/terms-local.json](docs/terms-local.json)，
每筆都附採用理由。

翻譯詞彙與完整政策請參閱 [docs/glossary.md](docs/glossary.md)；貢獻前請閱讀 [CONTRIBUTING.md](CONTRIBUTING.md)。

## 致謝與宣告

- 感謝 [QueedWen](https://github.com/QueedWen) 建立 [omarchy-zh-cn](https://github.com/QueedWen/omarchy-zh-cn) 簡體中文本地化專案；本專案即由其改作而來（MIT 授權）。
- 向 [DHH](https://github.com/dhh) 與 Omarchy 團隊致意，感謝打造這套美麗、有趣且充滿代理精神的 Linux 發行版。

這是社群專案，與 Omarchy 官方無隸屬關係。本專案的繁體中文（台灣）翻譯與調整由 [Vik1n9](https://github.com/Vik1n9) 協助起頭；Vik1n9 不保證後續維護或更新，歡迎任何人接手或參與維護。

Omarchy 及其原始碼遵循其上游授權條款；本儲存庫只包含本專案編寫的安裝邏輯、同步邏輯和繁體中文翻譯，採用 MIT 授權條款。
