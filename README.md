# SuperRight

一个自建的 macOS Finder 右键增强工具，替代收费的「超级右键」。基于 Apple 官方 **FinderSync** 扩展，菜单项直接出现在右键顶层，由一份 `config.json` 驱动。

> 个人自用 / 自行构建。免费 Apple ID 即可签名运行（有 7 天有效期限制，见[已知限制](#已知限制)）。

## 功能

右键**文件夹空白处**：

- **新建文件** ▸ 纯文本类型（txt/md/json/sh…）或自定义名称（重名自动加序号）
- **在此打开** ▸ 用终端 / Warp / 编辑器等打开当前目录
- **跳转到** ▸ 在 Finder 打开常用目录
- **复制当前路径**

右键**选中的文件**：

- **复制路径** / **复制名称**
- **移动到** ▸ / **复制到** ▸ 常用目标（非破坏式，冲突自动加序号）
- **用 App 打开** ▸ （终端类 App 会自动进入文件所在目录）

列表项（常用目录、发送目标、打开的 App、新建类型）全部来自配置文件，随手增删。

## 架构

```
SuperRight.app（主程序，非沙盒，菜单栏图标常驻）
 ├─ FinderExt.appex（FinderSync 扩展，沙盒）── 弹菜单 + 捕获点击
 └─ App Group 共享容器 ── config.json，两端共读
```

- 扩展沙盒受限，**轻动作就地做**（复制路径写剪贴板），**重动作打包成 `superright://` URL** 交给非沙盒主程序执行真正的文件操作 / 启动 App。
- 菜单项用 `tag` 标识派发（FinderSync 会丢弃 `representedObject`，这是关键坑）。
- 纯逻辑（配置解析、URL 编解码、重名加序号、路径处理）抽成共享模块并有单元测试。

详见 [`docs/`](docs/finder-context-menu/)（设计、调研、踩坑、tracker）。

## 系统要求

- macOS 14+（开发机为 macOS 26 / Apple Silicon 实测）
- 完整版 **Xcode**（不能只装 Command Line Tools，FinderSync 扩展打包需要）
- [XcodeGen](https://github.com/yonyz/XcodeGen)：`brew install xcodegen`

## 构建与安装

1. **登录 Apple ID 并生成首个 profile**（一次性，需 GUI）：
   - `xcodegen generate` 生成 `SuperRight.xcodeproj` 并打开
   - Xcode → Settings → Accounts 登录 Apple ID（免费个人即可）
   - 给 `SuperRight` 和 `FinderExt` 两个 target 各在 Signing & Capabilities 里选一次你的 *(Personal Team)*

2. **填写本地签名配置**：
   ```bash
   cp Local.xcconfig.example Local.xcconfig
   # 编辑 Local.xcconfig，填入你的 Team ID（profile 的 TeamIdentifier，不是证书 OU！）
   # 查 Team ID：
   security cms -D -i ~/Library/Developer/Xcode/UserData/Provisioning\ Profiles/*.provisionprofile \
     | plutil -extract TeamIdentifier.0 raw -
   ```

3. **一键构建 + 安装 + 启用**：
   ```bash
   bash scripts/build-install.sh
   ```
   它会：生成工程 → 构建 → 安装到 `/Applications` → 启动主程序 → 启用 Finder 扩展 → 重启 Finder。

4. **授权**（首次）：
   - 「系统设置 → 登录项与扩展 → Finder 扩展」勾选 **SuperRight**（脚本已尝试自动启用）
   - 「系统设置 → 隐私与安全性 → 完全磁盘访问权限」加入 **SuperRight.app**（否则操作受保护目录会反复弹隐私窗）

## 配置

文件位置：`~/Library/Group Containers/group.com.cola.SuperRight/config.json`
（也可从菜单栏图标 → 打开配置文件）。**存盘即时生效**，无需重启 Finder。

```json
{
  "scope": "/",
  "newFileTypes": [{ "name": "Markdown", "ext": "md" }],
  "favoriteDirs":  [{ "name": "下载", "path": "~/Downloads" }],
  "sendTargets":   [{ "name": "项目", "path": "~/projects" }],
  "openApps": [
    { "name": "终端", "bundleId": "com.apple.Terminal" },
    { "name": "Antigravity", "bundleId": "com.google.antigravity-ide" }
  ]
}
```

- 路径支持 `~`。App 可用 `bundleId` 或 `path` 定位。
- 配置缺失/损坏时回退内置默认，菜单不会变空。

## 菜单栏图标

主程序无 Dock 图标（后台代理）。菜单栏的 SuperRight 图标提供：**重启 / 打开配置 / 在 Finder 显示配置 / 退出**。

## 已知限制

- **免费个人 team 的 provisioning profile 仅 7 天有效**。过期后扩展可能失效，重跑 `bash scripts/build-install.sh` 续期（必要时先在 Xcode 里 ⌘B 刷新一次 profile）。加入付费开发者计划可避免。
- 需要「完全磁盘访问权限」才能顺畅操作受保护目录——这是非沙盒工具的通用代价，「超级右键」同样如此。

## 开发

```bash
# 单元测试（纯逻辑）
xcodebuild test -project SuperRight.xcodeproj -scheme SharedTests \
  -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO
```

## 许可证

[Apache-2.0](LICENSE)
