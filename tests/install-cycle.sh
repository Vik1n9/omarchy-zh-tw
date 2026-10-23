#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)

if [[ ! -d /usr/share/omarchy/shell || ! -f /usr/share/omarchy/default/i18n/zh-TW/shell.json ]]; then
  echo "非 Omarchy 4.5 以上環境，跳過安裝週期檢查。"
  exit 0
fi

sandbox_root=$(mktemp -d)
sandbox_home="$sandbox_root/home"
stub_bin="$sandbox_root/bin"
mkdir -p "$sandbox_home" "$stub_bin"
# 測試只能寫沙箱；XDG_CONFIG_HOME 若指向真實目錄，語言檔會寫到使用者的設定裡。
export XDG_CONFIG_HOME="$sandbox_home/.config"

cleanup() {
  [[ -n ${sandbox_root:-} && -d $sandbox_root && $sandbox_root == /tmp/* ]] && rm -rf -- "$sandbox_root"
}
trap cleanup EXIT

cat >"$stub_bin/omarchy" <<'STUB'
#!/usr/bin/env bash
set -euo pipefail

case "${1:-} ${2:-}" in
  "version ")
    echo "4.5.0-test"
    ;;
  "plugin clone")
    source_id=$3
    target_id="${USER}.${source_id#omarchy.}"
    target="$HOME/.config/omarchy/plugins/$target_id"
    mkdir -p "$target"
    jq -n --arg id "$target_id" --arg source "$source_id" \
      '{id: $id, omarchy: {clonedFrom: $source}}' >"$target/manifest.json"
    ;;
  "plugin remove")
    rm -rf -- "$HOME/.config/omarchy/plugins/$3"
    ;;
  "hook install")
    target="$HOME/.config/omarchy/hooks/$3.d/$(basename "$4")"
    mkdir -p "$(dirname "$target")"
    cp "$4" "$target"
    chmod 755 "$target"
    ;;
  "restart shell")
    ;;
  *)
    echo "未處理的 omarchy 測試呼叫：$*" >&2
    exit 1
    ;;
esac
STUB

cat >"$stub_bin/omarchy-shell" <<'STUB'
#!/usr/bin/env bash
exit 0
STUB

cat >"$stub_bin/hyprctl" <<'STUB'
#!/usr/bin/env bash
case "${1:-}" in
  configerrors) exit 0 ;;
  reload) echo ok; exit 0 ;;
esac
exit 0
STUB
chmod 755 "$stub_bin/omarchy" "$stub_bin/omarchy-shell" "$stub_bin/hyprctl"

test_path="$stub_bin:$PATH"

# 模擬 0.2 的安裝：舊工具、舊的更新流程與 Agents 擴充、一個已不需要的受管理複製。
mkdir -p "$sandbox_home/.local/bin" \
  "$sandbox_home/.local/share/omarchy-zh-tw/bin" \
  "$sandbox_home/.local/share/omarchy-zh-tw/agents/bin" \
  "$sandbox_home/.config/omarchy/hooks/post-update.d" \
  "$sandbox_home/.config/omarchy/plugins/testuser.audio"
printf '#!/usr/bin/env bash\necho old-sync\n' >"$sandbox_home/.local/bin/omarchy-zh-tw-sync"
printf '#!/usr/bin/env bash\necho old-keybindings\n' >"$sandbox_home/.local/bin/omarchy-menu-keybindings-zh-tw"
printf '#!/usr/bin/env bash\necho old-update\n' >"$sandbox_home/.local/bin/omarchy-update-zh-tw"
printf '#!/usr/bin/env bash\necho old-update\n' >"$sandbox_home/.local/share/omarchy-zh-tw/bin/omarchy-update"
printf '#!/usr/bin/env bash\necho old-hook\n' >"$sandbox_home/.config/omarchy/hooks/post-update.d/omarchy-zh-tw-post-update"
jq -n '{id: "testuser.audio", omarchy: {clonedFrom: "omarchy.audio", zhTwManaged: true}}' \
  >"$sandbox_home/.config/omarchy/plugins/testuser.audio/manifest.json"
printf 'da\n' >"$sandbox_home/.config/omarchy/language"
cat >"$sandbox_home/.config/omarchy/shell.json" <<'JSON'
{
  "version": 1,
  "bar": {
    "layout": {
      "left": [],
      "center": [{"id": "omarchy.weather", "unit": "imperial"}],
      "right": []
    }
  },
  "plugins": [],
  "disabledPlugins": []
}
JSON

HOME="$sandbox_home" USER=testuser PATH="$test_path" "$ROOT_DIR/install.sh" --dry-run >/dev/null
[[ $(cat "$sandbox_home/.config/omarchy/language") == da ]]

HOME="$sandbox_home" USER=testuser PATH="$test_path" "$ROOT_DIR/install.sh" >/dev/null

test -x "$sandbox_home/.local/bin/omarchy-zh-tw-sync"
test -x "$sandbox_home/.local/bin/omarchy-menu-keybindings-zh-tw"
test -f "$sandbox_home/.local/share/omarchy-zh-tw/i18n/zh-TW/shell.json"
test -f "$sandbox_home/.local/share/omarchy-zh-tw/i18n/keybindings.json"
test -x "$sandbox_home/.config/omarchy/hooks/post-update.d/omarchy-zh-tw-post-update"
test ! -e "$sandbox_home/.local/bin/omarchy-update-zh-tw"
test ! -e "$sandbox_home/.local/share/omarchy-zh-tw/bin"
test ! -e "$sandbox_home/.local/share/omarchy-zh-tw/agents"
test ! -e "$sandbox_home/.config/omarchy/plugins/testuser.audio"
[[ $(cat "$sandbox_home/.config/omarchy/language") == zh-TW ]]
rg -Fq -- '-- >>> omarchy-zh-tw' "$sandbox_home/.config/hypr/bindings.lua"
[[ $(find "$sandbox_home/.config/omarchy/plugins" -mindepth 2 -maxdepth 2 -name manifest.json | wc -l) -eq 9 ]]
[[ $(jq -r '.bar.layout.center[0].unit' "$sandbox_home/.config/omarchy/shell.json") == metric ]]

# 再安裝一次必須是冪等的，且不能把已切換的語言當成原值記下。
HOME="$sandbox_home" USER=testuser PATH="$test_path" "$ROOT_DIR/install.sh" >/dev/null
[[ $(find "$sandbox_home/.config/omarchy/plugins" -mindepth 2 -maxdepth 2 -name manifest.json | wc -l) -eq 9 ]]
[[ $(grep -c -- '-- >>> omarchy-zh-tw' "$sandbox_home/.config/hypr/bindings.lua") -eq 1 ]]

HOME="$sandbox_home" USER=testuser PATH="$test_path" "$ROOT_DIR/uninstall.sh" --yes >/dev/null

rg -Fq 'old-sync' "$sandbox_home/.local/bin/omarchy-zh-tw-sync"
rg -Fq 'old-keybindings' "$sandbox_home/.local/bin/omarchy-menu-keybindings-zh-tw"
rg -Fq 'old-hook' "$sandbox_home/.config/omarchy/hooks/post-update.d/omarchy-zh-tw-post-update"
test ! -e "$sandbox_home/.local/share/omarchy-zh-tw"
test ! -e "$sandbox_home/.config/omarchy/extensions/omarchy-menu.jsonc"
[[ $(find "$sandbox_home/.config/omarchy/plugins" -mindepth 2 -maxdepth 2 -name manifest.json | wc -l) -eq 0 ]]
[[ $(cat "$sandbox_home/.config/omarchy/language") == da ]]
! rg -Fq -- '-- >>> omarchy-zh-tw' "$sandbox_home/.config/hypr/bindings.lua"
[[ $(jq -r '.bar.layout.center[0].unit' "$sandbox_home/.config/omarchy/shell.json") == imperial ]]

echo "隔離安裝與解除安裝週期檢查通過。"
