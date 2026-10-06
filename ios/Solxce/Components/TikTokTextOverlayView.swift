// Components/TikTokTextOverlayView.swift
import SwiftUI

/// TikTok-style text sticker styling models
public enum TikTokFontStyle: String, CaseIterable, Identifiable {
    case classic = "Classic"
    case typewriter = "Typewriter"
    case neon = "Neon"
    case heavy = "Heavy"
    case handwriting = "Script"
    case italic = "Italic"

    public var id: String { rawValue }

    public func font(size: CGFloat) -> Font {
        switch self {
        case .classic:
            return .system(size: size, weight: .bold, design: .default)
        case .typewriter:
            return .system(size: size, weight: .bold, design: .monospaced)
        case .neon:
            return .system(size: size, weight: .heavy, design: .rounded)
        case .heavy:
            return .system(size: size, weight: .black, design: .default)
        case .handwriting:
            return .system(size: size, weight: .semibold, design: .serif)
        case .italic:
            return .system(size: size, weight: .bold, design: .default).italic()
        }
    }
}

public enum TikTokHighlightMode: String, CaseIterable, Identifiable {
    case filled = "Filled"        // Solid contrasting pill/box (classic TikTok)
    case outline = "Outline"      // Translucent glass box with border
    case transparent = "None"     // Just raw text with deep drop shadow
    case inverted = "Inverted"    // White/black swapped punchout

    public var id: String { rawValue }

    public var iconName: String {
        switch self {
        case .filled: return "character.textbox"
        case .outline: return "square.dashed"
        case .transparent: return "textformat"
        case .inverted: return "circle.lefthalf.filled"
        }
    }
}

public struct TikTokColorOption: Identifiable {
    public let id: String
    public let name: String
    public let color: Color
    public let hex: String

    public init(name: String, hex: String) {
        self.id = hex
        self.name = name
        self.hex = hex
        self.color = Color(hex: hex)
    }

    public static let defaultOptions: [TikTokColorOption] = [
        TikTokColorOption(name: "White", hex: "#FFFFFF"),
        TikTokColorOption(name: "Volt Lime", hex: "#CCFF00"),
        TikTokColorOption(name: "Solar Orange", hex: "#FF6B00"),
        TikTokColorOption(name: "Electric Pink", hex: "#FF2E93"),
        TikTokColorOption(name: "Cyan", hex: "#00E5FF"),
        TikTokColorOption(name: "Purple", hex: "#A855F7"),
        TikTokColorOption(name: "Crimson", hex: "#EF4444"),
        TikTokColorOption(name: "Obsidian", hex: "#000000")
    ]
}

public struct TikTokTextStickerData: Codable, Equatable {
    public var text: String
    public var fontStyle: String // TikTokFontStyle rawValue
    public var highlightMode: String // TikTokHighlightMode rawValue
    public var colorHex: String
    public var fontSize: CGFloat
    public var alignment: String // "center", "leading", "trailing"
    public var xOffset: CGFloat
    public var yOffset: CGFloat
    public var rotationDegrees: Double
    public var scale: CGFloat

    public init(
        text: String = "",
        fontStyle: String = TikTokFontStyle.neon.rawValue,
        highlightMode: String = TikTokHighlightMode.filled.rawValue,
        colorHex: String = "#FFFFFF",
        fontSize: CGFloat = 16,
        alignment: String = "center",
        xOffset: CGFloat = 0,
        yOffset: CGFloat = 0,
        rotationDegrees: Double = 0,
        scale: CGFloat = 1.0
    ) {
        self.text = text
        self.fontStyle = fontStyle
        self.highlightMode = highlightMode
        self.colorHex = colorHex
        self.fontSize = fontSize
        self.alignment = alignment
        self.xOffset = xOffset
        self.yOffset = yOffset
        self.rotationDegrees = rotationDegrees
        self.scale = scale
    }

    public var parsedFontStyle: TikTokFontStyle {
        TikTokFontStyle(rawValue: fontStyle) ?? .neon
    }

    public var parsedHighlightMode: TikTokHighlightMode {
        TikTokHighlightMode(rawValue: highlightMode) ?? .filled
    }

    public var textColor: Color {
        Color(hex: colorHex)
    }

    public var textAlignment: TextAlignment {
        switch alignment {
        case "leading": return .leading
        case "trailing": return .trailing
        default: return .center
        }
    }
}

// MARK: - TikTok Text Badge Display Component (High Visibility Everywhere)
public struct TikTokTextBadgeView: View {
    public let text: String
    public var fontStyle: TikTokFontStyle = .neon
    public var highlightMode: TikTokHighlightMode = .filled
    public var textColor: Color = .white
    public var fontSize: CGFloat = 14
    public var alignment: TextAlignment = .center

    public init(
        text: String,
        fontStyle: TikTokFontStyle = .neon,
        highlightMode: TikTokHighlightMode = .filled,
        textColor: Color = .white,
        fontSize: CGFloat = 14,
        alignment: TextAlignment = .center
    ) {
        self.text = text
        self.fontStyle = fontStyle
        self.highlightMode = highlightMode
        self.textColor = textColor
        self.fontSize = fontSize
        self.alignment = alignment
    }

    public var body: some View {
        if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            Group {
                switch highlightMode {
                case .filled:
                    // TikTok style solid high-contrast black capsule with crisp glow
                    Text(text)
                        .font(fontStyle.font(size: fontSize))
                        .multilineTextAlignment(alignment)
                        .foregroundColor(textColor == .black ? .white : textColor)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(
                            ZStack {
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(Color.black.opacity(0.88))
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(textColor.opacity(0.4), lineWidth: 1.5)
                            }
                        )
                        .shadow(color: Color.black.opacity(0.8), radius: 8, x: 0, y: 3)

                case .inverted:
                    // Swapped color punchout: colorful background with punchy black text
                    Text(text)
                        .font(fontStyle.font(size: fontSize))
                        .multilineTextAlignment(alignment)
                        .foregroundColor(.black)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(textColor == .black ? Color.white : textColor)
                        )
                        .shadow(color: Color.black.opacity(0.6), radius: 8, x: 0, y: 3)

                case .outline:
                    // Glass border with dark blur background
                    Text(text)
                        .font(fontStyle.font(size: fontSize))
                        .multilineTextAlignment(alignment)
                        .foregroundColor(textColor)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Color.black.opacity(0.55))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(textColor, lineWidth: 2)
                        )
                        .shadow(color: Color.black.opacity(0.7), radius: 6, x: 0, y: 2)

                case .transparent:
                    // Raw text with deep multi-layer drop shadow for 100% legibility on any background
                    Text(text)
                        .font(fontStyle.font(size: fontSize))
                        .multilineTextAlignment(alignment)
                        .foregroundColor(textColor)
                        .shadow(color: Color.black, radius: 4, x: 0, y: 2)
                        .shadow(color: Color.black, radius: 10, x: 0, y: 4)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                }
            }
        }
    }
}
