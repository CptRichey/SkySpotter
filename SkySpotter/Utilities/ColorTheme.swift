import SwiftUI

struct ColorTheme {
    // Primary colors
    static let primary = Color(hex: "0052CC")         // Deep blue
    static let secondary = Color(hex: "FF9500")       // Orange accent
    static let tertiary = Color(hex: "34C759")        // Green for success
    
    // Background colors
    static let background = Color(hex: "F5F8FC")      // Light background
    static let darkBackground = Color(hex: "1C2B46")  // Dark mode background
    static let cardBackground = Color.white           // Card background in light mode
    static let darkCardBackground = Color(hex: "243757") // Card background in dark mode
    
    // Text colors
    static let textPrimary = Color(hex: "1D1D1F")     // Primary text
    static let textSecondary = Color(hex: "6B7280")   // Secondary text
    static let textLight = Color.white                // Light text for dark backgrounds
    
    // Category colors
    static let civilCategory = Color(hex: "4C9AFF")   // Blue for civil aircraft
    static let militaryCategory = Color(hex: "C12127") // Red for military aircraft
    static let mixedCategory = Color(hex: "9F7AEA")   // Purple for mixed category
    
    // Difficulty colors
    static let easyDifficulty = Color(hex: "36B37E")  // Green for easy
    static let mediumDifficulty = Color(hex: "FF8B00") // Orange for medium
    static let hardDifficulty = Color(hex: "DE350B")  // Red for hard
}

// Extension to create Color from hex string
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
            (a, r, g, b) = (1, 1, 1, 0)
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
