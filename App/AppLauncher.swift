import Foundation
import AppKit

enum AppLauncherError: Error, LocalizedError {
    case appNotFound(String)
    var errorDescription: String? {
        switch self {
        case .appNotFound(let a): return "找不到 App：\(a)"
        }
    }
}

/// 启动 App、在 Finder 跳转目录。
enum AppLauncher {

    /// 终端类 App：打开"文件"无意义，应改为进入其所在目录。
    static let terminalBundleIds: Set<String> = [
        "com.apple.Terminal",
        "com.googlecode.iterm2",
        "dev.warp.Warp-Stable",
        "io.alacritty",
        "net.kovidgoyal.kitty"
    ]

    /// 解析 App 的 URL：优先 bundleId，其次 path。
    static func resolveApp(bundleId: String?, path: String?) -> URL? {
        if let bid = bundleId,
           let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bid) {
            return url
        }
        if let p = path {
            let expanded = PathUtils.expand(p)
            if FileManager.default.fileExists(atPath: expanded) {
                return URL(fileURLWithPath: expanded)
            }
        }
        return nil
    }

    /// 用指定 App 打开若干文件/目录。
    static func open(_ paths: [String], bundleId: String?, appPath: String?,
                     completion: @escaping (Error?) -> Void) {
        guard let appURL = resolveApp(bundleId: bundleId, path: appPath) else {
            completion(AppLauncherError.appNotFound(bundleId ?? appPath ?? "未知"))
            return
        }
        let isTerminal = bundleId.map { terminalBundleIds.contains($0) } ?? false
        let fm = FileManager.default
        var seen = Set<String>()
        var urls: [URL] = []
        for p in paths {
            var resolved = PathUtils.expand(p)
            if isTerminal {
                // 终端打开文件 → 改为进入其所在目录
                var isDir: ObjCBool = false
                if fm.fileExists(atPath: resolved, isDirectory: &isDir), !isDir.boolValue {
                    resolved = (resolved as NSString).deletingLastPathComponent
                }
            }
            if seen.insert(resolved).inserted {   // 去重（多个文件可能同目录）
                urls.append(URL(fileURLWithPath: resolved))
            }
        }
        let config = NSWorkspace.OpenConfiguration()
        NSWorkspace.shared.open(urls, withApplicationAt: appURL, configuration: config) { _, error in
            completion(error)
        }
    }

    /// 在 Finder 打开一个目录窗口（跳转到常用目录）。
    static func revealDir(_ path: String) {
        let expanded = PathUtils.expand(path)
        NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: expanded)
    }

    /// 在 Finder 选中并显示这些文件。
    static func revealFiles(_ paths: [String]) {
        let urls = paths.map { URL(fileURLWithPath: $0) }
        NSWorkspace.shared.activateFileViewerSelecting(urls)
    }
}
