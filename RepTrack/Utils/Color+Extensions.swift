import SwiftUI

extension Color {
    init?(hex: String) {
        let sanitized = Color.sanitize(hex: hex)
        guard let components = Color.colorComponents(from: sanitized) else { return nil }
        self.init(
            .sRGB,
            red: components.red,
            green: components.green,
            blue: components.blue,
            opacity: components.alpha
        )
    }
    
    private static func sanitize(hex: String) -> String {
        var string = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if string.hasPrefix("#") {
            string.removeFirst()
        }
        return string
    }
    
    private static func colorComponents(from string: String) -> (red: Double, green: Double, blue: Double, alpha: Double)? {
        var hexValue: UInt64 = 0
        guard Scanner(string: string).scanHexInt64(&hexValue) else { return nil }
        
        switch string.count {
        case 6:
            let red = Double((hexValue & 0xFF0000) >> 16) / 255.0
            let green = Double((hexValue & 0x00FF00) >> 8) / 255.0
            let blue = Double(hexValue & 0x0000FF) / 255.0
            return (red, green, blue, 1.0)
        case 8:
            let red = Double((hexValue & 0xFF000000) >> 24) / 255.0
            let green = Double((hexValue & 0x00FF0000) >> 16) / 255.0
            let blue = Double((hexValue & 0x0000FF00) >> 8) / 255.0
            let alpha = Double(hexValue & 0x000000FF) / 255.0
            return (red, green, blue, alpha)
        default:
            return nil
        }
    }
}


