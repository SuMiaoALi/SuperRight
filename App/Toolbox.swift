import Foundation
import AppKit
import ImageIO
import UniformTypeIdentifiers
import CryptoKit
import CoreImage

/// 工具箱：各项独立的小操作。无 UI（弹窗在 CommandHandler）。
enum Toolbox {
    private static let fm = FileManager.default

    // MARK: - 显示/隐藏 隐藏文件

    static func toggleHiddenFiles() {
        let read = Shell.run("/usr/bin/defaults", ["read", "com.apple.finder", "AppleShowAllFiles"])
        let cur = read.out.lowercased().contains("1") || read.out.lowercased().contains("true") || read.out.lowercased().contains("yes")
        Shell.run("/usr/bin/defaults", ["write", "com.apple.finder", "AppleShowAllFiles", "-bool", cur ? "false" : "true"])
        Shell.run("/usr/bin/killall", ["Finder"])
    }

    // MARK: - 二维码

    /// 为路径文本生成二维码 PNG，存到同目录 "<名>.qr.png"，返回其路径。
    @discardableResult
    static func makeQRCode(for path: String) throws -> URL {
        let text = path
        guard let data = text.data(using: .utf8),
              let filter = CIFilter(name: "CIQRCodeGenerator") else {
            throw SimpleError(L("无法生成二维码"))
        }
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("M", forKey: "inputCorrectionLevel")
        guard var ci = filter.outputImage else { throw SimpleError(L("二维码生成失败")) }
        let scale: CGFloat = 512 / ci.extent.width
        ci = ci.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        let rep = NSCIImageRep(ciImage: ci)
        let img = NSImage(size: rep.size)
        img.addRepresentation(rep)
        guard let tiff = img.tiffRepresentation,
              let bmp = NSBitmapImageRep(data: tiff),
              let png = bmp.representation(using: .png, properties: [:]) else {
            throw SimpleError(L("二维码编码失败"))
        }
        let base = (path as NSString).lastPathComponent
        let dir = (path as NSString).deletingLastPathComponent
        let out = URL(fileURLWithPath: dir).appendingPathComponent("\(base).qr.png")
        try png.write(to: out)
        return out
    }

    // MARK: - 压缩 / 解压

    /// 把选中项压缩成一个 zip（放在它们的父目录），返回 zip 路径。
    @discardableResult
    static func zip(_ paths: [String]) throws -> URL {
        guard let first = paths.first else { throw SimpleError(L("没有选中文件")) }
        let parent = (first as NSString).deletingLastPathComponent
        let base = paths.count == 1
            ? ((first as NSString).lastPathComponent as NSString).deletingPathExtension
            : L("归档")
        let existing = Set((try? fm.contentsOfDirectory(atPath: parent)) ?? [])
        let zipName = FileName.unique(base: base, ext: "zip", existing: existing)
        let names = paths.map { ($0 as NSString).lastPathComponent }
        let r = Shell.run("/usr/bin/zip", ["-r", "-X", zipName] + names, cwd: parent)
        guard r.code == 0 else { throw SimpleError(L("压缩失败：") + r.out) }
        return URL(fileURLWithPath: parent).appendingPathComponent(zipName)
    }

    /// 解压选中的 zip，各自解到同目录下以其名命名的文件夹。
    static func unzip(_ paths: [String]) throws {
        for p in paths where (p as NSString).pathExtension.lowercased() == "zip" {
            let parent = (p as NSString).deletingLastPathComponent
            let base = (p as NSString).lastPathComponent as NSString
            let existing = Set((try? fm.contentsOfDirectory(atPath: parent)) ?? [])
            let folder = FileName.unique(base: base.deletingPathExtension, ext: "", existing: existing)
            let dest = URL(fileURLWithPath: parent).appendingPathComponent(folder)
            let r = Shell.run("/usr/bin/ditto", ["-x", "-k", p, dest.path])
            guard r.code == 0 else { throw SimpleError(L("解压失败：") + r.out) }
        }
    }

    // MARK: - 图片格式转换

