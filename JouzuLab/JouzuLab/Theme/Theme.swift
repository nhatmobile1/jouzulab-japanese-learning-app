import SwiftUI

// MARK: - Organic/Natural Theme

/// Organic/Natural design theme with earthy tones, flowing shapes, and calm aesthetics.
/// Supports both light and dark mode with proper contrast ratios (4.5:1 minimum).
enum AppTheme {

    // MARK: - Colors

    enum Colors {
        // Primary brand colors
        static let primary = Color("Primary")
        static let secondary = Color("Secondary")
        static let accent = Color("Accent")

        // Backgrounds
        static let background = Color("Background")
        static let surface = Color("Surface")
        static let surfaceElevated = Color("SurfaceElevated")

        // Text
        static let textPrimary = Color("TextPrimary")
        static let textSecondary = Color("TextSecondary")
        static let textTertiary = Color("TextTertiary")

        // Semantic colors
        static let success = Color("Success")
        static let warning = Color("Warning")
        static let error = Color("Error")

        // Entry type colors
        static let vocab = Color("Vocab")
        static let phrase = Color("Phrase")
        static let sentence = Color("Sentence")

        // JLPT level colors
        static let jlptN5 = Color("JLPT_N5")
        static let jlptN4 = Color("JLPT_N4")
        static let jlptN3 = Color("JLPT_N3")
        static let jlptN2 = Color("JLPT_N2")
        static let jlptN1 = Color("JLPT_N1")

        // Fallback colors (used if asset colors not defined)
        enum Fallback {
            // Light mode
            static let backgroundLight = Color(hex: "F5F2EB")
            static let surfaceLight = Color(hex: "FFFFFF")
            static let surfaceElevatedLight = Color(hex: "FAFAF7")
            static let primaryLight = Color(hex: "4A6741")
            static let secondaryLight = Color(hex: "8B7355")
            static let accentLight = Color(hex: "7C9A6D")
            static let textPrimaryLight = Color(hex: "2D3B2D")
            static let textSecondaryLight = Color(hex: "6B7B6B")
            static let textTertiaryLight = Color(hex: "9BA89B")

            // Dark mode
            static let backgroundDark = Color(hex: "1C2419")
            static let surfaceDark = Color(hex: "2D3B2D")
            static let surfaceElevatedDark = Color(hex: "3A4A3A")
            static let primaryDark = Color(hex: "7C9A6D")
            static let secondaryDark = Color(hex: "A69580")
            static let accentDark = Color(hex: "9BB88D")
            static let textPrimaryDark = Color(hex: "E8EBE5")
            static let textSecondaryDark = Color(hex: "A8B5A8")
            static let textTertiaryDark = Color(hex: "7A8A7A")

            // Semantic
            static let success = Color(hex: "5A8A4A")
            static let warning = Color(hex: "C4A35A")
            static let error = Color(hex: "B85A5A")

            // Entry types
            static let vocab = Color(hex: "5A7A52")
            static let phrase = Color(hex: "7A6A52")
            static let sentence = Color(hex: "52707A")

            // JLPT levels
            static let jlptN5 = Color(hex: "7C9A6D")
            static let jlptN4 = Color(hex: "6A8A7C")
            static let jlptN3 = Color(hex: "8A7A5A")
            static let jlptN2 = Color(hex: "7A6A8A")
            static let jlptN1 = Color(hex: "8A5A6A")

            // Tab bar - dark background like iTalki/LinkedIn
            static let tabBar = Color(hex: "1C1C1E")  // iOS system dark gray
            static let tabBarSelected = Color(hex: "4A6741")  // Primary green
            static let tabBarUnselected = Color(hex: "8E8E93")  // iOS system gray
        }
    }

    // MARK: - Typography

    enum Typography {
        // Japanese text (larger for readability)
        static let japaneseTitle = Font.system(size: 32, weight: .medium)
        static let japaneseHeadline = Font.system(size: 24, weight: .medium)
        static let japaneseBody = Font.system(size: 18, weight: .regular)

        // Reading/furigana
        static let reading = Font.system(size: 16, weight: .regular)
        static let readingSmall = Font.system(size: 14, weight: .regular)

        // English/UI text
        static let title = Font.system(size: 28, weight: .semibold, design: .rounded)
        static let headline = Font.system(size: 20, weight: .semibold, design: .rounded)
        static let subheadline = Font.system(size: 17, weight: .medium, design: .rounded)
        static let body = Font.system(size: 17, weight: .regular, design: .rounded)
        static let callout = Font.system(size: 16, weight: .regular, design: .rounded)
        static let caption = Font.system(size: 13, weight: .regular, design: .rounded)
        static let captionBold = Font.system(size: 13, weight: .semibold, design: .rounded)

        // Stats/numbers
        static let statLarge = Font.system(size: 36, weight: .bold, design: .rounded)
        static let statMedium = Font.system(size: 24, weight: .semibold, design: .rounded)
    }

    // MARK: - Spacing

    enum Spacing {
        static let xxs: CGFloat = 4
        static let xs: CGFloat = 8
        static let sm: CGFloat = 12
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
    }

    // MARK: - Corner Radius

    enum CornerRadius {
        static let small: CGFloat = 4
        static let medium: CGFloat = 8
        static let large: CGFloat = 10
        static let xl: CGFloat = 12
        static let pill: CGFloat = 50
    }

    // MARK: - Shadows

    enum Shadow {
        static func soft(colorScheme: ColorScheme) -> some View {
            Color.black.opacity(colorScheme == .dark ? 0.3 : 0.08)
        }

        static let softRadius: CGFloat = 8
        static let softY: CGFloat = 4

        static let elevatedRadius: CGFloat = 16
        static let elevatedY: CGFloat = 8
    }

    // MARK: - Animation

