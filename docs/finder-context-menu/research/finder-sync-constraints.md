# FinderSync 关键约束与技术依据

> 这是本 feature 的"依据是什么"事实来源。
> 标 🟡 的项为待实现期实测确认，不可盲信。

## FinderSync 是什么
`FinderSync` 是 Apple 官方为 Finder 增加同步徽标 + **右键上下文菜单**的扩展机制（`FIFinderSync` 子类）。超级右键就是基于它。它是**应用扩展（App Extension）**，运行在 Finder 的扩展宿主里，受沙盒约束。

## 菜单回调
- 扩展通过 `FIFinderSyncController.default().directoryURLs` 注册受监控目录；只有这些目录及其子层右键时才会回调本扩展。注册 `/` 可覆盖整盘（= 超级右键"使用范围：系统磁盘"）。🟡 实测 `/` 是否需要额外权限 / 是否稳定。
- `override func menu(for menuKind: FIMenuKind) -> NSMenu` 返回要插入的菜单。
- `FIMenuKind` 关键值：
  - `.contextualMenuForItems`：右键选中的文件/文件夹。
  - `.contextualMenuForContainer`：右键当前 Finder 窗口背景（空白处）。← 新建文件、在此打开终端用这个。
  - `.contextualMenuForSidebar`、`.toolbarItemMenu`：MVP 不用。
- 拿当前选中项：`FIFinderSyncController.default().selectedItemURLs()`；拿当前目录：`.targetedURL()`。

## 沙盒约束（架构选择的核心依据）
- 扩展是沙盒进程。对 Finder **传进来的 URL**（选中项、目标目录）有访问权，因为是用户操作授予的。
- 但**主动**启动任意 App（终端 / Antigravity）、移动文件到配置里的任意目标目录、打开不在当前上下文的常用目录，会撞沙盒限制。
- 因此设计上：重动作不在扩展里做，打包 `superright://` URL 交给**非沙盒主程序**执行。
- `NSWorkspace.open(url)` 打开自定义 URL scheme：🟡 实测沙盒扩展确实能发起（业界普遍认为打开 URL 是被允许的，但需实测确认 scheme 路由到主程序）。

## App Group 共享配置
- 主程序与扩展加同一个 App Group（如 `group.com.cola.superright`），用 `FileManager.containerURL(forSecurityApplicationGroupIdentifier:)` 拿共享目录，config.json 放这里，两端都能读。
- 主程序首次启动写默认配置。🟡 确认免费个人 Apple ID 能配 App Group（付费开发者账号一定可以；免费账号的 App Group 能力需实测）。
  - 兜底方案：若免费账号 App Group 受限，config.json 改放 `~/Library/Application Support/SuperRight/` 等扩展也能读的固定路径，或改用 `UserDefaults(suiteName:)`。实现期定。

## 主程序权限
- 主程序设为**非沙盒**普通 App ⇒ 拥有用户级文件权限。
- 访问受 TCC 保护的位置（桌面 / 文档 / 下载 / 外接盘等）首次会触发系统授权弹窗；做"完全磁盘访问权限"引导兜底，对齐超级右键的权限区。

## 构建与启用
- Xcode 工程：1 个 App target + 1 个 FinderSync extension target，共享一个 framework target 放纯逻辑。
- 签名：免费 Apple ID "Sign to Run Locally" 个人自用可行。
- 启用：macOS 13+「系统设置 → 登录项与扩展 → 扩展 → Finder 扩展」勾选。
- 调试扩展：把宿主设为 Finder，或 `pluginkit -m` 查看注册状态、`killall Finder` 重载。

## 待验证清单（实现期逐条实测，更新本文件）
- 🟡 注册 `/` 的可行性与权限要求
- 🟡 沙盒扩展 `NSWorkspace.open` 自定义 scheme 是否成功路由到主程序
- ✅ 免费 Apple ID 的 App Group 可用性 —— **可用**。免费个人 team 的 Xcode 自动签名接受 `group.com.cola.SuperRight`，App/扩展两端 App Groups 能力均无报错，兜底方案暂不需要。
- 🟡 `contextualMenuForContainer` 在空白处右键的真实触发表现

## 构建/签名实测结论（2026-06-15）
- 环境：Xcode 26.5（完整版），macOS 26.5 SDK，免费个人 Apple ID。
- **App Group 在免费个人 team 下可用**（见上）。
- **xcodebuild 纯命令行签名对个人 team 走不通**：
  - 自动签名 + `-allowProvisioningUpdates` → `No Account for Team`（CLI 拿不到 Xcode GUI 存的账号会话）。
  - 自动签名不带该 flag → `No profiles found`（不联网就不会用已建 profile）。
  - 手动签名指定 specifier → `No profile matching`（CLI profile 查找路径不一致，复制到 `~/Library/MobileDevice/Provisioning Profiles/` 仍未匹配）。
  - **结论**：构建走 Xcode GUI（`osascript` 驱动 `tell application "Xcode" to build`，已生效的签名上下文）。单测可继续用 `xcodebuild test ... CODE_SIGNING_ALLOWED=NO`。
- **Provisioning profile 7 天到期**（个人 team 限制）：到期后在 Xcode 里重新构建一次即自动续期。位置 `~/Library/Developer/Xcode/UserData/Provisioning Profiles/`。
- 工程用 XcodeGen 从 `project.yml` 生成；改 `project.yml` 后 `xcodegen generate` 重生成，签名设置（Automatic + DEVELOPMENT_TEAM）保留。