    static func convertImage(_ paths: [String], to fmt: ImageFormat) throws {
        for p in paths {
            guard let src = CGImageSourceCreateWithURL(URL(fileURLWithPath: p) as CFURL, nil),
                  let cg = CGImageSourceCreateImageAtIndex(src, 0, nil) else {
                throw SimpleError(L("无法读取图片：") + PathUtils.lastComponent(p))
            }
            let parent = (p as NSString).deletingLastPathComponent
            let base = ((p as NSString).lastPathComponent as NSString).deletingPathExtension
            let existing = Set((try? fm.contentsOfDirectory(atPath: parent)) ?? [])
            let outName = FileName.unique(base: base, ext: fmt.rawValue, existing: existing)
            let outURL = URL(fileURLWithPath: parent).appendingPathComponent(outName)
            guard let dest = CGImageDestinationCreateWithURL(outURL as CFURL, fmt.uti as CFString, 1, nil) else {
                throw SimpleError(L("无法创建目标：") + fmt.displayName)
            }
            CGImageDestinationAddImage(dest, cg, nil)
            if !CGImageDestinationFinalize(dest) {
                throw SimpleError(L("转换失败：") + PathUtils.lastComponent(p))
            }
        }
    }

    // MARK: - 文件信息

    static func info(for path: String) -> String {
        let ns = path as NSString
        var lines = [L("名称：") + ns.lastPathComponent, L("路径：") + path]
        let attrs = (try? fm.attributesOfItem(atPath: path)) ?? [:]
        var isDir: ObjCBool = false
        fm.fileExists(atPath: path, isDirectory: &isDir)
        lines.append(L("类型：") + (isDir.boolValue ? L("文件夹") : L("文件")))
        if let size = attrs[.size] as? Int64 { lines.append(L("大小：") + ByteFormat.human(size)) }
        let df = DateFormatter(); df.dateFormat = "yyyy-MM-dd HH:mm:ss"
        if let c = attrs[.creationDate] as? Date { lines.append(L("创建：") + df.string(from: c)) }
        if let m = attrs[.modificationDate] as? Date { lines.append(L("修改：") + df.string(from: m)) }
        if let perm = attrs[.posixPermissions] as? Int { lines.append(L("权限：") + String(format: "%o", perm)) }
        if !isDir.boolValue, let data = try? Data(contentsOf: URL(fileURLWithPath: path)) {
            let md5 = Insecure.MD5.hash(data: data).map { String(format: "%02x", $0) }.joined()
            let sha = SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
            lines.append("MD5: " + md5)
            lines.append("SHA256: " + sha)
        }
        return lines.joined(separator: "\n")
    }

    // MARK: - 替身 / 软链

    static func makeAlias(_ paths: [String]) throws {
        for p in paths {
            let src = URL(fileURLWithPath: p)
            let parent = (p as NSString).deletingLastPathComponent
            let base = (p as NSString).lastPathComponent
            let existing = Set((try? fm.contentsOfDirectory(atPath: parent)) ?? [])
            let name = FileName.unique(base: "\(base) \(L("替身"))", ext: "", existing: existing)
            let dst = URL(fileURLWithPath: parent).appendingPathComponent(name)
            let bookmark = try src.bookmarkData(options: .suitableForBookmarkFile,
                                                includingResourceValuesForKeys: nil, relativeTo: nil)
            try URL.writeBookmarkData(bookmark, to: dst)
        }
    }

    static func makeSymlink(_ paths: [String]) throws {
        for p in paths {
            let parent = (p as NSString).deletingLastPathComponent
            let base = (p as NSString).lastPathComponent
            let existing = Set((try? fm.contentsOfDirectory(atPath: parent)) ?? [])
            let name = FileName.unique(base: "\(base) \(L("链接"))", ext: "", existing: existing)
            let link = (parent as NSString).appendingPathComponent(name)
            try fm.createSymbolicLink(atPath: link, withDestinationPath: p)
        }
    }

    // MARK: - 永久删除

    static func deletePermanently(_ paths: [String]) throws {
        for p in paths { try fm.removeItem(atPath: p) }
    }

    // MARK: - 批量重命名（规则在 RenameRule，纯逻辑在 BatchRename）

    static func batchRename(_ paths: [String], rule: RenameRule) throws {
        // 先算新名再统一改，避免中途冲突。
        let names = paths.map { ($0 as NSString).lastPathComponent }
        let newNames = BatchRename.applyAll(names, rule: rule)
        for (p, newName) in Swift.zip(paths, newNames) where newName != ((p as NSString).lastPathComponent) {
            let parent = (p as NSString).deletingLastPathComponent
            let dst = (parent as NSString).appendingPathComponent(newName)
            try fm.moveItem(atPath: p, toPath: dst)
        }
    }
}
