# 選用：系統繁體中文環境與輸入法

介面安裝器只修改使用者設定，不會自動執行需要管理員權限的系統設定。若系統本身尚未設定繁體中文環境，可按需完成以下步驟。

## 系統地區設定

確認 `/etc/locale.gen` 已啟用：

```text
zh_TW.UTF-8 UTF-8
```

然後在終端機執行：

```bash
sudo locale-gen
sudo localectl set-locale LANG=zh_TW.UTF-8
```

登出並重新登入後檢查：

```bash
localectl status
```

鍵盤配置可以繼續使用 `us`；系統語言和實體鍵盤配置是兩項獨立設定。

## 繁體中文字型

```bash
omarchy pkg add noto-fonts-cjk wqy-microhei wqy-zenhei
```

Noto CJK 作為主要中文字型已經足夠；文泉驛字型用於相容少數舊應用程式。

## 繁體中文輸入法

下面範例使用 Fcitx 5 和 Rime：

```bash
omarchy pkg add fcitx5 fcitx5-configtool fcitx5-gtk fcitx5-qt fcitx5-rime
```

偏好注音輸入的使用者，也可以改用新酷音：

```bash
omarchy pkg add fcitx5-chewing
```

安裝後開啟 `fcitx5-configtool`，把 Rime 或新酷音加入輸入法列表。若 Fcitx 5 沒有自動啟動，可將系統提供的桌面啟動檔案複製到使用者目錄，並確保它沒有被標記為 `Hidden=true`：

```bash
mkdir -p ~/.config/autostart
cp /etc/xdg/autostart/org.fcitx.Fcitx5.desktop ~/.config/autostart/
```

完成後登出並重新登入。不要在不理解影響的情況下同時設定多個輸入法框架。

## 選用語言套件

```bash
omarchy pkg add libreoffice-fresh-zh-tw man-pages-zh_tw
```

瀏覽器和其他應用程式是否提供中文介面取決於對應套件及其自身語言設定，不屬於 Omarchy Shell 繁體化範圍。
