import Foundation

/// 扩展点击菜单后，重动作打包成 superright://<action>?... 交给主程序执行。
/// 这是扩展与主程序之间的 IPC 契约。编解码为纯函数，便于单测。
enum ActionURL {
    static let scheme = "superright"

    enum Action: String {
        case newFile      // 在 dir 下新建文件；ext 给扩展名；custom=1 时由主程序弹名字输入框
        case moveTo       // 把 paths 移动到 dest
        case copyTo       // 把 paths 复制到 dest
        case openWith     // 用 app 打开 paths
        case openDirWith  // 用 app 打开目录 dir
        case revealDir    // 在 Finder 打开/跳转到 dir
    }

    struct Command: Equatable {
        var action: Action
        var paths: [String] = []     // 选中项（openWith / moveTo / copyTo）
        var dir: String?             // 目录（newFile / openDirWith / revealDir）
        var dest: String?            // 目标目录（moveTo / copyTo）
        var ext: String?             // 新建文件扩展名
        var custom: Bool = false     // 新建文件：是否让主程序弹输入框
        var appBundleId: String?     // openWith / openDirWith 的 App
        var appPath: String?
    }

    /// 编码为 URL。
    static func encode(_ cmd: Command) -> URL {
        var comps = URLComponents()
        comps.scheme = scheme
        comps.host = cmd.action.rawValue
        var items: [URLQueryItem] = []
        for p in cmd.paths { items.append(URLQueryItem(name: "p", value: p)) }
        if let v = cmd.dir { items.append(URLQueryItem(name: "dir", value: v)) }
        if let v = cmd.dest { items.append(URLQueryItem(name: "dest", value: v)) }
        if let v = cmd.ext { items.append(URLQueryItem(name: "ext", value: v)) }
        if cmd.custom { items.append(URLQueryItem(name: "custom", value: "1")) }
        if let v = cmd.appBundleId { items.append(URLQueryItem(name: "appBundle", value: v)) }
        if let v = cmd.appPath { items.append(URLQueryItem(name: "appPath", value: v)) }
        comps.queryItems = items.isEmpty ? nil : items
        return comps.url!
    }

    /// 从 URL 解码；非法返回 nil。
    static func decode(_ url: URL) -> Command? {
        guard url.scheme == scheme,
              let host = url.host,
              let action = Action(rawValue: host) else { return nil }
        let comps = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let items = comps?.queryItems ?? []
        func first(_ name: String) -> String? { items.first { $0.name == name }?.value }
        let paths = items.filter { $0.name == "p" }.compactMap { $0.value }
        return Command(
            action: action,
            paths: paths,
            dir: first("dir"),
            dest: first("dest"),
            ext: first("ext"),
            custom: first("custom") == "1",
            appBundleId: first("appBundle"),
            appPath: first("appPath")
        )
    }
}
