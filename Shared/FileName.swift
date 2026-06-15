import Foundation

enum FileName {
    /// 在已存在文件名集合 `existing` 中，为 base+ext 找一个不冲突的名字。
    /// 冲突时追加 " 2"、" 3"……返回最终文件名（含扩展名）。纯函数，便于单测。
    /// ext 为空字符串时表示无扩展名。
    static func unique(base: String, ext: String, existing: Set<String>) -> String {
        let suffix = ext.isEmpty ? "" : ".\(ext)"
        let first = base + suffix
        if !existing.contains(first) { return first }
        var n = 2
        while true {
            let candidate = "\(base) \(n)\(suffix)"
            if !existing.contains(candidate) { return candidate }
            n += 1
        }
    }
}
