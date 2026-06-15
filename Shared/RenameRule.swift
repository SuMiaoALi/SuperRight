import Foundation

/// 批量重命名规则。
struct RenameRule: Equatable {
    var find = ""
    var replace = ""
    var prefix = ""
    var suffix = ""
    var useIndex = false
    var startIndex = 1
    var padding = 0   // 序号补零宽度，0 表示不补
}

enum BatchRename {
    /// 对单个文件名按规则 + 位置生成新名（保留扩展名）。纯函数。
    static func apply(_ name: String, rule: RenameRule, position: Int) -> String {
        let ns = name as NSString
        let ext = ns.pathExtension
        var base = ns.deletingPathExtension
        if !rule.find.isEmpty {
            base = base.replacingOccurrences(of: rule.find, with: rule.replace)
        }
        base = rule.prefix + base + rule.suffix
        if rule.useIndex {
            let idx = rule.startIndex + position
            let idxStr = rule.padding > 0 ? String(format: "%0\(rule.padding)d", idx) : String(idx)
            base += idxStr
        }
        return ext.isEmpty ? base : "\(base).\(ext)"
    }

    /// 批量应用，position 为 0 基序号。
    static func applyAll(_ names: [String], rule: RenameRule) -> [String] {
        names.enumerated().map { apply($1, rule: rule, position: $0) }
    }
}
