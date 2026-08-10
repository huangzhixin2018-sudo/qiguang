//
//  ColorExtractor.swift
//  栖光
//

import UIKit
import SwiftUI

/// 照片颜色解析数据模型
struct ExtractedColorItem: Identifiable, Hashable {
    let id = UUID()
    let color: Color
    let uiColor: UIColor
    let hexString: String
    let ratio: Double // 占比 0.0 ~ 1.0
    let nameHint: String
}

/// 沉浸式色谱算法工具类
struct ColorExtractor {
    
    /// 从 UIImage 异步提取 3 ~ 5 个主色调
    static func extractPalette(from image: UIImage, count: Int = 5) async -> [ExtractedColorItem] {
        return await Task.detached(priority: .userInitiated) {
            return extractPaletteSync(from: image, count: count)
        }.value
    }
    
    /// 同步提取函数
    nonisolated private static func extractPaletteSync(from image: UIImage, count: Int) -> [ExtractedColorItem] {
        // 1. 降采样图片至 64x64 加速计算
        let targetSize = CGSize(width: 64, height: 64)
        UIGraphicsBeginImageContextWithOptions(targetSize, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: targetSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        guard let cgImage = resizedImage?.cgImage else { return [] }
        let width = cgImage.width
        let height = cgImage.height
        let totalPixels = width * height
        guard totalPixels > 0 else { return [] }
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        var rawData = [UInt8](repeating: 0, count: width * height * 4)
        
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let bitsPerComponent = 8
        
        guard let context = CGContext(
            data: &rawData,
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue
        ) else { return [] }
        
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        // 2. 颜色桶量化 (Color Binning in RGB space)
        var colorCounts: [Int: (r: Int, g: Int, b: Int, count: Int)] = [:]
        
        for i in stride(from: 0, to: rawData.count, by: 4) {
            let r = Int(rawData[i])
            let g = Int(rawData[i + 1])
            let b = Int(rawData[i + 2])
            let a = Int(rawData[i + 3])
            
            // 忽略太透明的像素
            if a < 50 { continue }
            
            // 按 32 步长进行量化
            let binR = (r / 32) * 32 + 16
            let binG = (g / 32) * 32 + 16
            let binB = (b / 32) * 32 + 16
            
            let key = (binR << 16) | (binG << 8) | binB
            
            if let existing = colorCounts[key] {
                colorCounts[key] = (existing.r + r, existing.g + g, existing.b + b, existing.count + 1)
            } else {
                colorCounts[key] = (r, g, b, 1)
            }
        }
        
        // 3. 排序提取出现频率最高的颜色
        let sortedBins = colorCounts.values.sorted { $0.count > $1.count }
        let topBins = Array(sortedBins.prefix(count * 2))
        
        // 4. 过滤相似颜色并构造结果
        var results: [ExtractedColorItem] = []
        let processedTotal = Double(totalPixels)
        
        for bin in topBins {
            if results.count >= count { break }
            
            let avgR = CGFloat(bin.r / bin.count) / 255.0
            let avgG = CGFloat(bin.g / bin.count) / 255.0
            let avgB = CGFloat(bin.b / bin.count) / 255.0
            
            let uiColor = UIColor(red: avgR, green: avgG, blue: avgB, alpha: 1.0)
            
            // 检查与已有提取颜色是否过于相似
            let isTooSimilar = results.contains { existing in
                colorDistance(uiColor, existing.uiColor) < 0.18
            }
            
            if !isTooSimilar || results.isEmpty {
                let hex = String(format: "#%02X%02X%02X", Int(avgR * 255), Int(avgG * 255), Int(avgB * 255))
                let ratio = Double(bin.count) / processedTotal
                let hint = getColorNameHint(r: avgR, g: avgG, b: avgB)
                
                results.append(
                    ExtractedColorItem(
                        color: Color(uiColor),
                        uiColor: uiColor,
                        hexString: hex,
                        ratio: ratio,
                        nameHint: hint
                    )
                )
            }
        }
        
        if results.isEmpty {
            results.append(ExtractedColorItem(color: .gray, uiColor: .gray, hexString: "#808080", ratio: 1.0, nameHint: "寂静灰"))
        }
        
        return results
    }
    
    nonisolated private static func colorDistance(_ c1: UIColor, _ c2: UIColor) -> CGFloat {
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        c1.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        c2.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        
        let dr = r1 - r2
        let dg = g1 - g2
        let db = b1 - b2
        return sqrt(dr*dr + dg*dg + db*db)
    }
    
    nonisolated private static func getColorNameHint(r: CGFloat, g: CGFloat, b: CGFloat) -> String {
        let uiColor = UIColor(red: r, green: g, blue: b, alpha: 1.0)
        var h: CGFloat = 0, s: CGFloat = 0, v: CGFloat = 0, a: CGFloat = 0
        uiColor.getHue(&h, saturation: &s, brightness: &v, alpha: &a)
        
        let hueDeg = h * 360.0
        
        if v < 0.15 { return "暗夜黑" }
        if s < 0.12 && v > 0.85 { return "月光白" }
        if s < 0.15 { return "寂静灰" }
        
        switch hueDeg {
        case 0..<20, 340...360:
            return s > 0.6 ? (v > 0.7 ? "朱红" : "深绯") : "暖粉"
        case 20..<45:
            return s > 0.6 ? "琥珀金" : "暖沙"
        case 45..<70:
            return s > 0.6 ? "暖阳黄" : "浅稻"
        case 70..<160:
            return s > 0.5 ? "松柏绿" : "苔藓"
        case 160..<200:
            return s > 0.5 ? "青碧" : "水光"
        case 200..<260:
            return s > 0.5 ? "深海蓝" : "雾霭蓝"
        case 260..<310:
            return s > 0.5 ? "暮紫" : "浅芋"
        case 310..<340:
            return "品红"
        default:
            return "沉木"
        }
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

