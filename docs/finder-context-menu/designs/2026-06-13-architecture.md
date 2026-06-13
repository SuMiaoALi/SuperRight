# SuperRight 架构设计

> 状态：✅ 已与用户确认方向（2026-06-13 brainstorming）
> 这是本 feature 的"为什么这么做"事实来源。

## 目标

自建一个 macOS Finder 右键增强工具，替代收费的"超级右键"，覆盖个人日常高频功能。个人使用，自签构建，不追求 App Store 上架。

## MVP 功能范围

| # | 功能 | 触发场景 |
|---|------|---------|
| 1 | 新建文件（纯文本类 + 自定义名称） | 文件夹空白处 |
| 2 | 移动到 / 复制到（共用 sendTargets 列表） | 选中文件 |
| 3 | 常用目录快速跳转（在 Finder 打开） | 空白处 / 选中文件 |
| 4 | 复制路径 / 复制名称 | 选中文件 / 空白处 |
| 5 | 在 App 中打开当前目录（终端、Antigravity 等） | 空白处 |

**非目标（MVP 之后）**：Office 模板新建、模板目录扫描、图形设置界面、文件夹图标修改、压缩/格式转换等工具箱功能。

## 架构：双 target + App Group 共享配置

```
SuperRight.app（主程序，非沙盒）
 ├─ Finder 扩展（FinderSync，沙盒）── 只负责"弹菜单 + 捕获动作"
 └─ App Group 共享容器 ── 放 config.json，扩展与主程序都读
```

### Finder 扩展（FinderSync，沙盒）
- 注册 `scope`（默认 `/`，对应超级右键"使用范围：系统磁盘"）为受监控目录。
- `menu(for:menuKind)` 按右键场景动态生成 `NSMenu`，菜单项从 config.json 读。
- 菜单项点击：
  - **轻动作就地完成**：复制路径 / 复制名称 → 直接写 `NSPasteboard`（扩展自身就有选中项的路径，无需绕主程序）。
  - **重动作打包成 `superright://` URL**，调 `NSWorkspace.open` 交给主程序执行。

### 主程序（普通 .app，非沙盒）
- 注册 `superright://` 自定义 URL 协议。
- `application(_:open:)` 收到命令 → `CommandHandler` 分发 → `FileOps` / `AppLauncher` 真正干活。
- 非沙盒 ⇒ 拥有完整用户文件权限；个别受系统保护目录需用户授"完全磁盘访问权限"（对齐超级右键的"权限"区）。
- 首次启动写默认 config.json。
- 后期：挂图形设置界面。

### 为什么这样分
FinderSync 扩展是沙盒进程，直接在扩展里启动终端 App、移动文件到任意目录会被沙盒拦截。主程序非沙盒不受限。`superright://` 自定义协议是扩展→主程序最轻量的 IPC，无需引入 XPC / mach service。

## 菜单按右键场景分发

| 场景（menuKind） | 菜单项 |
|---|---|
| 空白处 `contextualMenuForContainer` | 新建文件 ▸ [类型列表 + 自定义]、在 App 中打开此处 ▸、跳到常用目录 ▸、复制当前路径 |
| 选中文件 `contextualMenuForItems` | 复制路径 / 复制名称、移动到 ▸ [目标]、复制到 ▸ [目标]、用 App 打开 ▸ |

"移动到"和"复制到"是两个并列子菜单，共用同一份 `sendTargets`。

## 配置文件 config.json（App Group 容器内，手改，预留 GUI）

```json
{
  "scope": "/",
  "newFileTypes": [
    {"name": "文本", "ext": "txt"},
    {"name": "Markdown", "ext": "md"},
    {"name": "JSON", "ext": "json"},
    {"name": "Shell 脚本", "ext": "sh"}
  ],
  "favoriteDirs": [
    {"name": "下载", "path": "~/Downloads"},
    {"name": "项目", "path": "~/programs"}
  ],
  "sendTargets": [
    {"name": "项目", "path": "~/programs"}
  ],
  "openApps": [
    {"name": "终端", "bundleId": "com.apple.Terminal"},
    {"name": "Antigravity", "path": "/Applications/Antigravity.app"}
  ]
}
```

- 路径支持 `~` 展开。
- App 既可用 `bundleId` 也可用 `path` 定位。
- 读配置抽成**共享模块**（扩展与主程序共用同一份 model + loader），后期挂 GUI 不返工。

## 模块划分

纯逻辑（走 TDD 单测，是项目可测的核心）：
- `Config` model + loader：JSON 解析、`~` 展开、字段校验、缺省回退。
- `superright://` URL 编码 / 解码。
- 新建文件**重名自动加序号**（`xxx.txt` → `xxx 2.txt`）。
- 路径格式化（多选时换行拼接等）。

薄壳（手动冒烟测，无法易测）：
- FinderSync 菜单回调（`menu(for:)`、`@objc` action）。
- `NSWorkspace` / `FileManager` 这层。

## 错误处理

- 配置缺失 / 损坏 → 扩展回退内置默认菜单，**永不空菜单**；主程序记录日志并重写默认配置。
- 新建重名 → 自动加序号；移动 / 复制目标已存在 → 弹 `NSAlert` 询问覆盖 / 跳过。
- 目标 App 未安装 / 权限不足 → 系统通知提示。
- 受保护目录操作失败（TCC）→ 检测到权限错误，弹窗引导去「系统设置 → 隐私与安全性 → 完全磁盘访问权限」。

## 构建与启用

- Xcode 构建，免费 Apple ID "Sign to Run Locally" 自签即可个人用。
- 首次启动主程序写默认配置。
- 用户去「系统设置 → 登录项与扩展 → Finder 扩展」勾选启用 SuperRight。
- 个别受保护目录需手动授完全磁盘访问权限。
