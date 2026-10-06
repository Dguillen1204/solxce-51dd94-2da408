// Views/AICoachChatView.swift
import SwiftUI

struct AICoachChatView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var engine = AICoachEngine()
    @State private var inputText: String = ""
    @FocusState private var isInputFocused: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.ground.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Chat message stream
                    ScrollViewReader { proxy in
                        ScrollView {
                            VStack(spacing: AppTheme.Spacing.md) {
                                // Coach Header badge
                                coachInfoBanner

                                ForEach(engine.messages) { message in
                                    MessageBubbleView(message: message) { suggestion in
                                        handlePromptSelection(suggestion)
                                    }
                                    .id(message.id)
                                }

                                if engine.isThinking {
                                    thinkingIndicator
                                        .id("thinking_indicator")
                                }
                            }
                            .padding(.horizontal, AppTheme.Spacing.screenMargin)
                            .padding(.top, AppTheme.Spacing.md)
                            .padding(.bottom, AppTheme.Spacing.lg)
                        }
                        .onChange(of: engine.messages.count) { _, _ in
                            scrollToBottom(proxy: proxy)
                        }
                        .onChange(of: engine.isThinking) { _, isThinking in
                            if isThinking {
                                withAnimation {
                                    proxy.scrollTo("thinking_indicator", anchor: .bottom)
                                }
                            }
                        }
                    }

                    // Prompt Suggestion Strip
                    if !engine.isThinking {
                        quickPromptRail
                    }

                    // Bottom Composer Bar
                    composerBar
                }
            }
            .navigationTitle("Solxce AI Coach")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        engine.clearChat()
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(AppTheme.textMuted)
                    }
                    .accessibilityLabel("Clear conversation")
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                }
            }
        }
    }

    // MARK: - Coach Info Banner
    private var coachInfoBanner: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            ZStack {
                Circle()
                    .fill(AppTheme.primary.opacity(0.15))
                    .frame(width: 38, height: 38)

                Image(systemName: "sparkles")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(AppTheme.primary)
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text("SOLXCE AI INTELLIGENCE")
                        .font(AppTheme.eyebrowFont)
                        .tracking(1.2)
                        .foregroundStyle(AppTheme.primary)

                    Circle()
                        .fill(AppTheme.primary)
                        .frame(width: 6, height: 6)
                }

                Text("Instant answers for training, macros, running & recovery")
                    .font(.system(size: 12))
                    .foregroundStyle(AppTheme.textSecondary)
            }

            Spacer()
        }
        .padding(AppTheme.Spacing.sm)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.card))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radii.card)
                .stroke(AppTheme.hairline, lineWidth: 1)
        )
    }

    // MARK: - Quick Prompt Suggestion Rail
    private var quickPromptRail: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppTheme.Spacing.xs) {
                ForEach(AICoachEngine.defaultPrompts, id: \.title) { item in
                    Button {
                        handlePromptSelection(item.prompt)
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: item.icon)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(AppTheme.primary)

                            Text(item.title)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(AppTheme.text)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(AppTheme.surfaceRaised)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(AppTheme.hairline, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, AppTheme.Spacing.screenMargin)
            .padding(.vertical, 6)
        }
    }

    // MARK: - Thinking Animation
    private var thinkingIndicator: some View {
        HStack {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(AppTheme.primary)

                Text("Coach is analyzing...")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(AppTheme.textSecondary)

                ProgressView()
                    .tint(AppTheme.primary)
                    .scaleEffect(0.7)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(AppTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(AppTheme.primary.opacity(0.3), lineWidth: 1)
            )

            Spacer()
        }
    }

    // MARK: - Composer Bar
    private var composerBar: some View {
        VStack(spacing: 0) {
            Divider()
                .background(AppTheme.hairline)

            HStack(spacing: AppTheme.Spacing.xs) {
                HStack {
                    Image(systemName: "sparkle")
                        .font(.system(size: 14))
                        .foregroundStyle(AppTheme.primary)

                    TextField("Ask about workouts, macros, running...", text: $inputText, axis: .vertical)
                        .lineLimit(1...4)
                        .font(AppTheme.bodyFont)
                        .foregroundStyle(AppTheme.text)
                        .focused($isInputFocused)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(AppTheme.field)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(isInputFocused ? AppTheme.primary.opacity(0.6) : AppTheme.hairline, lineWidth: 1)
                )

                // Send Button
                Button {
                    sendCurrentInput()
                } label: {
                    ZStack {
                        Circle()
                            .fill(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? AppTheme.surfaceRaised : AppTheme.primary)
                            .frame(width: 40, height: 40)

                        Image(systemName: "arrow.up")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? AppTheme.textMuted : AppTheme.onPrimary)
                    }
                }
                .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || engine.isThinking)
            }
            .padding(.horizontal, AppTheme.Spacing.screenMargin)
            .padding(.vertical, 10)
            .background(AppTheme.ground)
        }
    }

    private func sendCurrentInput() {
        let text = inputText
        inputText = ""
        Task {
            await engine.sendMessage(text)
        }
    }

    private func handlePromptSelection(_ prompt: String) {
        Task {
            await engine.sendMessage(prompt)
        }
    }

    private func scrollToBottom(proxy: ScrollViewProxy) {
        if let lastId = engine.messages.last?.id {
            withAnimation(.easeOut(duration: 0.25)) {
                proxy.scrollTo(lastId, anchor: .bottom)
            }
        }
    }
}

