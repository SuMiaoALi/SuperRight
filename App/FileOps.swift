import Foundation

enum FileOpsError: Error, LocalizedError {
    case cannotCreate(String)
    case cannotTransfer(src: String, reason: String)

    var errorDescription: String? {
        switch self {
        case .cannotCreate(let r): return "新建文件失败：\(r)"
        case .cannotTransfer(let src, let reason): return "处理「\(PathUtils.lastComponent(src))」失败：\(reason)"
        }
    }
}

/// 纯文件系统操作，不含任何 UI。冲突一律加序号，非破坏式。
enum FileOps {
    private static let fm = FileManager.default

    /// 目录下现有文件名集合。
    static func existingNames(inDir dir: String) -> Set<String> {
        let items = (try? fm.contentsOfDirectory(atPath: dir)) ?? []
        return Set(items)
    }

    /// 在 dir 下新建空文件，名字冲突时加序号。返回新文件 URL。
    @discardableResult
    static func createEmptyFile(inDir dir: String, base: String, ext: String) throws -> URL {
        let name = FileName.unique(base: base, ext: ext, existing: existingNames(inDir: dir))
        let url = URL(fileURLWithPath: dir).appendingPathComponent(name)
        do {
            try Data().write(to: url)
        } catch {
            throw FileOpsError.cannotCreate(error.localizedDescription)
        }
        return url
    }

    /// 把多个文件移动/复制到 destDir，每个名字冲突时加序号。返回新位置 URL 列表。
    @discardableResult
    static func transfer(_ srcPaths: [String], toDir destDir: String, move: Bool) throws -> [URL] {
        try fm.createDirectory(atPath: destDir, withIntermediateDirectories: true)
        var results: [URL] = []
        for src in srcPaths {
            let srcName = (src as NSString).lastPathComponent
            let ext = (srcName as NSString).pathExtension
            let base = (srcName as NSString).deletingPathExtension
            let finalName = FileName.unique(base: base, ext: ext, existing: existingNames(inDir: destDir))
            let dst = URL(fileURLWithPath: destDir).appendingPathComponent(finalName)
            do {
                if move {
                    try fm.moveItem(atPath: src, toPath: dst.path)
                } else {
                    try fm.copyItem(atPath: src, toPath: dst.path)
                }
                results.append(dst)
            } catch {
                throw FileOpsError.cannotTransfer(src: src, reason: error.localizedDescription)
            }
        }
        return results
    }
}
