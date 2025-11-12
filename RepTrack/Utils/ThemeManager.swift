import SwiftUI
import Combine

struct AppThemePalette: Identifiable, Equatable {
    let id: String
    let displayName: String
    let description: String
    let isDark: Bool
    
    private let backgroundHex: String
    private let surfaceHex: String
    private let surfaceElevatedHex: String
    private let accentHex: String
    private let accentDarkHex: String
    private let accentLightHex: String
    private let borderHex: String
    private let textPrimaryHex: String
    private let textSecondaryHex: String
    private let mutedOpacity: Double
    
    init(
        id: String,
        displayName: String,
        description: String,
        isDark: Bool = true,
        backgroundHex: String,
        surfaceHex: String,
        surfaceElevatedHex: String,
        accentHex: String,
        accentDarkHex: String,
        accentLightHex: String,
        borderHex: String,
        textPrimaryHex: String,
        textSecondaryHex: String,
        mutedOpacity: Double = 0.15
    ) {
        self.id = id
        self.displayName = displayName
        self.description = description
        self.isDark = isDark
        self.backgroundHex = backgroundHex
        self.surfaceHex = surfaceHex
        self.surfaceElevatedHex = surfaceElevatedHex
        self.accentHex = accentHex
        self.accentDarkHex = accentDarkHex
        self.accentLightHex = accentLightHex
        self.borderHex = borderHex
        self.textPrimaryHex = textPrimaryHex
        self.textSecondaryHex = textSecondaryHex
        self.mutedOpacity = mutedOpacity
    }
    
    var background: Color { Color(hex: backgroundHex) ?? Color.black }
    var surface: Color { Color(hex: surfaceHex) ?? Color.black.opacity(0.85) }
    var surfaceElevated: Color { Color(hex: surfaceElevatedHex) ?? Color.black.opacity(0.75) }
    var accent: Color { Color(hex: accentHex) ?? Color.blue }
    var accentDark: Color { Color(hex: accentDarkHex) ?? Color.blue.opacity(0.6) }
    var accentLight: Color { Color(hex: accentLightHex) ?? Color.blue.opacity(0.8) }
    var border: Color { Color(hex: borderHex) ?? Color.white.opacity(0.08) }
    var textPrimary: Color { Color(hex: textPrimaryHex) ?? Color.white }
    var textSecondary: Color { Color(hex: textSecondaryHex) ?? Color.white.opacity(0.7) }
    var muted: Color { textPrimary.opacity(mutedOpacity) }
}

final class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    
    @Published private(set) var availableThemes: [AppThemePalette]
    @Published var selectedThemeID: String {
        didSet {
            saveSelectedTheme()
        }
    }
    
    private let storageKey = "selectedThemeID"
    
    private init() {
        let themes: [AppThemePalette] = [
            AppThemePalette(
                id: "aurora",
                displayName: "Aurora",
                description: "Deep navy with electric blue highlights.",
                isDark: true,
                backgroundHex: "#05080F",
                surfaceHex: "#101521",
                surfaceElevatedHex: "#171E2C",
                accentHex: "#4D96FF",
                accentDarkHex: "#15396B",
                accentLightHex: "#7BB7FF",
                borderHex: "#2A3447",
                textPrimaryHex: "#E0E0E0",
                textSecondaryHex: "#A0A0A0",
                mutedOpacity: 0.18
            ),
            AppThemePalette(
                id: "neonSunset",
                displayName: "Neon Sunset",
                description: "Magenta highlights over a charcoal base.",
                isDark: true,
                backgroundHex: "#0B0612",
                surfaceHex: "#140B1F",
                surfaceElevatedHex: "#1F1231",
                accentHex: "#F25F9F",
                accentDarkHex: "#8B1E5D",
                accentLightHex: "#FF8FCD",
                borderHex: "#3B214A",
                textPrimaryHex: "#F5EAF7",
                textSecondaryHex: "#D0BFD6",
                mutedOpacity: 0.2
            ),
            AppThemePalette(
                id: "forestPulse",
                displayName: "Forest Pulse",
                description: "Muted charcoal with vibrant teal accents.",
                isDark: true,
                backgroundHex: "#05140E",
                surfaceHex: "#0B1E17",
                surfaceElevatedHex: "#13261F",
                accentHex: "#2DCFA6",
                accentDarkHex: "#0F6E54",
                accentLightHex: "#66F5CD",
                borderHex: "#1F3A2F",
                textPrimaryHex: "#E4F7F0",
                textSecondaryHex: "#A8D4C5",
                mutedOpacity: 0.18
            ),
            AppThemePalette(
                id: "daybreak",
                displayName: "Daybreak",
                description: "Light mode with sapphire accents.",
                isDark: false,
                backgroundHex: "#F5F7FB",
                surfaceHex: "#FFFFFF",
                surfaceElevatedHex: "#FFFFFF",
                accentHex: "#2D6DF6",
                accentDarkHex: "#103C9A",
                accentLightHex: "#7FA8FF",
                borderHex: "#D6DEEB",
                textPrimaryHex: "#1A2433",
                textSecondaryHex: "#4C5566",
                mutedOpacity: 0.12
            )
        ]
        
        availableThemes = themes
        selectedThemeID = Self.resolveInitialThemeID(themes: themes, storageKey: storageKey)
    }
    
    var currentTheme: AppThemePalette {
        availableThemes.first { $0.id == selectedThemeID } ?? availableThemes[0]
    }
    
    func select(_ theme: AppThemePalette) {
        guard theme.id != selectedThemeID else { return }
        selectedThemeID = theme.id
    }
    
    private func saveSelectedTheme() {
        UserDefaults.standard.set(selectedThemeID, forKey: storageKey)
    }
    
    private static func resolveInitialThemeID(themes: [AppThemePalette], storageKey: String) -> String {
        let saved = UserDefaults.standard.string(forKey: storageKey)
        if let saved, themes.contains(where: { $0.id == saved }) {
            return saved
        } else {
            return themes.first?.id ?? "aurora"
        }
    }
}


