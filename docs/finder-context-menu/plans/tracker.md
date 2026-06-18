# SuperRight 路线图与 Tracker

> 这是本 feature 的"现在做到哪了"事实来源。
> 状态：✅ 完成并验证 / 🟡 进行中或有未关闭风险 / ⬜ 未开始

## 当前目标
完成 MVP：5 类右键功能（新建文件 / 移动复制到 / 常用目录跳转 / 复制路径名 / 在 App 打开当前目录），FinderSync 实现，配置文件驱动。

## 阶段拆分

### 阶段 0 — 技术验证（spike） ✅
- ✅ XcodeGen 生成 App + FinderSync extension + SharedTests 三 target（Shared 源码编进 App/Ext/Tests）
- ✅ 扩展注册 `/`，菜单代码就位（Finder 实际渲染待人工验证，见阶段 2）
- ✅ 扩展点击 → `superright://` → 主程序收到并执行（IPC 打通，app 侧已端到端验证）
- ✅ App Group 在免费个人 team 下可用（config.json 成功写入共享容器，兜底方案不需要）
- ✅ 签名打通（root cause：team id 用错——应取 profile 的 TeamIdentifier 而非证书 OU，见 runbook）

### 阶段 1 — 共享纯逻辑（TDD） ✅
- ✅ `Config` model + loader、`PathUtils`、`FileName` 重名加序号、`ActionURL` 编解码
- ✅ 单测 18 个全绿（`xcodebuild test -scheme SharedTests`）

### 阶段 2 — 菜单构建（扩展） 🟡
- ✅ `MenuBuilder`：按 menuKind + config 生成 NSMenu（新建/打开/跳转/复制/移动复制到/用App打开）
- ✅ 复制路径 / 复制名称（扩展内直接写剪贴板）
- ✅ 其余动作编码为 superright:// URL 并 open
- ✅ **Finder 右键菜单已人工验证通过**（2026-06-15）。修复关键坑：FinderSync 会丢弃菜单项 `representedObject`，改用 `tag` 查表派发。

### 阶段 3 — 主程序动作执行 ✅
- ✅ `CommandHandler` URL 解码分发
- ✅ `FileOps`：新建（重名加序号）、移动、复制（冲突非破坏式加序号）
- ✅ `AppLauncher`：在 App 打开目录/文件、Finder 跳转目录
- ✅ 错误处理：自定义名输入框 + 失败 NSAlert（覆盖改为非破坏式加序号，见决策）
- ✅ **5 类功能 app 侧端到端冒烟全过**（newFile/copyTo/moveTo/openDirWith/revealDir）

### 阶段 4 — 默认配置与启用体验 ✅
- ✅ 首次启动写默认 config.json（已验证落盘到 App Group 容器）
- ✅ runbook + 一键 `scripts/build-install.sh`（构建/安装/启用/重启 Finder）
- 🟡 README（面向用户的安装说明，可后补）

---

## v1.0（对齐超级右键）—— 见 designs/2026-06-15-v1.0-blueprint.md

> 按蓝图一次推完，最后统一测试。每阶段先写纯逻辑单测，再接 app 侧。

### 阶段 5 — 配置 schema 扩展 + 动作契约 ✅
- ✅ Config 增 `templatesDir`/`folderColors`/`features`/`settings`（向后兼容，单测）
- ✅ ActionURL 增全部新动作 + 参数（编解码单测）
- ✅ 菜单 `features` 开关裁剪逻辑
- **验收**：单测绿；旧配置仍可解析。

### 阶段 6 — 新建文件增强 ✅
- ✅ 打包 docx/xlsx/pptx/rtf 最小空白模板资源
- ✅ `TemplateStore` 扫描模板目录 → 动态生成"从模板新建"菜单
- ✅ `newFromTemplate` 动作：拷贝模板到当前目录并重命名（重名加序号）
- **验收**：各类型能新建；丢进模板目录的文件即时出现在菜单。

### 阶段 7 — 文件夹图标 ✅
- ✅ `IconOps`：换色（系统文件夹图标着色）、设自定义图标、拷贝/粘贴图标、清除
- ✅ 菜单「文件夹图标 ▸」分组
- **验收**：文件夹变色/换图标/还原。

### 阶段 8 — 工具箱 ✅
- ✅ 隐藏文件 toggle、二维码、zip/unzip、图片格式转换、文件信息(含 MD5/SHA256)、替身/软链、批量重命名、永久删除（二次确认）
- ✅ 剪切/拷贝标记 + 粘贴到此（`TransferClipboard` 状态）
- ✅ 菜单「工具箱 ▸」分组 + 空白处「粘贴到此」
- ✅ 各纯逻辑单测（重命名规则、文件信息格式化、zip 命令、图片格式映射等）
- **验收**：smoke.sh 跑通所有可脚本化动作。

