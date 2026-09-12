# Omarchy 繁體中文版 Agents 用量擴充功能

此目錄由 `omarchy-zh-tw` 同步器疊加到系統內建的 Agents 外掛，不複製或替換上游 QML 原始碼。

新增內容：

- Grok Build：讀取 `~/.grok/auth.json` 中現有登入，透過 Grok CLI 的用量介面顯示週期限額與預付餘額。
- Kimi Code：透過 `KIMI_API_KEY`、權限為 `0600` 的 `~/.config/omarchy/agents/kimi.json`，或 Kimi Code CLI 登入後讀取 Coding Plan 配額。
- Codex 相容層：把已棄用的 `untrusted` 核准值轉換為目前 CLI 接受的值，並為 app-server 初始化留出更合理的等待時間。
- Grok/Kimi 淺色與深色主題圖示。

未設定或登入失效的服務只會產生不可用記錄，Agents 外掛會將其隱藏。存取權杖不會寫入 `~/.local/state/omarchy/agents/usage/` 的顯示資料。

Kimi 設定範例：

```json
{
  "apiKey": "...",
  "region": "cn"
}
```

`region` 支援 `cn` 與 `global`。請執行 `chmod 600 ~/.config/omarchy/agents/kimi.json`，否則收集器會拒絕讀取其中的憑證。

圖示來源與授權可見 `assets/NOTICE.md`。