// MARK: - Message Bubble Component
struct MessageBubbleView: View {
    let message: AICoachMessage
    let onSelectSuggestion: (String) -> Void

    var body: some View {
        HStack(alignment: .top, spacing: AppTheme.Spacing.xs) {
            if message.sender == .coach {
                ZStack {
                    Circle()
                        .fill(AppTheme.primary)
                        .frame(width: 30, height: 30)

                    Image(systemName: "sparkles")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(AppTheme.onPrimary)
                }
                .padding(.top, 2)
            } else {
                Spacer(minLength: 40)
            }

            VStack(alignment: message.sender == .coach ? .leading : .trailing, spacing: AppTheme.Spacing.xs) {
                // Sender label & category tag
                if message.sender == .coach {
                    HStack(spacing: 6) {
                        Text("SOLXCE COACH")
                            .font(AppTheme.eyebrowFont)
                            .tracking(1)
                            .foregroundStyle(AppTheme.primary)

                        if let category = message.category {
                            Text("• \(category.rawValue)")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(AppTheme.textMuted)
                        }
                    }
                }

                // Message Text Bubble
                VStack(alignment: .leading, spacing: 6) {
                    Text(parseMarkdownText(message.text))
                        .font(.system(size: 15))
                        .lineSpacing(3)
                        .foregroundStyle(message.sender == .user ? AppTheme.onPrimary : AppTheme.text)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(
                    message.sender == .user
                        ? AppTheme.primary
                        : AppTheme.surface
                )
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: 16
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            message.sender == .user ? Color.clear : AppTheme.hairline,
                            lineWidth: 1
                        )
                )

                // Follow-up Suggestions
                if message.sender == .coach && !message.suggestions.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Suggested follow-ups:")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(AppTheme.textMuted)
                            .padding(.top, 4)

                        FlowLayout(spacing: 6) {
                            ForEach(message.suggestions, id: \.self) { suggestion in
                                Button {
                                    onSelectSuggestion(suggestion)
                                } label: {
                                    HStack(spacing: 4) {
                                        Text(suggestion)
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundStyle(AppTheme.text)

                                        Image(systemName: "arrow.up.right")
                                            .font(.system(size: 9, weight: .bold))
                                            .foregroundStyle(AppTheme.primary)
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(AppTheme.surfaceRaised)
                                    .clipShape(Capsule())
                                    .overlay(
                                        Capsule()
                                            .stroke(AppTheme.hairline, lineWidth: 1)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }

            if message.sender == .user {
                ZStack {
                    Circle()
                        .fill(AppTheme.surfaceRaised)
                        .frame(width: 30, height: 30)

                    Image(systemName: "person.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(AppTheme.primary)
                }
                .padding(.top, 2)
            } else {
                Spacer(minLength: 24)
            }
        }
    }

    private func parseMarkdownText(_ text: String) -> LocalizedStringKey {
        LocalizedStringKey(text)
    }
}

// MARK: - Flow Layout for Suggestion Tags
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 320
        var height: CGFloat = 0
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > width {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
        }

        height = currentY + lineHeight
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var currentX: CGFloat = bounds.minX
        var currentY: CGFloat = bounds.minY
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > bounds.maxX {
                currentX = bounds.minX
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            subview.place(at: CGPoint(x: currentX, y: currentY), proposal: .unspecified)
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
        }
    }
}
