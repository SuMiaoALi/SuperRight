import Foundation
import AppKit
import UniformTypeIdentifiers

/// 文件(夹)图标操作。依赖对目标文件的写权限（受保护目录需完全磁盘访问）。
enum IconOps {

    /// 生成着色的文件夹图标：在系统文件夹图标上叠加半透明色，保留立体阴影。
    static func tintedFolderIcon(hex: String) -> NSImage? {
        guard let rgb = ColorHex.rgb(hex) else { return nil }
        let color = NSColor(red: rgb.r, green: rgb.g, blue: rgb.b, alpha: 0.5)
        let base = NSWorkspace.shared.icon(for: .folder)
        let size = NSSize(width: 512, height: 512)
        let img = NSImage(size: size)
        img.lockFocus()
        base.draw(in: NSRect(origin: .zero, size: size),
                  from: .zero, operation: .copy, fraction: 1.0)
        color.set()
        NSRect(origin: .zero, size: size).fill(using: .sourceAtop)
        img.unlockFocus()
        return img
    }

    /// 给文件夹换颜色。
    static func setColor(_ paths: [String], hex: String) throws {
        guard let icon = tintedFolderIcon(hex: hex) else {
            throw SimpleError("颜色值无效：\(hex)")
        }
        for p in paths {
            if !NSWorkspace.shared.setIcon(icon, forFile: p, options: []) {
                throw SimpleError("设置图标失败：\(PathUtils.lastComponent(p))")
            }
        }
    }

    /// 设置自定义图标（用一张图片）。
    static func setCustomIcon(_ paths: [String], imagePath: String) throws {
        guard let image = NSImage(contentsOfFile: imagePath) else {
            throw SimpleError("无法读取图片：\(PathUtils.lastComponent(imagePath))")
        }
        for p in paths {
            if !NSWorkspace.shared.setIcon(image, forFile: p, options: []) {
                throw SimpleError("设置图标失败：\(PathUtils.lastComponent(p))")
            }
        }
    }

    /// 清除自定义图标，恢复默认。
    static func clearIcon(_ paths: [String]) throws {
        for p in paths {
            if !NSWorkspace.shared.setIcon(nil, forFile: p, options: []) {
                throw SimpleError("清除图标失败：\(PathUtils.lastComponent(p))")
            }
        }
    }

    /// 把某文件的图标拷到剪贴板。
    static func copyIcon(_ path: String) {
        let icon = NSWorkspace.shared.icon(forFile: path)
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.writeObjects([icon])
    }

    /// 把剪贴板里的图标贴到这些文件上。
    static func pasteIcon(_ paths: [String]) throws {
        let pb = NSPasteboard.general
        guard let objs = pb.readObjects(forClasses: [NSImage.self], options: nil) as? [NSImage],
              let image = objs.first else {
            throw SimpleError("剪贴板里没有图标/图片")
        }
        for p in paths {
            if !NSWorkspace.shared.setIcon(image, forFile: p, options: []) {
                throw SimpleError("粘贴图标失败：\(PathUtils.lastComponent(p))")
            }
        }
    }
}
