import Foundation

/// 轻量本地化：以中文原文为 key，英文查表，查不到回退中文（缺翻译不会变空白）。
/// 语言跟随系统，可被配置覆盖（settings.language: "system"/"zh"/"en"）。
enum L10n {
    static var override: String?   // nil=跟随系统

    static func apply(_ language: String) {
        override = (language == "zh" || language == "en") ? language : nil
    }

    static var isEnglish: Bool {
        switch override {
        case "en": return true
        case "zh": return false
        default: return !(Locale.preferredLanguages.first ?? "en").hasPrefix("zh")
        }
    }

    static func t(_ s: String) -> String { isEnglish ? (en[s] ?? s) : s }

    static let en: [String: String] = [
        // 菜单
        "新建文件": "New File",
        "自定义名称…": "Custom Name…",
        "在此打开": "Open Here",
        "跳转到": "Go To",
        "复制当前路径": "Copy Current Path",
        "粘贴到此": "Paste Here",
        "显示/隐藏 隐藏文件": "Toggle Hidden Files",
        "复制路径": "Copy Path",
        "复制名称": "Copy Name",
        "移动到": "Move To",
        "复制到": "Copy To",
        "用 App 打开": "Open With",
        "文件夹图标": "Folder Icon",
        "换颜色": "Color",
        "设置自定义图标…": "Set Custom Icon…",
        "拷贝图标": "Copy Icon",
        "粘贴图标": "Paste Icon",
        "清除自定义图标": "Reset Icon",
        "工具箱": "Toolbox",
        "剪切": "Cut",
        "拷贝": "Copy",
        "压缩为 ZIP": "Compress to ZIP",
        "解压": "Unzip",
        "转换图片为": "Convert Image To",
        "生成二维码": "Generate QR Code",
        "文件信息": "File Info",
        "创建替身": "Make Alias",
        "创建符号链接": "Make Symlink",
        "批量重命名…": "Batch Rename…",
        "永久删除…": "Delete Permanently…",
        // 菜单栏
        "设置…": "Settings…",
        "打开配置文件": "Open Config File",
        "在 Finder 中显示配置": "Show Config in Finder",
        "重启 SuperRight": "Restart SuperRight",
        "退出 SuperRight": "Quit SuperRight",
        "签名剩": "Signature:",
        "天": "days left",
        "（建议续签）": " (renew soon)",
        "⚠️ 签名已过期，请续签": "⚠️ Signature expired — renew",
        "签名状态未知": "Signature status unknown",
        // 弹窗
        "输入文件名（可带扩展名）": "Enter file name (extension optional)",
        "创建": "Create",
        "取消": "Cancel",
        "操作失败": "Operation Failed",
        "好": "OK",
        "复制": "Copy",
        "关闭": "Close",
        "选择图标图片": "Choose Icon Image",
        "前缀": "Prefix",
        "后缀": "Suffix",
        "查找": "Find",
        "替换为": "Replace",
        "序号": "Number",
        "起始序号（留空=不加，可写 001 补零）": "Start # (blank = none, e.g. 001 to pad)",
        "重命名": "Rename",
        "永久删除": "Delete Permanently",
        "这些文件将被直接删除，不进废纸篓，无法恢复。": "These files will be deleted directly, bypassing the Trash. This cannot be undone.",
        // 设置
        "通用": "General",
        "列表": "Lists",
        "菜单功能": "Menu",
        "关于": "About",
        "启动与显示": "Startup & Display",
        "显示菜单栏图标": "Show menu-bar icon",
        "登录时自动启动": "Launch at login",
        "使用范围": "Scope",
        "语言": "Language",
        "跟随系统": "System",
        "权限与位置": "Permissions & Locations",
        "打开「完全磁盘访问权限」设置": "Open Full Disk Access settings",
        "打开「登录项与扩展」设置": "Open Login Items & Extensions settings",
        "打开模板文件夹": "Open Templates Folder",
        "右键菜单显示哪些分组": "Which menu groups to show",
        "移动到 / 复制到": "Move / Copy To",
        "跳转到常用目录": "Go to favorites",
        "用 App 打开 / 在此打开": "Open With / Open Here",
        "新建文件类型": "New File Types",
        "常用目录": "Favorite Directories",
        "发送/移动复制目标": "Send / Move-Copy Targets",
        "打开方式 App": "Open-With Apps",
        "名称": "Name",
        "扩展名": "Extension",
        "路径": "Path",
        "选择…": "Choose…",
        "选择 App…": "Choose App…",
        "扫描常用 App": "Scan for Apps",
        "自动发现机器上已装的编辑器/终端/浏览器": "Auto-discover installed editors / terminals / browsers",
        "新类型": "New Type",
        "新目录": "New Folder",
        "新 App": "New App",
        "开源的 macOS 右键增强工具": "Open-source macOS right-click enhancer",
        "配置文件改动即时生效，无需重启 Finder。": "Config changes apply instantly — no Finder restart needed.",
        "SuperRight 设置": "SuperRight Settings",
        // 错误
        "新建文件失败：": "Failed to create file: ",
        "找不到 App：": "App not found: ",
        "颜色值无效：": "Invalid color: ",
        "设置图标失败：": "Failed to set icon: ",
        "无法读取图片：": "Cannot read image: ",
        "清除图标失败：": "Failed to reset icon: ",
        "剪贴板里没有图标/图片": "No icon/image on the clipboard",
        "粘贴图标失败：": "Failed to paste icon: ",
        "无法生成二维码": "Cannot generate QR code",
        "二维码生成失败": "QR generation failed",
        "二维码编码失败": "QR encoding failed",
        "压缩失败：": "Compression failed: ",
        "解压失败：": "Extraction failed: ",
        "无法创建目标：": "Cannot create target: ",
        "转换失败：": "Conversion failed: ",
        "没有选中文件": "No files selected",
        "没有已剪切/拷贝的文件": "Nothing has been cut/copied",
        // 文件名 / 创建项默认名
        "未命名": "Untitled",
        "归档": "Archive",
        "替身": "alias",
        "链接": "link",
        // 文件信息标签
        "名称：": "Name: ",
        "路径：": "Path: ",
        "类型：": "Type: ",
        "文件夹": "Folder",
        "文件": "File",
        "大小：": "Size: ",
        "创建：": "Created: ",
        "修改：": "Modified: ",
        "权限：": "Permissions: ",
    ]
}

/// 全局快捷函数。
func L(_ s: String) -> String { L10n.t(s) }
