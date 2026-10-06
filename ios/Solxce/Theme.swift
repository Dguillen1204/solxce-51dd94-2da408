// Theme.swift
import SwiftUI
import UIKit

/// Appearance selection setting persisted in AppStorage
public enum AppAppearance: String, CaseIterable, Identifiable {
    case system = "system"
    case dark = "dark"
    case light = "light"

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .system: return "System"
        case .dark: return "Dark"
        case .light: return "Light"
        }
    }

    public var iconName: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .dark: return "moon.stars.fill"
        case .light: return "sun.max.fill"
        }
    }

    public var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .dark: return .dark
        case .light: return .light
        }
    }
}

/// Dynamic Vibrant App Accent Palette Engine
public enum AppAccentColor: String, CaseIterable, Identifiable {
    case volt = "volt"
    case cyan = "cyan"
    case crimson = "crimson"
    case violet = "violet"
    case solarOrange = "solar_orange"
    case emerald = "emerald"
    case electricPink = "electric_pink"
    case monochrome = "monochrome"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .volt: return "Apex Volt"
        case .cyan: return "Cyber Cyan"
        case .crimson: return "Crimson Pulse"
        case .violet: return "Ultra Violet"
        case .solarOrange: return "Solar Orange"
        case .emerald: return "Apex Emerald"
        case .electricPink: return "Electric Pink"
        case .monochrome: return "Pure Monochrome"
        }
    }

    public var description: String {
        switch self {
        case .volt: return "High-octane neon lime & volt energy"
        case .cyan: return "Hyper-clean electric cyan blue"
        case .crimson: return "High-intensity athletic laser red"
        case .violet: return "Futuristic neon purple telemetry"
        case .solarOrange: return "Blazing kinetic thermal amber"
        case .emerald: return "Pure bio-luminescent radiant green"
        case .electricPink: return "High-voltage vivid magenta flare"
        case .monochrome: return "Minimalist platinum & obsidian white"
        }
    }

    public var hexCode: String {
        switch self {
        case .volt: return "#CCFF00"
        case .cyan: return "#06B6D4"
        case .crimson: return "#F43F5E"
        case .violet: return "#8B5CF6"
        case .solarOrange: return "#F97316"
        case .emerald: return "#10B981"
        case .electricPink: return "#EC4899"
        case .monochrome: return "#FFFFFF"
        }
    }

    public var color: Color {
        Color(hex: hexCode)
    }

    public var gradient: LinearGradient {
        switch self {
        case .volt:
            return LinearGradient(colors: [Color(hex: "#CCFF00"), Color(hex: "#84CC16")], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .cyan:
            return LinearGradient(colors: [Color(hex: "#06B6D4"), Color(hex: "#3B82F6")], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .crimson:
            return LinearGradient(colors: [Color(hex: "#F43F5E"), Color(hex: "#E11D48")], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .violet:
            return LinearGradient(colors: [Color(hex: "#8B5CF6"), Color(hex: "#6366F1")], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .solarOrange:
            return LinearGradient(colors: [Color(hex: "#FB923C"), Color(hex: "#EA580C")], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .emerald:
            return LinearGradient(colors: [Color(hex: "#34D399"), Color(hex: "#059669")], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .electricPink:
            return LinearGradient(colors: [Color(hex: "#F472B6"), Color(hex: "#DB2777")], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .monochrome:
            return LinearGradient(colors: [Color.white, Color(hex: "#CBD5E1")], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
}

/// Centralized Design System tokens for Solxce
public enum AppTheme {
    public static let activeAccentKey = "solxce_app_accent_color"

    // MARK: - Active Dynamic Accent Getter
    public static var activeAccent: AppAccentColor {
        let raw = UserDefaults.standard.string(forKey: activeAccentKey) ?? AppAccentColor.volt.rawValue
        return AppAccentColor(rawValue: raw) ?? .volt
    }

    // MARK: - Adaptive Color Helper
    public static func dynamicColor(light: UIColor, dark: UIColor) -> Color {
        Color(UIColor { trait in
            trait.userInterfaceStyle == .dark ? dark : light
        })
    }

    // MARK: - Core Colors
    /// Primary Dynamic Accent / High-Contrast Theme Color
    public static var primary: Color {
        accent
    }

    /// Dynamic Vibrant Accent Color
    public static var accent: Color {
        activeAccent.color
    }

    /// Dynamic Linear Gradient for active accent
    public static var accentGradient: LinearGradient {
        activeAccent.gradient
    }

    /// Constant Vibrant Palettes
    public static let volt = Color(hex: "#CCFF00")
    public static let cyan = Color(hex: "#06B6D4")
    public static let crimson = Color(hex: "#F43F5E")
    public static let violet = Color(hex: "#8B5CF6")
    public static let solarOrange = Color(hex: "#F97316")
    public static let emerald = Color(hex: "#10B981")
    public static let electricPink = Color(hex: "#EC4899")
    public static let specularWhite = Color(hex: "#FFFFFF")
    public static let platinum = Color(hex: "#E2E8F0")
    public static let silver = Color(hex: "#94A3B8")
    public static let darkCharcoal = Color(hex: "#1E1E24")

    public static let primaryVolt = Color(hex: "#CCFF00")
    public static let neonLime = Color(hex: "#CCFF00")

    /// Base canvas background: True Black (#000000)
    public static let ground = dynamicColor(
        light: UIColor(red: 0.965, green: 0.965, blue: 0.975, alpha: 1.0),
        dark: UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
    )

    /// Card surfaces: Deep Obsidian (#121212)
    public static let surface = dynamicColor(
        light: UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0),
        dark: UIColor(red: 0.071, green: 0.071, blue: 0.071, alpha: 1.0)
    )

    /// Elevated surfaces: Refined Charcoal (#1C1C1C)
    public static let surfaceRaised = dynamicColor(
        light: UIColor(red: 0.93, green: 0.93, blue: 0.95, alpha: 1.0),
        dark: UIColor(red: 0.110, green: 0.110, blue: 0.110, alpha: 1.0)
    )

    /// Backward compatibility alias for elevated / raised surfaces
    public static var elevated: Color { surfaceRaised }

    /// Input fields & subtle chips (#222224)
    public static let field = dynamicColor(
        light: UIColor(red: 0.90, green: 0.90, blue: 0.93, alpha: 1.0),
        dark: UIColor(red: 0.133, green: 0.133, blue: 0.141, alpha: 1.0)
    )

    /// Hairline borders (Subtle obsidian shimmer)
    public static let hairline = dynamicColor(
        light: UIColor(white: 0.0, alpha: 0.08),
        dark: UIColor(white: 1.0, alpha: 0.12)
    )

    /// Primary Typography: High Contrast Text (Black in Light mode, White in Dark mode)
    public static let text = dynamicColor(
        light: UIColor(red: 0.05, green: 0.05, blue: 0.06, alpha: 1.0),
        dark: UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
    )

    /// Secondary Typography: Platinum Muted (Dark Slate in Light mode, Soft Gray in Dark mode)
    public static let textSecondary = dynamicColor(
        light: UIColor(red: 0.35, green: 0.37, blue: 0.42, alpha: 1.0),
        dark: UIColor(red: 0.75, green: 0.78, blue: 0.84, alpha: 1.0)
    )

    /// Muted/Disabled Typography (Medium Gray in Light mode, Slate Gray in Dark mode)
    public static let textMuted = dynamicColor(
        light: UIColor(red: 0.52, green: 0.54, blue: 0.60, alpha: 1.0),
        dark: UIColor(red: 0.50, green: 0.53, blue: 0.58, alpha: 1.0)
    )

    /// Text sitting on top of primary button
    public static let onPrimary = dynamicColor(
        light: UIColor.white,
        dark: UIColor.black
    )

    // MARK: - Telemetry & Macro Semantics
    public static let caloriesColor = Color(hex: "#F97316") // Amber Flame
    public static let proteinColor = Color(hex: "#06B6D4")  // Cyan
    public static let carbsColor = Color(hex: "#CCFF00")    // Volt
    public static let fatColor = Color(hex: "#EC4899")      // Pink

    // MARK: - Spacing Grid
    public enum Spacing {
        public static let xxs: CGFloat = 4
        public static let xs: CGFloat = 8
        public static let sm: CGFloat = 12
        public static let md: CGFloat = 16
        public static let lg: CGFloat = 20
        public static let xl: CGFloat = 24
        public static let xxl: CGFloat = 32
        public static let huge: CGFloat = 48
        public static let screenMargin: CGFloat = 16
    }

    // MARK: - Radii
    public enum Radii {
        public static let button: CGFloat = 12
        public static let card: CGFloat = 14
        public static let sheet: CGFloat = 20
        public static let tag: CGFloat = 8
    }

    // Backward compatibility alias for corner radius constants
    public enum CornerRadius {
        public static let button: CGFloat = 12
        public static let card: CGFloat = 14
        public static let sheet: CGFloat = 20
        public static let tag: CGFloat = 8
    }

    // MARK: - Typographic Ramp
    public static let displayFont: Font = .system(size: 32, weight: .black, design: .default)
    public static let heroNumeralFont: Font = .system(size: 44, weight: .black, design: .rounded)
    public static let largeTitleFont: Font = .system(size: 28, weight: .bold, design: .default)
    public static let titleFont: Font = .system(size: 20, weight: .bold, design: .default)
    public static let headlineFont: Font = .system(size: 17, weight: .semibold, design: .default)
    public static let bodyFont: Font = .system(size: 16, weight: .regular, design: .default)
    public static let subheadlineFont: Font = .system(size: 14, weight: .medium, design: .default)
    public static let captionFont: Font = .system(size: 12, weight: .regular, design: .default)
    public static let eyebrowFont: Font = .system(size: 11, weight: .bold, design: .default)
    public static let monoFont: Font = .system(size: 13, weight: .semibold, design: .monospaced)
}

// MARK: - Color Hex Initializer Extension
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
