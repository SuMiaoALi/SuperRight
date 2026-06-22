#!/bin/bash
# 一步到位的首次安装向导：检查环境 → 生成工程 → 自动填 Team ID → 构建安装 → 提示授权。
# 用法：bash scripts/setup.sh
set -e
cd "$(dirname "$0")/.."
PROF_DIR="$HOME/Library/Developer/Xcode/UserData/Provisioning Profiles"

echo "▶ 检查环境"
if ! xcode-select -p 2>/dev/null | grep -q "Xcode.app"; then
  echo "✗ 需要完整版 Xcode（当前是 Command Line Tools）。装好 Xcode 后执行："
  echo "  sudo xcode-select -s /Applications/Xcode.app && xcodebuild -runFirstLaunch"
  exit 1
fi
command -v xcodegen >/dev/null || { echo "✗ 缺 xcodegen：brew install xcodegen"; exit 1; }

echo "▶ 生成工程"
xcodegen generate >/dev/null

# 自动检测 Team ID（取 SuperRight 的 profile，否则取任意一个的 TeamIdentifier）
detect_team() {
  [ -d "$PROF_DIR" ] || return 1
  local f
  f=$(grep -lr "com.cola.SuperRight" "$PROF_DIR"/*.provisionprofile 2>/dev/null | head -1)
  [ -z "$f" ] && f=$(ls "$PROF_DIR"/*.provisionprofile 2>/dev/null | head -1)
  [ -z "$f" ] && return 1
  security cms -D -i "$f" 2>/dev/null | plutil -extract TeamIdentifier.0 raw - 2>/dev/null
}

if [ ! -f Local.xcconfig ]; then
  TEAM=$(detect_team || true)
  if [ -z "$TEAM" ]; then
    cat <<'TIP'
✗ 还没有可用的签名描述文件。请先做一次性的 GUI 步骤：
  1. open SuperRight.xcodeproj
  2. Xcode → Settings → Accounts 登录你的 Apple ID（免费个人即可）
  3. 选中 SuperRight 和 FinderExt 两个 target，各在 Signing & Capabilities 里
     勾选 Automatically manage signing 并选你的 (Personal Team)
  完成后重新运行：bash scripts/setup.sh
TIP
    exit 1
  fi
  echo "DEVELOPMENT_TEAM = $TEAM" > Local.xcconfig
  echo "▶ 已自动写入 Team ID：$TEAM → Local.xcconfig"
else
  echo "▶ Local.xcconfig 已存在，跳过"
fi

echo "▶ 构建并安装"
bash scripts/build-install.sh

cat <<'DONE'

────────────────────────────────────────
✓ 安装完成！还差两步系统授权（首次）：
  1. 系统设置 → 登录项与扩展 → Finder 扩展 → 勾选 SuperRight
  2. 系统设置 → 隐私与安全性 → 完全磁盘访问权限 → 加入 SuperRight.app
可选：bash scripts/install-autorenew.sh  （自动续签，免每周手动重建）
────────────────────────────────────────
DONE
