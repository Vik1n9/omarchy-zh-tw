# 詞彙表與翻譯政策

本表是 `omarchy-zh-tw` 的譯名依據。貢獻翻譯前請先查閱；新增或變更詞彙時，請一併更新本表。

## 政策

譯名依下列順位決定，前一層有定論就不再往下查：

1. **GNOME／KDE 的 zh-TW 社群定論**。Linux 桌面既有的在地化用語優先，同時參考 Arch Wiki zh-TW。
2. **台灣微軟**。桌面社群沒有定論時，比對台灣微軟的在地化用語，來源以產品介面與人工在地化頁面為準（Windows／Microsoft 365 的 zh-TW 介面、`support.microsoft.com/zh-tw`）。
   - `support.microsoft.com` 有部分頁面是機器翻譯，同一站內會出現「功能表／選單」「快速鍵／快捷鍵」並存；引用前先確認該頁是人工在地化內容。
3. **樂詞網**。前兩層都沒有依據時，採國家教育研究院樂詞網《電子計算機名詞》的譯名；中華民國資訊學會 IICM 電腦名詞譯名表作為補充對照。
4. **特別翻譯或保留原文**。以上都不適用時另行決定譯法，或保留原文，並在本表「備註」記錄理由。

其他規則：

- 名詞審譯來源的條目偏舊、語境不合或資料異常時，採用上位順位的用語，並在「備註」記錄理由。
- 上位順位與下位順位衝突時，於「備註」寫明差異，避免日後被誤認為疏漏（見 menu、shortcut、account 三列）。
- 產品名稱、指令、真實路徑與第三方內容一律保持原文。
- 新增或變更詞彙時，一併更新本表。

查表工具：

| 工具 | 來源 | 預設路徑 | 覆寫 |
| --- | --- | --- | --- |
| `scripts/naer-lookup.sh <英文詞彙>` | 樂詞網《電子計算機名詞》JSON | `$HOME/Documents/電子計算機名詞.json` | `NAER_TERMS_JSON` |
| `scripts/iicm-lookup.sh <英文詞彙>` | IICM 電腦名詞譯名表（78,396 筆） | `$HOME/Documents/iicm-computer-terms` | `IICM_TERMS_DIR` |

## 標點

- 全形標點：，。！？：；、。
- 顯示引號：`「」`，巢狀 `『』`；不使用 `“”` 或 `‘’`。程式碼語法中的 `"` 不在規範內。
- 能不使用引號就不使用；系統介面少見引號。

## 採用譯名

