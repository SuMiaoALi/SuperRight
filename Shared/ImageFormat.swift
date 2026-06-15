import Foundation

/// 图片格式转换的目标格式。
enum ImageFormat: String, CaseIterable {
    case png, jpg, heic, tiff, bmp, gif

    var displayName: String {
        switch self {
        case .png: return "PNG"
        case .jpg: return "JPEG"
        case .heic: return "HEIC"
        case .tiff: return "TIFF"
        case .bmp: return "BMP"
        case .gif: return "GIF"
        }
    }

    /// CGImageDestination 用的 UTI。
    var uti: String {
        switch self {
        case .png:  return "public.png"
        case .jpg:  return "public.jpeg"
        case .heic: return "public.heic"
        case .tiff: return "public.tiff"
        case .bmp:  return "com.microsoft.bmp"
        case .gif:  return "com.compuserve.gif"
        }
    }
}
