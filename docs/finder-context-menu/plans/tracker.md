# SuperRight 路线图与 Tracker

> 这是本 feature 的"现在做到哪了"事实来源。
> 状态：✅ 完成并验证 / 🟡 进行中或有未关闭风险 / ⬜ 未开始

## 当前目标
完成 MVP：5 类右键功能（新建文件 / 移动复制到 / 常用目录跳转 / 复制路径名 / 在 App 打开当前目录），FinderSync 实现，配置文件驱动。

## 阶段拆分

### 阶段 0 — 技术验证（spike） ⬜
先打通最不确定的链路，再投入功能开发。逐条更新 research/finder-sync-constraints.md 的 🟡 项。
- ⬜ Xcode 建 App + FinderSync extension + 共享 framework 三 target 骨架
- ⬜ 扩展注册 `/`，空白处 / 选中项右键能弹出最小菜单（写死一项）
- ⬜ 扩展点击 → `superright://test` → 主程序收到并弹通知（打通 IPC）
- ⬜ 确认 App Group 配置可用（免费账号），否则切兜底配置路径
- **验收**：右键能看到自定义项，点击后主程序确实收到命令。

### 阶段 1 — 共享纯逻辑（TDD） ⬜
可独立单测，先于 UI 写。
- ⬜ `Config` model + loader：JSON 解析、`~` 展开、字段校验、缺省回退
- ⬜ `superright://` URL 编码 / 解码
- ⬜ 新建文件重名自动加序号
- ⬜ 路径格式化（多选拼接）
- **验收**：单测全绿。

### 阶段 2 — 菜单构建（扩展） ⬜
- ⬜ `MenuBuilder`：按 menuKind + config 生成 NSMenu
- ⬜ 复制路径 / 复制名称（扩展内直接写剪贴板）
- ⬜ 其余动作编码为 superright:// URL 并 open
- **验收**：各场景菜单项齐全、层级正确。

### 阶段 3 — 主程序动作执行 ⬜
- ⬜ `CommandHandler`：URL 解码分发
- ⬜ `FileOps`：新建文件（含重名处理）、移动、复制
- ⬜ `AppLauncher`：在 App 中打开目录、跳转常用目录到 Finder
- ⬜ 错误处理：NSAlert 覆盖询问、通知提示、权限引导
- **验收**：5 类功能端到端可用。

### 阶段 4 — 默认配置与启用体验 ⬜
- ⬜ 首次启动写默认 config.json
- ⬜ README：构建、签名、启用扩展、授权步骤
- **验收**：干净机器按 README 能装好并用起来。

### 阶段 5（MVP 后，非目标） ⬜
图形设置界面、Office 模板、文件夹图标、工具箱等。

## 下一步动作
→ 阶段 0：搭 Xcode 三 target 骨架，打通"右键弹菜单 → superright:// → 主程序收到"最小链路。

## 决策记录
- 2026-06-13：选 FinderSync 而非 Services/Quick Actions，因核心功能是动态列表，Services 难做。
- 2026-06-13：扩展沙盒、主程序非沙盒，superright:// 自定义协议做 IPC。
- 2026-06-13：配置先用 config.json 手改，读配置抽共享模块，GUI 留后。
- 2026-06-13：新建文件 MVP 仅纯文本类 + 自定义名称，不做 Office 模板。

## 已知风险 / 暂缓项
- 🟡 免费 Apple ID 的 App Group 与扩展签名能力未实测，阶段 0 验证；有兜底配置路径方案。
- 🟡 沙盒扩展打开自定义 URL scheme 的可行性待实测。
