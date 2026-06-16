# SuperRight

[English](README.md) ｜ 中文

一个自建的 macOS Finder 右键增强工具，替代收费的「超级右键」。基于 Apple 官方 **FinderSync** 扩展，菜单项直接出现在右键顶层，由一份 `config.json` 驱动。

> 个人自用 / 自行构建。免费 Apple ID 即可签名运行（profile 7 天有效，已内置自动续签，见[已知限制](#已知限制)）。

## 功能

右键**文件夹空白处**：

- **新建文件** ▸ 纯文本类型（txt/md/rtf/json/sh…）、内置 Office 模板（Word/Excel/PPT）、**模板目录**里的任意类型、或自定义名称（重名自动加序号）
- **在此打开** ▸ 用终端 / Warp / 编辑器等打开当前目录
- **跳转到** ▸ 在 Finder 打开常用目录
- **复制当前路径**、**粘贴到此**、**显示/隐藏 隐藏文件**

右键**选中的文件**：

- **复制路径** / **复制名称**
- **移动到** ▸ / **复制到** ▸ 常用目标（非破坏式，冲突自动加序号）
- **用 App 打开** ▸ （终端类 App 会自动进入文件所在目录）
- **文件夹图标** ▸ 换颜色 / 自定义图标 / 拷贝粘贴 / 清除
- **工具箱** ▸ 剪切拷贝、压缩 ZIP / 解压、图片格式转换、生成二维码、文件信息(MD5/SHA256)、创建替身/符号链接、批量重命名、永久删除

**设置界面**（菜单栏图标 → 设置…）：图形化增删改各列表、菜单分组开关、模板文件夹、权限引导、登录自启——无需手改 JSON。配置改动即时生效。

## 架构

```
SuperRight.app（主程序，非沙盒，菜单栏图标常驻）
 ├─ FinderExt.appex（FinderSync 扩展，沙盒）── 弹菜单 + 捕获点击
 └─ App Group 共享容器 ── config.json，两端共读
```

- 扩展沙盒受限，**轻动作就地做**（复制路径写剪贴板），**重动作打包成 `superright://` URL** 交给非沙盒主程序执行真正的文件操作 / 启动 App。
- 菜单项用 `tag` 标识派发（FinderSync 会丢弃 `representedObject`，这是关键坑）。
- 纯逻辑（配置解析、URL 编解码、重名加序号、路径处理）抽成共享模块并有单元测试。

详见 [`docs/`](docs/finder-context-menu/)。

## 系统要求

- macOS 14+
- 完整版 **Xcode**（FinderSync 扩展打包需要，不能只装 CLT）
- [XcodeGen](https://github.com/yonyz/XcodeGen)：`brew install xcodegen`

## 构建与安装

1. **登录 Apple ID 并生成首个 profile**（一次性，需 GUI）：`xcodegen generate` 后打开工程，Xcode → Settings → Accounts 登录免费 Apple ID，给 `SuperRight` 和 `FinderExt` 两个 target 各选一次 *(Personal Team)*。
2. **填本地签名配置**：`cp Local.xcconfig.example Local.xcconfig`，填入 Team ID（取 profile 的 `TeamIdentifier`，不是证书 OU）：
   ```bash
   security cms -D -i ~/Library/Developer/Xcode/UserData/Provisioning\ Profiles/*.provisionprofile | plutil -extract TeamIdentifier.0 raw -
   ```
3. **一键构建安装**：`bash scripts/build-install.sh`
4. **授权**：系统设置启用 Finder 扩展；给 SuperRight.app 完全磁盘访问权限。

## 自动续签（应对 7 天到期）

免费个人 team 的 profile 7 天到期。一条命令装一个 LaunchAgent，登录时 + 每 5 天自动重建续签：

```bash
bash scripts/install-autorenew.sh            # 安装
bash scripts/install-autorenew.sh uninstall  # 卸载
```

菜单栏图标会显示「签名剩 X 天」。付费开发者计划($99/年)可彻底免除到期 + 公证后分发给他人。

## 配置

`~/Library/Group Containers/group.com.cola.SuperRight/config.json`（菜单栏 → 打开配置文件）。存盘即时生效。路径支持 `~`；配置损坏时回退内置默认。

## 已知限制

- **免费个人 team profile 仅 7 天**——已用 LaunchAgent 自动续签缓解；付费号可免除。
- **二进制不可直接分发给他人**：个人 team 签名只在本机有效，他人需自行构建。要分发 `.dmg` 需付费号 + 公证。
- 受保护目录需「完全磁盘访问权限」。

## 开发

```bash
xcodebuild test -project SuperRight.xcodeproj -scheme SharedTests -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO
```

## 许可证

[Apache-2.0](LICENSE)
