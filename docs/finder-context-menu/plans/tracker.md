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
- ✅ 签名打通（root cause：team id 用错；正确 `7T3GCLP6RW`，见 runbook）

### 阶段 1 — 共享纯逻辑（TDD） ✅
- ✅ `Config` model + loader、`PathUtils`、`FileName` 重名加序号、`ActionURL` 编解码
- ✅ 单测 18 个全绿（`xcodebuild test -scheme SharedTests`）

### 阶段 2 — 菜单构建（扩展） 🟡
- ✅ `MenuBuilder`：按 menuKind + config 生成 NSMenu（新建/打开/跳转/复制/移动复制到/用App打开）
- ✅ 复制路径 / 复制名称（扩展内直接写剪贴板）
- ✅ 其余动作编码为 superright:// URL 并 open
- 🟡 **Finder 右键菜单实际渲染待人工验证**（脚本无法触发 Finder 上下文菜单）

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

### 阶段 5（MVP 后，非目标） ⬜
图形设置界面、Office 模板、文件夹图标、工具箱等。

## 下一步动作
→ **唯一待办：用户在 Finder 里右键人工验证菜单**（空白处 + 选中文件）。通过即 MVP 闭环。
→ 之后可选：面向用户的 README、图形设置界面、Office 模板等（阶段 5）。

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
- 🟡 Provisioning profile 7 天到期，需周期性重新构建续期（个人 team 限制）。
