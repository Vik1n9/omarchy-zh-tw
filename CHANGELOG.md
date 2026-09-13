# 更新記錄

## 未發行

- 對照 omacom/omarchy `quattro` 與 v4.0.3，補上截圖選取層快捷鍵、強制入口網站、時鐘格式提示、全螢幕桌面切換，以及 Claude／ChatGPT／Grok 桌面版移除選單的譯名。
- 清除殘留的大陸用語與 OpenCC 過度轉換，共 13 處介面與文件字串：封包遺失率、銷毀、儲存庫、上一則通知、預安裝軟體、相符、歷程記錄、如需說明、不需、視需要。
- 測試輸出的結語更正為「檢查通過」；原本的「透過」是簡體原文機械轉換後的誤譯，只能用於 via／through。
- 異體字統一：「臺」一律改用「台」。
- 修正 `tests/terminology.sh`：`git grep -P` 缺少 `(*UTF)` 導致整份術語檢查靜默跳過；ripgrep 後備改以 `\p{Han}` 選檔，涵蓋無副檔名的腳本。
- `tests/terminology.sh` 從禁用詞移除「通過」（它是檢查結果的正確用詞），並補上本次確認的大陸用語與誤轉詞；未安裝 opencc 時改為失敗，需 `ALLOW_MISSING_OPENCC=1` 才略過。
- `docs/glossary.md` 補上本次查照的詞條與一對多異體字的取用原則。
- uninstall 改採「解除安裝」（台灣微軟與樂詞網一致），禁用詞清單同步移除該詞。
- threshold 的通用譯名改採 GNOME 的「臨界值」；電池面板的 `Threshold` 仍依語境作「充電保護」。
- hook 改採微軟的「勾點」（原用的「掛鉤」各來源皆未收），同步更新整合檢查的斷言。
- DNS 正文改採微軟的「網域名稱服務」；介面仍保留 `DNS`。
- 翻譯政策改為四層順位：GNOME／KDE 的 zh-TW 社群定論 → 台灣微軟 → 樂詞網《電子計算機名詞》→ 特別翻譯或保留原文；並註明 `support.microsoft.com` 部分頁面為機器翻譯。
- 新增 `scripts/naer-lookup.sh` 查詢樂詞網《電子計算機名詞》，補上第三順位的查照工具。
- `tests/terminology.sh` 的異體字正規化補上「纔／才」，避免把正確的「才」誤報為簡體字。
- 新增 `scripts/build-termbase.sh`、`scripts/termbase_build.py`、`scripts/term-lookup.sh` 與 `scripts/termbase_query.py`：從 GNOME、KDE、台灣微軟術語集與樂詞網建立可查詢的譯名詞庫，GNOME／KDE 的譯名附上「模組:原始 msgid」出處，避免憑印象造詞或誤判語境。
- 新增 `scripts/audit-glossary.sh` 與 `scripts/audit_glossary.py`：核對詞彙表有哪些採用譯名沒有來源支持，比對一律精確、不自動補複數。
- 新增 `docs/terms-local.json` 自訂詞庫（第五順位，隨儲存庫版控）：收錄四來源查不到或語境不合而自訂的譯名與理由，避免已定案的詞每次稽核都被當成漏網詞。
- 於詞彙表註明 menu、shortcut、account 三項刻意沿用 Linux 桌面慣例而非微軟用語的理由。

## 0.2.0 - 2026-09-11

- 由 [QueedWen/omarchy-zh-cn](https://github.com/QueedWen/omarchy-zh-cn) 衍生，轉換為台灣繁體中文（zh-TW）。
- 全面更名為 `omarchy-zh-tw`：同步指令、更新指令、勾點、資料目錄、manifest 鍵 `zhTwManaged` 與選單標記。
- 依現代台灣桌面慣例重譯全部介面字串，並以 IICM 電腦名詞譯名表查照。
- Qt 地區改為 `zh_TW`，星期顯示為週一至週日，日期格式為 `yyyy年M月`。
- 顯示引號改為台灣慣用的「」，移除不必要的引號。
- 顯示器面板亮度分級以太陽一天的行程命名：日正當中、豔陽高照、午後斜陽、天光明亮、夕陽餘暉、華燈初上、燭光微弱、夜深人靜。
- 修正複製版選單的應用程式清單為空：clone 取不到 shell 的 appLibrary 時，改用本地 AppLibrary 後備。
- 新增 `docs/glossary.md` 詞彙表、`scripts/iicm-lookup.sh` 查表工具與 `tests/terminology.sh` 術語檢查。
- 沿用並轉換 Agents 狀態列擴充：Grok Build 與 Kimi Code 用量、主題淺色／深色圖示、新版 Codex CLI 核准策略相容。
- 更新 `docs/system-setup.md`：`zh_TW.UTF-8` 地區設定、`libreoffice-fresh-zh-tw` 與 `man-pages-zh_tw` 語言套件。

## 0.1.0 - 2026-08-20（簡體中文版原始記錄）

- 首次公開版本。
- 本地化 22 個 Omarchy 4 使用者外掛複製。
- 本地化主選單、快捷鍵面板和 Omarchy 動態通知。
- 日期與星期使用 `zh_CN` 地區格式。
- 天氣預設使用攝氏和 `km/h`。
- 增加安裝、解除安裝、更新後同步和靜態檢查指令碼。
