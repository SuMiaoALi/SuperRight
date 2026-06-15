import Foundation

/// 扩展点击菜单后，重动作打包成 superright://<action>?... 交给主程序执行。
/// 这是扩展与主程序之间的 IPC 契约。编解码为纯函数，便于单测。
/// 复杂参数（重命名规则、选图标文件）由主程序弹窗收集，URL 只带菜单点击时即可确定的参数。
enum ActionURL {
    static let scheme = "superright"

    enum Action: String {
        // 文件
        case newFile          // dir + ext；custom=1 时主程序弹名字框
        case newFromTemplate  // dir + tmpl(模板文件路径)
        case moveTo           // paths → dest
        case copyTo           // paths → dest
        case markCut          // 标记 paths 为"剪切"
        case markCopy         // 标记 paths 为"拷贝"
        case pasteHere        // 把标记的文件粘贴到 dir
        case deletePermanently // 永久删除 paths（主程序二次确认）
        // 打开 / 跳转
        case openWith         // 用 app 打开 paths
        case openDirWith      // 用 app 打开 dir
        case revealDir        // Finder 跳转到 dir
        // 文件夹图标
        case setFolderColor   // paths + hex
        case setCustomIcon    // paths（主程序弹选图）
        case clearIcon        // paths
        case copyIcon         // path（取图标到剪贴板）
        case pasteIcon        // paths（把剪贴板图标贴上）
        // 工具箱
        case toggleHidden     // 切换显示隐藏文件
        case qrcode           // paths（生成路径二维码）
        case zip              // paths → 同目录 zip
        case unzip            // paths（解压）
        case convertImage     // paths + fmt(目标格式)
        case fileInfo         // paths（展示信息）
        case makeAlias        // paths
        case makeSymlink      // paths
        case batchRename      // paths（主程序弹规则）
    }

    struct Command: Equatable {
        var action: Action
        var paths: [String] = []
        var dir: String?
        var dest: String?
        var ext: String?
        var custom: Bool = false
        var appBundleId: String?
        var appPath: String?
        var templatePath: String?   // newFromTemplate
        var fmt: String?            // convertImage 目标格式
        var hex: String?            // setFolderColor 颜色
    }

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
        if let v = cmd.templatePath { items.append(URLQueryItem(name: "tmpl", value: v)) }
        if let v = cmd.fmt { items.append(URLQueryItem(name: "fmt", value: v)) }
        if let v = cmd.hex { items.append(URLQueryItem(name: "hex", value: v)) }
        comps.queryItems = items.isEmpty ? nil : items
        return comps.url!
    }

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
            appPath: first("appPath"),
            templatePath: first("tmpl"),
            fmt: first("fmt"),
            hex: first("hex")
        )
    }
}
