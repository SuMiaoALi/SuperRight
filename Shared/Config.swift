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

/// 全部用户配置。扩展与主程序共用同一份。
struct Config: Codable, Equatable {
    var scope: String                  // FinderSync 监控根目录
    var newFileTypes: [NewFileType]
    var favoriteDirs: [NamedPath]
    var sendTargets: [NamedPath]
    var openApps: [OpenApp]

    /// 内置默认配置：扩展在读不到/读坏配置时回退到它，保证菜单永不为空。
    static let `default` = Config(
        scope: "/",
        newFileTypes: [
            NewFileType(name: "文本", ext: "txt"),
            NewFileType(name: "Markdown", ext: "md"),
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
        ]
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
