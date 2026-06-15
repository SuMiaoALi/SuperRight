# SuperRight 实施 Runbook

> 这是"怎么落地和怎么复现"的事实来源。

## 前置（一次性）
- 完整 Xcode（非仅 CLT）：`sudo xcode-select -s /Applications/Xcode.app`
- Xcode 登录 Apple ID（免费个人即可），生成 Personal Team
- 工具：`brew install xcodegen`
- **Team ID 易错点**：用于签名的 Team ID 是 **provisioning profile 里的 TeamIdentifier**（本项目 `7T3GCLP6RW`），不是证书名括号里的 `6PSGXDQ9B5`（那是证书 OU）。
  查 team：`security cms -D -i <profile> | plutil -extract TeamIdentifier.0 raw -`
  profile 在 `~/Library/Developer/Xcode/UserData/Provisioning Profiles/`。

## 构建 + 安装（日常迭代）
一条命令：
```
bash scripts/build-install.sh
```
它做：xcodegen 生成 → xcodebuild 构建 → ditto 安装到 `/Applications` → 启动主程序 → `pluginkit -e use` 启用扩展 → `killall Finder`。

### 签名要点（踩坑结论）
- `project.yml` 用 **Automatic 签名 + 正确 DEVELOPMENT_TEAM**，构建时**不要**加 `-allowProvisioningUpdates`（个人 team 加了会因 CLI 拿不到账号会话报 `No Account for Team`；不加则直接用本地已生成的托管 profile）。
- 手动签名（Manual）对 Xcode 托管 profile 不可用（报 "Xcode managed, but signing settings require manually managed"）。
- 首个托管 profile 必须先在 **Xcode GUI** 里给两个 target 各选一次 Team 才会生成；之后 CLI 复用。

## 单元测试
```
xcodebuild test -project SuperRight.xcodeproj -scheme SharedTests \
  -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO
```
覆盖：Config 解析、PathUtils、FileName 重名加序号、ActionURL 编解码。

## 验证（冒烟）
主程序侧动作可用 `superright://` 直接测（已全部通过）：
```
open "superright://newFile?dir=/tmp/x&ext=txt"           # 新建（重名自动加序号）
open "superright://copyTo?p=/tmp/x/a.txt&dest=/tmp/y"    # 复制到
open "superright://moveTo?p=/tmp/x/a.txt&dest=/tmp/y"    # 移动到
open "superright://openDirWith?dir=/tmp/x&appBundle=com.apple.Terminal"  # 在终端打开
open "superright://revealDir?dir=~%2FDownloads"          # 跳转目录
```
**Finder 右键菜单**无法脚本化验证，需人工：在任意文件夹空白处/选中文件上右键。

## 配置
- 文件：`~/Library/Group Containers/group.com.cola.SuperRight/config.json`（App Group 共享，主程序首启写默认）。
- 改完即时生效（扩展每次构建菜单都重读），无需重启 Finder。
- 字段见 designs/2026-06-13-architecture.md。

## 运维提示
- **Provisioning profile 7 天到期**（个人 team）：到期后菜单/启动可能失效，重跑 `build-install.sh` 即续期（必要时先在 Xcode GUI 构建一次刷新 profile）。
- 扩展没出现：`pluginkit -m -i com.cola.SuperRight.FinderExt` 看是否 `+`（启用）；或「系统设置 → 登录项与扩展 → Finder 扩展」勾选；再 `killall Finder`。
- 完全磁盘访问：操作受保护目录（桌面/文档/下载/外接盘）失败时，去「系统设置 → 隐私与安全性 → 完全磁盘访问权限」给 SuperRight.app 授权。
