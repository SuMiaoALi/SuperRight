#!/bin/bash
# 一键：生成工程 → 构建 → 安装到 /Applications → 启动注册 → 启用扩展 → 重启 Finder
# 用法：bash scripts/build-install.sh
set -e
cd "$(dirname "$0")/.."

EXT_ID="com.cola.SuperRight.FinderExt"
APP_SRC="build/Build/Products/Debug/SuperRight.app"
APP_DST="/Applications/SuperRight.app"

if [ ! -f Local.xcconfig ]; then
  echo "✗ 缺少 Local.xcconfig。请先：cp Local.xcconfig.example Local.xcconfig 并填入你的 Team ID（见 README）。"
  exit 1
fi

echo "▶ 1/6 生成工程 (xcodegen)"
xcodegen generate >/dev/null

echo "▶ 2/6 构建 (xcodebuild, 自动签名 + 自动续签 profile)"
# -allowProvisioningUpdates：正确 team 下可 headless 续期 7 天个人 profile
xcodebuild build -project SuperRight.xcodeproj -scheme SuperRight \
  -configuration Debug -allowProvisioningUpdates -derivedDataPath build 2>&1 | grep -iE "error:|BUILD SUCCEEDED|BUILD FAILED" || true

if [ ! -d "$APP_SRC" ]; then echo "✗ 构建失败，无产物"; exit 1; fi

echo "▶ 3/6 退出旧进程并安装到 /Applications"
osascript -e 'tell application "SuperRight" to quit' 2>/dev/null || true
pkill -x SuperRight 2>/dev/null || true
sleep 1
# 用 ditto 覆盖安装（避免 rm -rf）
ditto "$APP_SRC" "$APP_DST"

echo "▶ 4/6 启动主程序（注册 URL scheme + 扩展 + 写默认配置）"
open "$APP_DST"
sleep 2

echo "▶ 5/6 启用 Finder 扩展"
pluginkit -e use -i "$EXT_ID" || true
pluginkit -m -i "$EXT_ID"

echo "▶ 6/6 重启 Finder 以加载菜单"
killall Finder 2>/dev/null || true

echo "✓ 完成。去任意 Finder 文件夹右键试试。"