| 原文 | 採用譯名 | 名詞審譯條目 | 備註 |
| --- | --- | --- | --- |
| network | 網路 | 網路 | 一致 |
| software / hardware | 軟體／硬體 | 軟體／硬體 | 一致 |
| file / document | 檔案／文件 | 檔案／文件 | 一致 |
| folder / directory | 資料夾／目錄 | 文件庫；卷宗／目錄 | IICM「文件庫；卷宗」偏舊，依現代慣例 |
| memory / disk | 記憶體／磁碟 | 記憶體／磁碟 | 一致 |
| cache | 快取 | 高速緩衝記憶體；快取 | 採「快取」 |
| default / setting | 預設／設定 | 預設；內定／設定 | 一致 |
| search / find | 搜尋／尋找 | 搜尋；搜索／尋找 | 一致 |
| update / upgrade | 更新／升級 | 更新／升級 | 一致 |
| install | 安裝 | 安裝 | 一致 |
| uninstall | 卸載 | 卸載 | 一致；與 Remove「移除」區分 |
| remove | 移除 | （無獨立條目） | 與 Uninstall「卸載」區分 |
| package | 套件 | 套裝軟體；程式包 | Arch 社群慣例 |
| repository | 儲存庫 | 儲存庫 | 一致 |
| snapshot / restore | 快照／還原 | 快照／復原 | 一致 |
| migration | 遷移 | 遷移 | 一致 |
| workspace / window | 工作區／視窗 | 工作區／視窗 | 一致 |
| panel / bar | 面板／列 | 面板／條；帶 | 一致 |
| notification | 通知 | 通知 | 一致 |
| reminder | 提醒 | 提醒項目 | 一致 |
| temperature / humidity | 溫度／濕度 | 溫度／濕度 | 一致 |
| font / cursor | 字型／游標 | 字型／游標 | 一致 |
| IP address | IP 位址 | IP 位址 | 一致 |
| gateway | 閘道器 | 閘道器；閘道 | 一致 |
| upload / download | 上傳／下載 | 上傳／下載 | 一致 |
| microphone | 麥克風 | 麥克風 | 一致 |
| kernel | 核心 | 核心 | 一致 |
| terminal | 終端機 | 終端機 | 一致 |
| copy / cut / paste | 複製／剪下／貼上 | 複製／切割／（見 cut and paste 剪貼） | 依桌面慣例 |
| orphan | 孤兒 | 孤兒 | 一致 |
| reset / conflict | 重設／衝突 | 重設；重新開始；重置／衝突 | 一致 |
| signature | 簽章 | 簽章分析 | 軟體簽章語境 |
| account / user | 帳號／使用者 | 帳戶／用戶；使用者 | 依桌面慣例；台灣微軟作「帳戶」 |
| authentication | 驗證／認證 | 鑑別；鑑定 | 依桌面慣例 |
| authorization | 授權 | 授權 | 一致 |
| performance | 效能 | 性能；效能 | 採「效能」 |
| adapter / device | 配接器／裝置 | 配接器；附加卡／裝置；設備 | 一致 |
| provider | 供應商 | 供應者 | 依桌面慣例 |
| menu | 選單 | 菜單；功能表；選單 | 依 GNOME／KDE；台灣微軟作「功能表」，Linux 桌面採「選單」 |
| clipboard | 剪貼簿 | 剪輯板 | 依現代桌面慣例 |
| audio | 音訊 | 聲頻 | 依現代桌面慣例 |
| video | 影片／視訊 | 視頻（video adapter 作「視訊配接器」） | 依語境與現代慣例 |
| icon | 圖示 | 圖像；圖符 | 依現代桌面慣例 |
| system tray | 系統匣 | 系統托盤（tray 作「托盤」） | GNOME 與台灣微軟皆作「系統匣」，順位高於樂詞網 |
| reboot / restart | 重新啟動 | 再啟動 | 依現代桌面慣例 |
| refresh | 重新整理 | 再新；重清；復新 | 依現代桌面慣例 |
| time-out | 逾時 | 暫停；時間超出 | 依現代桌面慣例 |
| layout | 版面配置 | 布局；布置 | 依 MS／GNOME |
| stream | 串流 | 流 | 多媒體語境 |
| theme | 主題 | 文題（疑為資料錯誤） | 依現代慣例 |
| shortcut / keybinding | 快捷鍵 | （accelerator key 作「加速鍵」） | 依現代桌面慣例；台灣微軟作「鍵盤快速鍵」 |
| screenshot | 截圖／螢幕擷取 | （無直接條目） | 依現代慣例 |
| passphrase | 密語 | 通行片語 | 依現代慣例 |
| token / credential | 權杖／憑證 | 符記；訊標／身份碼 | 依現代慣例 |
| threshold | 閾值 | 定限 | 依現代慣例 |
| hook | 掛鉤 | 鉤 | 軟體語境 |
| OCR | 光學字元辨識 | 光學字元閱讀機 | 一致 |
| Wi-Fi / Bluetooth | 無線網路／藍牙 | （無條目） | — |
| screensaver / wallpaper | 螢幕保護程式／桌布 | （無條目） | 依 MS zh-TW |
| plugin / widget | 外掛／小工具 | plug-in 作「插入」（語境不合） | 依 GNOME／MS |
| emoji / dictation | 表情符號／聽寫 | （無條目） | — |
| DNS | DNS（正文：領域名稱服務） | 領域名稱服務 | 介面保留 DNS |
| crash | 當機 | （無直接條目） | 依現代慣例 |
| extension | 擴充功能 | 擴充 | 台灣微軟（Edge）與 GNOME 皆作「擴充功能」；「擴充套件」是簡轉繁的轉換產物 |
| packet loss | 封包遺失率 | （無條目） | 「丟包」為大陸用語 |
| destroy | 銷毀 | 銷毀 | 「銷燬」是 OpenCC s2twp 的過度轉換產物 |
| pass（檢查結果） | 通過 | 傳遞；通過 | 檢查結果用「通過」；「透過」只能用於 via／through |
| match | 相符／符合 | 匹配；相配；符合 | 介面採「相符」，避免大陸慣用的「匹配」 |
| history | 歷程記錄 | 歷史記錄 | 偏離舊譯，依 GNOME／MS zh-TW |
| help | 說明 | 求助 | 介面採「說明」，不用「幫助」 |
| preinstalled | 內建 | （無條目；bundled software 作「附隨軟體」） | 「預裝」為大陸簡稱 |
| color picker | 取色器 | （無條目） | 沿用本專案既有譯名 |
| list | 列表 | 表列；清單；串列 | 沿用本專案既有譯名 |

## 一對多異體字

轉碼工具會把下列字過度轉換，本專案一律採左欄：

| 採用 | 不採用 | 語境 |
| --- | --- | --- |
| 台 | 臺 | 台灣、每台裝置 |
| 准 | 準 | 核准（「標準」等仍用「準」） |
| 游 | 遊 | 上游、游標（「遊戲」仍用「遊」） |
| 群 | 羣 | 社群 |
| 毀 | 燬 | 銷毀 |
| 才 | 纔 | 最後才是…… |

`tests/terminology.sh` 的 `normalize_stream` 會先正規化這些字再比對，避免誤報為簡體字。
