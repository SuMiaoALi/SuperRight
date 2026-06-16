#!/bin/bash
# 安装/卸载"自动续签" LaunchAgent：登录时 + 每 5 天重新构建一次，
# 用 -allowProvisioningUpdates 续期免费个人 team 的 7 天 profile。
# 用法：bash scripts/install-autorenew.sh [uninstall]
set -e
REPO="$(cd "$(dirname "$0")/.." && pwd)"
LABEL="com.cola.SuperRight.renew"
PLIST="$HOME/Library/LaunchAgents/$LABEL.plist"

if [ "${1:-}" = "uninstall" ]; then
  launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null || launchctl unload "$PLIST" 2>/dev/null || true
  rm -f "$PLIST"
  echo "✓ 已卸载自动续签。"
  exit 0
fi

mkdir -p "$HOME/Library/LaunchAgents"
cat > "$PLIST" <<PL
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key><string>$LABEL</string>
  <key>ProgramArguments</key>
  <array>
    <string>/bin/bash</string>
    <string>$REPO/scripts/build-install.sh</string>
  </array>
  <key>RunAtLoad</key><true/>
  <key>StartInterval</key><integer>432000</integer>
  <key>StandardOutPath</key><string>/tmp/superright-renew.log</string>
  <key>StandardErrorPath</key><string>/tmp/superright-renew.log</string>
</dict>
</plist>
PL

launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null || true
launchctl bootstrap "gui/$(id -u)" "$PLIST"
echo "✓ 已安装自动续签：登录时 + 每 5 天自动重建续签。日志 /tmp/superright-renew.log"
echo "  卸载：bash scripts/install-autorenew.sh uninstall"
