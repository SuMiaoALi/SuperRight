import Foundation

/// 配置的持久化层。config.json 放在 App Group 共享容器，扩展与主程序都读。
/// 若 App Group 不可用（如免费个人 team 受限），回退到固定的 Application Support 路径——
/// 主程序仍可读写；扩展沙盒读不到该路径时由 Config.default 兜底，菜单不至于空。
enum ConfigStore {
    static let appGroupID = "group.com.cola.SuperRight"

    /// 共享配置文件 URL；优先 App Group，失败回退 Application Support。
    static var configURL: URL? {
        let fm = FileManager.default
        if let container = fm.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) {
            return container.appendingPathComponent("config.json")
        }
        if let appSupport = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            let dir = appSupport.appendingPathComponent("SuperRight", isDirectory: true)
            return dir.appendingPathComponent("config.json")
        }
        return nil
    }

    /// 读配置；读不到或解析失败回退到 Config.default。
    static func load() -> Config {
        guard let url = configURL,
              let data = try? Data(contentsOf: url),
              let cfg = Config.decode(from: data) else {
            return .default
        }
        return cfg
    }

    /// 原子写回配置（设置界面用）。
    static func save(_ config: Config) {
        guard let url = configURL else { return }
        try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(),
                                                 withIntermediateDirectories: true)
        try? config.encoded().write(to: url, options: .atomic)
    }

    /// 首次启动写默认配置（已存在则不动）。返回是否写入。
    @discardableResult
    static func writeDefaultIfNeeded() -> Bool {
        guard let url = configURL else { return false }
        let fm = FileManager.default
        if fm.fileExists(atPath: url.path) { return false }
        try? fm.createDirectory(at: url.deletingLastPathComponent(),
                                withIntermediateDirectories: true)
        try? Config.default.encoded().write(to: url)
        return true
    }
}
