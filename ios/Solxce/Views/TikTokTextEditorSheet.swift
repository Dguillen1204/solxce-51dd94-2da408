// Views/TikTokTextEditorSheet.swift
import SwiftUI

/// Full-screen interactive TikTok-style Text & Sticker Composer Sheet
public struct TikTokTextEditorSheet: View {
    @Environment(\.dismiss) private var dismiss

    @Binding var text: String
    @Binding var fontStyle: TikTokFontStyle
    @Binding var highlightMode: TikTokHighlightMode
    @Binding var selectedColorHex: String
    @Binding var fontSize: CGFloat
    @Binding var alignment: TextAlignment

    @FocusState private var isTextFieldFocused: Bool

    private let colors = TikTokColorOption.defaultOptions

    public var body: some View {
        ZStack {
            // Dark dimming canvas
            Color.black.opacity(0.85)
                .ignoresSafeArea()
                .onTapGesture {
                    isTextFieldFocused = false
                }

            VStack(spacing: 0) {
                // Top Control Bar (Done & Alignment & Background Mode)
                HStack(spacing: 16) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))

                    Spacer()

                    // Text Alignment toggle
                    Button {
                        cycleAlignment()
                    } label: {
                        Image(systemName: alignmentIcon)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 38, height: 38)
                            .background(Color.white.opacity(0.18))
                            .clipShape(Circle())
                    }

                    // Highlight Mode (A) button
                    Button {
                        cycleHighlightMode()
                    } label: {
                        ZStack {
                            Circle()
                                .fill(highlightMode == .filled ? Color.white : Color.white.opacity(0.18))
                                .frame(width: 38, height: 38)
                            Text("A")
                                .font(.system(size: 16, weight: .heavy, design: .rounded))
                                .foregroundColor(highlightMode == .filled ? .black : .white)
                        }
                    }

                    // Done Commit Button
                    Button {
                        dismiss()
                    } label: {
                        Text("Done")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.black)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color(hex: "#CCFF00"))
                            .clipShape(Capsule())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)

                Spacer()

                // Live Interactive Text Area (Center of screen)
                VStack(spacing: 12) {
                    TextField("Type something...", text: $text, axis: .vertical)
                        .focused($isTextFieldFocused)
                        .multilineTextAlignment(alignment)
                        .font(fontStyle.font(size: max(22, fontSize)))
                        .foregroundColor(
                            highlightMode == .inverted ? .black : (selectedColorHex == "#000000" && highlightMode == .filled ? .white : Color(hex: selectedColorHex))
                        )
                        .padding(.horizontal, 18)
                        .padding(.vertical, 10)
                        .background(
                            backgroundForText()
                        )
                        .frame(maxWidth: 320)
                }
                .padding(.horizontal, 24)

                Spacer()

                // Bottom Controls: Font selector & Color Palette & Size Slider
                VStack(spacing: 14) {
                    // Font Style Carousel (TikTok style)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(TikTokFontStyle.allCases) { style in
                                Button {
                                    fontStyle = style
                                } label: {
                                    Text(style.rawValue)
                                        .font(style.font(size: 14))
                                        .foregroundColor(fontStyle == style ? .black : .white)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 8)
                                        .background(fontStyle == style ? Color.white : Color.white.opacity(0.15))
                                        .clipShape(Capsule())
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }

                    // Font Size Slider
                    HStack(spacing: 12) {
                        Image(systemName: "textformat.size.smaller")
                            .foregroundColor(.white.opacity(0.7))
                            .font(.system(size: 14))

                        Slider(value: $fontSize, in: 14...32, step: 1)
                            .tint(Color(hex: "#CCFF00"))

                        Image(systemName: "textformat.size.larger")
                            .foregroundColor(.white.opacity(0.7))
                            .font(.system(size: 18))
                    }
                    .padding(.horizontal, 24)

                    // Color Palette Selector Dots
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 14) {
                            ForEach(colors) { option in
                                Button {
                                    selectedColorHex = option.hex
                                } label: {
                                    ZStack {
                                        Circle()
                                            .fill(option.color)
                                            .frame(width: 32, height: 32)
                                            .overlay(
                                                Circle()
                                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                            )

                                        if selectedColorHex == option.hex {
                                            Circle()
                                                .stroke(Color.white, lineWidth: 3)
                                                .frame(width: 38, height: 38)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 12)
                    }
                }
                .padding(.vertical, 12)
                .background(Color.black.opacity(0.7))
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isTextFieldFocused = true
            }
        }
    }

    private func cycleAlignment() {
        switch alignment {
        case .leading: alignment = .center
        case .center: alignment = .trailing
        case .trailing: alignment = .leading
        }
    }

    private var alignmentIcon: String {
        switch alignment {
        case .leading: return "text.alignleft"
        case .center: return "text.aligncenter"
        case .trailing: return "text.alignright"
        }
    }

    private func cycleHighlightMode() {
        switch highlightMode {
        case .filled: highlightMode = .inverted
        case .inverted: highlightMode = .outline
        case .outline: highlightMode = .transparent
        case .transparent: highlightMode = .filled
        }
    }

    @ViewBuilder
    private func backgroundForText() -> some View {
        switch highlightMode {
        case .filled:
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.black.opacity(0.9))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Color(hex: selectedColorHex).opacity(0.5), lineWidth: 1.5)
                )
        case .inverted:
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(hex: selectedColorHex))
        case .outline:
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.black.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Color(hex: selectedColorHex), lineWidth: 2)
                )
        case .transparent:
            Color.clear
        }
    }
}