    enum Animation {
        static let quick = SwiftUI.Animation.easeInOut(duration: 0.2)
        static let standard = SwiftUI.Animation.easeInOut(duration: 0.3)
        static let smooth = SwiftUI.Animation.easeInOut(duration: 0.4)
    }
}

// MARK: - Color Extension

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

// MARK: - Adaptive Colors

extension Color {
    /// Creates an adaptive color that changes based on color scheme
    static func adaptive(light: Color, dark: Color) -> Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(dark)
                : UIColor(light)
        })
    }
}

// MARK: - Theme Environment

private struct ThemeColorsKey: EnvironmentKey {
    static let defaultValue = ThemeColors()
}

struct ThemeColors {
    let background: Color
    let surface: Color
    let surfaceElevated: Color
    let primary: Color
    let secondary: Color
    let accent: Color
    let textPrimary: Color
    let textSecondary: Color
    let textTertiary: Color
    let success: Color
    let warning: Color
    let error: Color

    init() {
        self.background = .adaptive(
            light: AppTheme.Colors.Fallback.backgroundLight,
            dark: AppTheme.Colors.Fallback.backgroundDark
        )
        self.surface = .adaptive(
            light: AppTheme.Colors.Fallback.surfaceLight,
            dark: AppTheme.Colors.Fallback.surfaceDark
        )
        self.surfaceElevated = .adaptive(
            light: AppTheme.Colors.Fallback.surfaceElevatedLight,
            dark: AppTheme.Colors.Fallback.surfaceElevatedDark
        )
        self.primary = .adaptive(
            light: AppTheme.Colors.Fallback.primaryLight,
            dark: AppTheme.Colors.Fallback.primaryDark
        )
        self.secondary = .adaptive(
            light: AppTheme.Colors.Fallback.secondaryLight,
            dark: AppTheme.Colors.Fallback.secondaryDark
        )
        self.accent = .adaptive(
            light: AppTheme.Colors.Fallback.accentLight,
            dark: AppTheme.Colors.Fallback.accentDark
        )
        self.textPrimary = .adaptive(
            light: AppTheme.Colors.Fallback.textPrimaryLight,
            dark: AppTheme.Colors.Fallback.textPrimaryDark
        )
        self.textSecondary = .adaptive(
            light: AppTheme.Colors.Fallback.textSecondaryLight,
            dark: AppTheme.Colors.Fallback.textSecondaryDark
        )
        self.textTertiary = .adaptive(
            light: AppTheme.Colors.Fallback.textTertiaryLight,
            dark: AppTheme.Colors.Fallback.textTertiaryDark
        )
        self.success = AppTheme.Colors.Fallback.success
        self.warning = AppTheme.Colors.Fallback.warning
        self.error = AppTheme.Colors.Fallback.error
    }
}

extension EnvironmentValues {
    var themeColors: ThemeColors {
        get { self[ThemeColorsKey.self] }
        set { self[ThemeColorsKey.self] = newValue }
    }
}

// MARK: - Reusable View Modifiers

struct CardStyle: ViewModifier {
    @Environment(\.colorScheme) var colorScheme

    func body(content: Content) -> some View {
        content
            .background(
                Color.adaptive(
                    light: AppTheme.Colors.Fallback.surfaceLight,
                    dark: AppTheme.Colors.Fallback.surfaceDark
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large))
            .shadow(
                color: .black.opacity(colorScheme == .dark ? 0.3 : 0.08),
                radius: AppTheme.Shadow.softRadius,
                x: 0,
                y: AppTheme.Shadow.softY
            )
    }
}

struct PillButtonStyle: ViewModifier {
    let isSelected: Bool
    @Environment(\.colorScheme) var colorScheme

    func body(content: Content) -> some View {
        content
            .font(AppTheme.Typography.callout)
            .padding(.horizontal, AppTheme.Spacing.md)
            .padding(.vertical, AppTheme.Spacing.xs)
            .background(
                isSelected
                    ? Color.adaptive(
                        light: AppTheme.Colors.Fallback.primaryLight,
                        dark: AppTheme.Colors.Fallback.primaryDark
                    )
                    : Color.adaptive(
                        light: AppTheme.Colors.Fallback.surfaceElevatedLight,
                        dark: AppTheme.Colors.Fallback.surfaceElevatedDark
                    )
            )
            .foregroundStyle(
                isSelected
                    ? .white
                    : Color.adaptive(
                        light: AppTheme.Colors.Fallback.textSecondaryLight,
                        dark: AppTheme.Colors.Fallback.textSecondaryDark
                    )
            )
            .clipShape(Capsule())
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardStyle())
    }

    func pillButton(isSelected: Bool) -> some View {
        modifier(PillButtonStyle(isSelected: isSelected))
    }
}

// MARK: - Entry Type Color Helper

extension String {
    var entryTypeColor: Color {
        switch self {
        case "vocab":
            return AppTheme.Colors.Fallback.vocab
        case "phrase":
            return AppTheme.Colors.Fallback.phrase
        case "sentence":
            return AppTheme.Colors.Fallback.sentence
        default:
            return AppTheme.Colors.Fallback.textSecondaryLight
        }
    }
}

// MARK: - JLPT Level Color Helper

extension String {
    var jlptColor: Color {
        switch self.uppercased() {
        case "N5":
            return AppTheme.Colors.Fallback.jlptN5
        case "N4":
            return AppTheme.Colors.Fallback.jlptN4
        case "N3":
            return AppTheme.Colors.Fallback.jlptN3
        case "N2":
            return AppTheme.Colors.Fallback.jlptN2
        case "N1":
            return AppTheme.Colors.Fallback.jlptN1
        default:
            return AppTheme.Colors.Fallback.textSecondaryLight
        }
    }
}
