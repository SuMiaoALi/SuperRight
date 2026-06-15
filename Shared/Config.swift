import Foundation

/// 新建文件的类型定义（纯文本类）。
struct NewFileType: Codable, Equatable {
    var name: String   // 菜单显示名，如 "Markdown"
    var ext: String    // 扩展名，不含点，如 "md"
}

/// 带名字的路径条目（常用目录 / 发送目标）。
struct NamedPath: Codable, Equatable {
    var name: String
    var path: String   // 支持以 ~ 开头
}

/// 可在其中打开目录/文件的 App。bundleId 与 path 至少有一个。
struct OpenApp: Codable, Equatable {
    var name: String
    var bundleId: String?
    var path: String?
}

/// 文件夹换色预设。
struct FolderColor: Codable, Equatable {
    var name: String
    var hex: String    // "#RRGGBB"
}

/// 各菜单分组显示开关。缺省全开。
struct FeatureToggles: Codable, Equatable {
    var newFile = true
    var transfer = true
    var favorites = true
    var icon = true
    var toolbox = true
    var openWith = true

    init(newFile: Bool = true, transfer: Bool = true, favorites: Bool = true,
         icon: Bool = true, toolbox: Bool = true, openWith: Bool = true) {
        self.newFile = newFile; self.transfer = transfer; self.favorites = favorites
        self.icon = icon; self.toolbox = toolbox; self.openWith = openWith
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        newFile  = try c.decodeIfPresent(Bool.self, forKey: .newFile) ?? true
        transfer = try c.decodeIfPresent(Bool.self, forKey: .transfer) ?? true
        favorites = try c.decodeIfPresent(Bool.self, forKey: .favorites) ?? true
        icon     = try c.decodeIfPresent(Bool.self, forKey: .icon) ?? true
        toolbox  = try c.decodeIfPresent(Bool.self, forKey: .toolbox) ?? true
        openWith = try c.decodeIfPresent(Bool.self, forKey: .openWith) ?? true
    }
}

/// 应用级设置。
struct AppSettings: Codable, Equatable {
    var menuBarIcon = true
    var launchAtLogin = false

    init(menuBarIcon: Bool = true, launchAtLogin: Bool = false) {
        self.menuBarIcon = menuBarIcon; self.launchAtLogin = launchAtLogin
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        menuBarIcon = try c.decodeIfPresent(Bool.self, forKey: .menuBarIcon) ?? true
        launchAtLogin = try c.decodeIfPresent(Bool.self, forKey: .launchAtLogin) ?? false
    }
}

/// 全部用户配置。扩展与主程序共用同一份。
/// 自定义解码：所有字段缺失时回退默认，保证旧配置/部分配置向后兼容。
struct Config: Codable, Equatable {
    var scope: String
    var newFileTypes: [NewFileType]
    var favoriteDirs: [NamedPath]
    var sendTargets: [NamedPath]
    var openApps: [OpenApp]
    var templatesDir: String
    var folderColors: [FolderColor]
    var features: FeatureToggles
    var settings: AppSettings

    init(scope: String, newFileTypes: [NewFileType], favoriteDirs: [NamedPath],
         sendTargets: [NamedPath], openApps: [OpenApp],
         templatesDir: String, folderColors: [FolderColor],
         features: FeatureToggles, settings: AppSettings) {
        self.scope = scope; self.newFileTypes = newFileTypes
        self.favoriteDirs = favoriteDirs; self.sendTargets = sendTargets
        self.openApps = openApps; self.templatesDir = templatesDir
        self.folderColors = folderColors; self.features = features; self.settings = settings
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = Config.default
        scope        = try c.decodeIfPresent(String.self, forKey: .scope) ?? d.scope
        newFileTypes = try c.decodeIfPresent([NewFileType].self, forKey: .newFileTypes) ?? d.newFileTypes
        favoriteDirs = try c.decodeIfPresent([NamedPath].self, forKey: .favoriteDirs) ?? d.favoriteDirs
        sendTargets  = try c.decodeIfPresent([NamedPath].self, forKey: .sendTargets) ?? d.sendTargets
        openApps     = try c.decodeIfPresent([OpenApp].self, forKey: .openApps) ?? d.openApps
        templatesDir = try c.decodeIfPresent(String.self, forKey: .templatesDir) ?? d.templatesDir
        folderColors = try c.decodeIfPresent([FolderColor].self, forKey: .folderColors) ?? d.folderColors
        features     = try c.decodeIfPresent(FeatureToggles.self, forKey: .features) ?? d.features
        settings     = try c.decodeIfPresent(AppSettings.self, forKey: .settings) ?? d.settings
    }

    /// 内置默认配置：扩展在读不到/读坏配置时回退到它，保证菜单永不为空。
    static let `default` = Config(
        scope: "/",
        newFileTypes: [
            NewFileType(name: "文本", ext: "txt"),
            NewFileType(name: "Markdown", ext: "md"),
            NewFileType(name: "RTF 富文本", ext: "rtf"),
            NewFileType(name: "JSON", ext: "json"),
            NewFileType(name: "Shell 脚本", ext: "sh")
        ],
        favoriteDirs: [
            NamedPath(name: "下载", path: "~/Downloads"),
            NamedPath(name: "文稿", path: "~/Documents"),
            NamedPath(name: "桌面", path: "~/Desktop")
        ],
        sendTargets: [
            NamedPath(name: "下载", path: "~/Downloads"),
            NamedPath(name: "文稿", path: "~/Documents")
        ],
        openApps: [
            OpenApp(name: "终端", bundleId: "com.apple.Terminal", path: nil),
            OpenApp(name: "Warp", bundleId: "dev.warp.Warp-Stable", path: nil),
            OpenApp(name: "Antigravity", bundleId: "com.google.antigravity-ide", path: nil)
        ],
        templatesDir: "~/Library/Application Support/SuperRight/Templates",
        folderColors: [
            FolderColor(name: "红", hex: "#FF5A52"),
            FolderColor(name: "橙", hex: "#FF9F0A"),
            FolderColor(name: "黄", hex: "#FFD60A"),
            FolderColor(name: "绿", hex: "#34C759"),
            FolderColor(name: "蓝", hex: "#0A84FF"),
            FolderColor(name: "紫", hex: "#BF5AF2"),
            FolderColor(name: "灰", hex: "#8E8E93")
        ],
        features: FeatureToggles(),
        settings: AppSettings()
    )

    /// 从 JSON 数据解析；失败返回 nil（调用方决定是否回退默认）。纯函数，便于单测。
    static func decode(from data: Data) -> Config? {
        try? JSONDecoder().decode(Config.self, from: data)
    }

    /// 编码为带缩进的 JSON，供写默认配置文件。
    func encoded() -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        return (try? encoder.encode(self)) ?? Data()
    }
}