### 阶段 9 — 设置界面（SwiftUI） ✅
- ✅ `SettingsWindowController` + SwiftUI 视图（通用/列表管理/功能开关/模板目录/权限引导）
- ✅ `ConfigWriter` 原子写回 config.json
- ✅ 菜单栏图标加"设置…"入口
- ✅ 登录自启（SMAppService）开关
- **验收**：GUI 增删改各列表后，右键菜单即时反映。

### 阶段 10 — 统一测试 + 收尾 🟡（待你人工验收）
- ✅ `scripts/smoke.sh` 全动作自测（11/11 通过）
- ⬜ 「人工验收清单」（Finder 菜单逐项 + GUI 操作）
- ✅ README/tracker 更新，提交并推 GitHub
- **验收**：你按清单一次过；全绿则 v1.0 发布。

### 暂缓（v1.1+）
翻译（需外部 API）、截图标注（系统已有）、Pages/Keynote/AI/PSD 内置模板（用模板目录替代）。

---

## v1.1（产品化 / 开源采纳）

### 自动续签兜底 ✅
- ✅ **关键发现**：用正确 team + `-allowProvisioningUpdates`，CLI 可 **headless 续期** 7 天 profile（之前失败是 team id 用错）
- ✅ build-install.sh 加 `-allowProvisioningUpdates`（每次构建即续期）
- ✅ `scripts/install-autorenew.sh`：LaunchAgent 登录时 + 每 5 天自动重建续签
- ✅ 菜单栏显示「签名剩 X 天」（ProfileExpiry 读内嵌 profile 到期日）

### 开源采纳 ✅
- ✅ App 图标（圆角渐变 + 光标符号，整套尺寸，actool 编译进包）
- ✅ 英文 README（README.md 英文主、README.zh-CN.md 中文）；说明个人 team 二进制不可分发
- ✅ UI i18n：L10n（中文为key英文查表，跟随系统+settings.language覆盖），菜单/菜单栏/设置/弹窗/错误全本地化，设置加语言选择器，+6 单测（共39）

### 暂缓
- 付费开发者号 → 公证 dmg（用户暂不付费）
- 操作反馈通知、最近目标目录、批量重命名实时预览（体验项，按需再做）

## 下一步动作
→ v1.0/v1.1 代码全部完成（自动续签+图标+中英双语+英文README），39 单测全绿。剩用户人工验收（见 acceptance-checklist）。

## 决策记录
- 2026-06-13：选 FinderSync 而非 Services/Quick Actions，因核心功能是动态列表，Services 难做。
- 2026-06-13：扩展沙盒、主程序非沙盒，superright:// 自定义协议做 IPC。
- 2026-06-13：配置先用 config.json 手改，读配置抽共享模块，GUI 留后。
- 2026-06-13：新建文件 MVP 仅纯文本类 + 自定义名称，不做 Office 模板。
- 2026-06-15：移动/复制目标冲突改为**非破坏式自动加序号**（而非弹窗覆盖询问），避免误覆盖；体验更顺。
- 2026-06-15：工程改用 XcodeGen（声明式 project.yml），不手写 pbxproj。
- 2026-06-15：构建走 Automatic 签名 + 正确 DEVELOPMENT_TEAM、不带 -allowProvisioningUpdates（个人 team CLI 签名结论，见 runbook）。
- 2026-06-15：终端类 App（Terminal/Warp/iTerm…）"打开文件"无意义，改为自动进入其**所在目录**并去重；editor 类按原路径打开。
- 2026-06-15：加**菜单栏状态图标**（非 Dock）作为后台代理的唯一可见入口，提供 重启/打开配置/显示配置/退出。对齐超级右键"显示菜单栏图标"。
- 2026-06-15：默认 openApps 改为 终端 + Warp + Antigravity（用户实际在用的）。
- 2026-06-15：用户已授"完全磁盘访问权限"，TCC 反复弹窗消除。

## 已知风险 / 暂缓项
- ✅ App Group（免费个人 team）可用，已验证。
- ✅ 沙盒扩展 → superright:// → 主程序 IPC 可用，app 侧已端到端验证。
- 🟡 Finder 右键菜单实际渲染待人工验证（最后一步）。
- ✅ Provisioning profile 7 天到期 → 已用 install-autorenew.sh（登录+每5天）自动续期 + 菜单栏倒计时缓解。
