#!/usr/bin/env swift
import AppKit

// 生成 App 图标：圆角渐变底 + 白色光标符号。输出到 App/Assets.xcassets/AppIcon.appiconset。
let outDir = CommandLine.arguments.count > 1 ? CommandLine.arguments[1]
    : "App/Assets.xcassets/AppIcon.appiconset"
try? FileManager.default.createDirectory(atPath: outDir, withIntermediateDirectories: true)

func render(_ px: Int) -> Data {
    let size = NSSize(width: px, height: px)
    // 用精确像素的 bitmap 上下文，避免 Retina lockFocus 把尺寸翻倍
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: px, pixelsHigh: px,
                              bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                              isPlanar: false, colorSpaceName: .deviceRGB,
                              bytesPerRow: 0, bitsPerPixel: 0)!
    rep.size = size
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    let rect = NSRect(origin: .zero, size: size)
    // 圆角渐变底（蓝→紫 squircle）
    let inset = CGFloat(px) * 0.06
    let r = rect.insetBy(dx: inset, dy: inset)
    let radius = r.width * 0.2237
    let path = NSBezierPath(roundedRect: r, xRadius: radius, yRadius: radius)
    let grad = NSGradient(colors: [NSColor(srgbRed: 0.36, green: 0.42, blue: 0.96, alpha: 1),
                                   NSColor(srgbRed: 0.62, green: 0.35, blue: 0.95, alpha: 1)])
    grad?.draw(in: path, angle: -90)
    // 白色光标符号
    if let sym = NSImage(systemSymbolName: "cursorarrow.click.2", accessibilityDescription: nil)?
        .withSymbolConfiguration(NSImage.SymbolConfiguration(pointSize: CGFloat(px) * 0.42, weight: .semibold)) {
        let s = sym.size
        let dr = NSRect(x: (CGFloat(px) - s.width)/2, y: (CGFloat(px) - s.height)/2, width: s.width, height: s.height)
        NSColor.white.set()
        sym.draw(in: dr)
        // template 符号默认黑，叠加白色
        NSColor.white.set()
        dr.fill(using: .sourceAtop)
    }
    NSGraphicsContext.restoreGraphicsState()
    return rep.representation(using: .png, properties: [:])!
}

let pxs = [16, 32, 64, 128, 256, 512, 1024]
for px in pxs {
    let data = render(px)
    try! data.write(to: URL(fileURLWithPath: "\(outDir)/icon_\(px).png"))
}

// Contents.json（macOS 各尺寸 @1x/@2x）
struct Entry { let size: Int; let scale: Int; let px: Int }
let entries = [Entry(size:16,scale:1,px:16), Entry(size:16,scale:2,px:32),
               Entry(size:32,scale:1,px:32), Entry(size:32,scale:2,px:64),
               Entry(size:128,scale:1,px:128), Entry(size:128,scale:2,px:256),
               Entry(size:256,scale:1,px:256), Entry(size:256,scale:2,px:512),
               Entry(size:512,scale:1,px:512), Entry(size:512,scale:2,px:1024)]
let imagesJSON = entries.map {
    "    {\"size\":\"\($0.size)x\($0.size)\",\"idiom\":\"mac\",\"filename\":\"icon_\($0.px).png\",\"scale\":\"\($0.scale)x\"}"
}.joined(separator: ",\n")
let contents = "{\n  \"images\": [\n\(imagesJSON)\n  ],\n  \"info\": {\"version\":1,\"author\":\"xcode\"}\n}\n"
try! contents.write(toFile: "\(outDir)/Contents.json", atomically: true, encoding: .utf8)
print("✓ 图标已生成到 \(outDir)")
