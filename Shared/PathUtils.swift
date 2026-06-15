import Foundation

enum PathUtils {
    /// 展开以 ~ 开头的路径。home 可注入，便于单测。
    static func expandTilde(_ path: String, home: String) -> String {
        if path == "~" { return home }
        if path.hasPrefix("~/") {
            return home + String(path.dropFirst(1))   // 去掉 ~，保留其后的 /...
        }
        return path
    }

    /// 用当前用户 home 展开。
    static func expand(_ path: String) -> String {
        expandTilde(path, home: NSHomeDirectory())
    }

    /// 多个路径拼成换行文本，供复制到剪贴板。
    static func joinForClipboard(_ paths: [String]) -> String {
        paths.joined(separator: "\n")
    }

    /// 从完整路径取文件名（最后一段）。
    static func lastComponent(_ path: String) -> String {
        (path as NSString).lastPathComponent
    }
}
