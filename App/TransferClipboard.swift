import Foundation

/// SuperRight 自维护的"剪切/拷贝 → 粘贴"剪贴板（区别于系统剪贴板）。
/// 状态写到 App Group，供后续 pasteHere 读取。
enum TransferClipboard {
    private struct State: Codable { var mode: String; var paths: [String] }  // mode: "cut" | "copy"

    private static var stateURL: URL? {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: ConfigStore.appGroupID)?
            .appendingPathComponent("transfer-clipboard.json")
    }

    static func mark(_ paths: [String], cut: Bool) {
        guard let url = stateURL,
              let data = try? JSONEncoder().encode(State(mode: cut ? "cut" : "copy", paths: paths)) else { return }
        try? data.write(to: url)
    }

    /// 把已标记的文件粘贴到 dir（cut 则移动并清空标记，copy 则复制）。返回新位置。
    @discardableResult
    static func pasteHere(_ dir: String) throws -> [URL] {
        guard let url = stateURL,
              let data = try? Data(contentsOf: url),
              let state = try? JSONDecoder().decode(State.self, from: data),
              !state.paths.isEmpty else {
            throw SimpleError("没有已剪切/拷贝的文件")
        }
        let move = state.mode == "cut"
        let results = try FileOps.transfer(state.paths, toDir: dir, move: move)
        if move { try? FileManager.default.removeItem(at: url) }  // 剪切后清空标记
        return results
    }

    static var hasMarked: Bool {
        guard let url = stateURL else { return false }
        return FileManager.default.fileExists(atPath: url.path)
    }
}
