import SwiftUI

enum AppColors {
    private static var palette: AppThemePalette {
        ThemeManager.shared.currentTheme
    }
    
    static var background: Color { palette.background }
    static var surface: Color { palette.surface }
    static var surfaceElevated: Color { palette.surfaceElevated }
    static var accent: Color { palette.accent }
    static var accentDark: Color { palette.accentDark }
    static var accentLight: Color { palette.accentLight }
    static var border: Color { palette.border }
    static var textPrimary: Color { palette.textPrimary }
    static var textSecondary: Color { palette.textSecondary }
    static var muted: Color { palette.muted }
    static var isDarkMode: Bool { palette.isDark }
}

