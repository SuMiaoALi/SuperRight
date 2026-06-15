import Foundation

enum ColorHex {
    /// "#RRGGBB" 或 "RRGGBB" → (r,g,b) 各 0...1；非法返回 nil。纯函数。
    static func rgb(_ hex: String) -> (r: Double, g: Double, b: Double)? {
        let s = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
        guard s.count == 6, let v = Int(s, radix: 16) else { return nil }
        return (Double((v >> 16) & 0xFF) / 255.0,
                Double((v >> 8) & 0xFF) / 255.0,
                Double(v & 0xFF) / 255.0)
    }
}
