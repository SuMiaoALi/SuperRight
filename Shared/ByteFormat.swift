import Foundation

enum ByteFormat {
    /// 人类可读字节数（B/KB/MB/…，1024 进制）。纯函数，便于单测。
    static func human(_ bytes: Int64) -> String {
        let units = ["B", "KB", "MB", "GB", "TB", "PB"]
        var v = Double(bytes)
        var i = 0
        while v >= 1024 && i < units.count - 1 { v /= 1024; i += 1 }
        return i == 0 ? "\(bytes) B" : String(format: "%.2f %@", v, units[i])
    }
}
