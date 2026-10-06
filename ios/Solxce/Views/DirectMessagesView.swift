// Views/DirectMessagesView.swift
import SwiftUI

// MARK: - Direct Messages Inbox
struct DirectMessagesListView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var socialManager = SocialPrivacyManager.shared

    @State private var searchText = ""
    @State private var showingNewMessageSheet = false
    @State private var selectedConversation: AthleteConversation?

    private var filteredConversations: [AthleteConversation] {
        socialManager.conversations.filter { conv in
            !socialManager.isBlocked(handle: conv.participantHandle) &&
            (searchText.isEmpty ||
             conv.participantName.localizedCaseInsensitiveContains(searchText) ||
             conv.participantHandle.localizedCaseInsensitiveContains(searchText) ||
             conv.lastMessageText.localizedCaseInsensitiveContains(searchText))
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search Bar
                searchHeader

                if filteredConversations.isEmpty {
                    emptyInboxView
                } else {
                    List {
                        ForEach(filteredConversations) { conv in
                            Button {
                                selectedConversation = conv
                                socialManager.markConversationRead(handle: conv.participantHandle)
                            } label: {
                                conversationRow(conv)
                            }
                            .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
                            .listRowBackground(AppTheme.ground)
                            .listRowSeparatorTint(Color.white.opacity(0.08))
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    if let idx = socialManager.conversations.firstIndex(where: { $0.id == conv.id }) {
                                        withAnimation {
                                            socialManager.conversations.remove(at: idx)
                                        }
                                    }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .background(AppTheme.ground.ignoresSafeArea())
            .navigationTitle("Direct Messages")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingNewMessageSheet = true
                    } label: {
                        Image(systemName: "square.and.pencil")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(AppTheme.accent)
                    }
                }
            }
            .sheet(item: $selectedConversation) { conv in
                NavigationStack {
                    ChatConversationView(conversation: conv)
                }
            }
            .sheet(isPresented: $showingNewMessageSheet) {
                NewMessageRecipientSheet { athlete in
                    let conv = socialManager.getOrCreateConversation(with: athlete)
                    selectedConversation = conv
                }
            }
        }
    }

    // MARK: - Search Header
    private var searchHeader: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(AppTheme.textSecondary)
                .font(.system(size: 14))

            TextField("Search conversations or athletes...", text: $searchText)
                .font(AppTheme.bodyFont)
                .foregroundStyle(AppTheme.primary)

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(AppTheme.textSecondary)
                        .font(.system(size: 14))
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, AppTheme.Spacing.screenMargin)
        .padding(.vertical, 8)
    }

    // MARK: - Conversation Row
    private func conversationRow(_ conv: AthleteConversation) -> some View {
        HStack(spacing: 12) {
            // Avatar
            ZStack {
                Circle()
                    .stroke(conv.athleteType.badgeColor, lineWidth: 2)
                    .frame(width: 48, height: 48)

                Circle()
                    .fill(AppTheme.surfaceElevated)
                    .frame(width: 44, height: 44)

                Image(systemName: conv.avatarSymbol)
                    .font(.system(size: 20))
                    .foregroundStyle(conv.athleteType.badgeColor)
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(conv.participantName)
                        .font(AppTheme.headlineFont)
                        .foregroundStyle(AppTheme.primary)

                    Text("@\(conv.participantHandle)")
                        .font(AppTheme.captionFont)
                        .foregroundStyle(AppTheme.textSecondary)

                    Spacer()

                    Text(conv.lastMessageTimeFormatted)
                        .font(AppTheme.captionFont)
                        .foregroundStyle(AppTheme.textSecondary)
                }

                HStack {
                    Text(conv.lastMessageText)
                        .font(AppTheme.bodyFont)
                        .foregroundStyle(conv.unreadCount > 0 ? AppTheme.primary : AppTheme.textSecondary)
                        .lineLimit(1)

                    Spacer()

                    if conv.unreadCount > 0 {
                        Circle()
                            .fill(AppTheme.accent)
                            .frame(width: 8, height: 8)
                    }
                }
            }
        }
        .contentShape(Rectangle())
    }

    // MARK: - Empty Inbox
    private var emptyInboxView: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            Spacer()
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 48))
                .foregroundStyle(AppTheme.textSecondary.opacity(0.6))

            Text("No Messages Yet")
                .font(AppTheme.titleFont)
                .foregroundStyle(AppTheme.primary)

            Text("Connect with training partners, share workout logs, and talk programming.")
                .font(AppTheme.captionFont)
                .foregroundStyle(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button {
                showingNewMessageSheet = true
            } label: {
                Text("Start a Conversation")
                    .font(AppTheme.headlineFont)
                    .foregroundStyle(AppTheme.inverseText)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(AppTheme.accent)
                    .clipShape(Capsule())
            }
            .padding(.top, 8)

            Spacer()
        }
    }
}

// MARK: - Chat Conversation View
struct ChatConversationView: View {
    let conversation: AthleteConversation
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var socialManager = SocialPrivacyManager.shared

    @State private var messageText = ""
    @State private var showingAthleteProfile = false
    @State private var showingQuickWorkouts = false

    private var activeConversation: AthleteConversation {
        socialManager.conversation(for: conversation.participantHandle) ?? conversation
    }

    private var isBlocked: Bool {
        socialManager.isBlocked(handle: conversation.participantHandle)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Chat history
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        // Athlete Header Summary
                        athleteHeaderBrief

                        ForEach(activeConversation.messages) { message in
                            chatBubble(message)
                                .id(message.id)
                        }
                    }
                    .padding(.horizontal, AppTheme.Spacing.screenMargin)
                    .padding(.vertical, AppTheme.Spacing.md)
                }
                .onChange(of: activeConversation.messages.count) {
                    if let last = activeConversation.messages.last {
                        withAnimation(.easeOut(duration: 0.25)) {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
            }

            // Input Bar
            if isBlocked {
                blockedWarningBar
            } else {
                composerBar
            }
        }
        .background(AppTheme.ground.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }

            ToolbarItem(placement: .principal) {
                Button {
                    showingAthleteProfile = true
                } label: {
                    HStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(AppTheme.surfaceElevated)
                                .frame(width: 32, height: 32)
                            Image(systemName: activeConversation.avatarSymbol)
                                .font(.system(size: 14))
                                .foregroundStyle(activeConversation.athleteType.badgeColor)
                        }

                        VStack(alignment: .leading, spacing: 1) {
                            Text(activeConversation.participantName)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(AppTheme.primary)
                            Text("@\(activeConversation.participantHandle)")
                                .font(.system(size: 11))
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                    }
                }
            }

            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAthleteProfile = true
                } label: {
                    Image(systemName: "info.circle")
                        .font(.system(size: 16))
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }
        }
        .sheet(isPresented: $showingAthleteProfile) {
            OtherUserProfileView(athleteHandle: activeConversation.participantHandle)
        }
        .sheet(isPresented: $showingQuickWorkouts) {
            QuickShareWorkoutSheet { workoutSummary in
                socialManager.sendMessage(
                    text: "Shared a workout log: \(workoutSummary)",
                    to: activeConversation.participantHandle,
                    workoutShare: workoutSummary
                )
            }
        }
    }

    // MARK: - Athlete Header Brief
    private var athleteHeaderBrief: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(activeConversation.athleteType.badgeColor, lineWidth: 2)
                    .frame(width: 60, height: 60)
                Circle()
                    .fill(AppTheme.surfaceElevated)
                    .frame(width: 54, height: 54)
                Image(systemName: activeConversation.avatarSymbol)
                    .font(.system(size: 24))
                    .foregroundStyle(activeConversation.athleteType.badgeColor)
            }

            Text(activeConversation.participantName)
                .font(AppTheme.headlineFont)
                .foregroundStyle(AppTheme.primary)

            Text("@\(activeConversation.participantHandle) · \(activeConversation.athleteType.rawValue)")
                .font(AppTheme.captionFont)
                .foregroundStyle(AppTheme.textSecondary)

            Divider()
                .overlay(Color.white.opacity(0.08))
                .padding(.top, 8)
        }
        .padding(.vertical, 12)
    }

    // MARK: - Chat Bubble
    private func chatBubble(_ message: DirectMessage) -> some View {
        HStack(alignment: .bottom, spacing: 8) {
            if message.isFromCurrentUser {
                Spacer(minLength: 40)
            }

            VStack(alignment: message.isFromCurrentUser ? .trailing : .leading, spacing: 4) {
                if let share = message.workoutShareSummary {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 6) {
                            Image(systemName: "bolt.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(AppTheme.accent)
                            Text("Workout Highlight")
                                .font(.system(size: 11, weight: .heavy))
                                .foregroundStyle(AppTheme.accent)
                        }
                        Text(share)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(AppTheme.primary)
                    }
                    .padding(10)
                    .background(Color.black.opacity(0.3))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                Text(message.text)
                    .font(AppTheme.bodyFont)
                    .foregroundStyle(message.isFromCurrentUser ? AppTheme.inverseText : AppTheme.primary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        message.isFromCurrentUser
                            ? AppTheme.accent
                            : AppTheme.surfaceElevated
                    )
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: 16
                        )
                    )

                Text(formatTimestamp(message.timestamp))
                    .font(.system(size: 10))
                    .foregroundStyle(AppTheme.textSecondary.opacity(0.8))
                    .padding(.horizontal, 4)
            }

            if !message.isFromCurrentUser {
                Spacer(minLength: 40)
            }
        }
    }

    private func formatTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    // MARK: - Composer Bar
    private var composerBar: some View {
        VStack(spacing: 0) {
            Divider().overlay(Color.white.opacity(0.08))

            HStack(spacing: 10) {
                // Attach workout button
                Button {
                    showingQuickWorkouts = true
                } label: {
                    Image(systemName: "dumbbell.fill")
                        .font(.system(size: 17))
                        .foregroundStyle(AppTheme.accent)
                        .frame(width: 36, height: 36)
                        .background(AppTheme.surfaceElevated)
                        .clipShape(Circle())
                }

                // Text Input
                HStack {
                    TextField("Send message to @\(activeConversation.participantHandle)...", text: $messageText)
                        .font(AppTheme.bodyFont)
                        .foregroundStyle(AppTheme.primary)

                    if !messageText.isEmpty {
                        Button {
                            sendMessage()
                        } label: {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 26))
                                .foregroundStyle(AppTheme.accent)
                        }
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(AppTheme.surfaceElevated)
                .clipShape(Capsule())
            }
            .padding(.horizontal, AppTheme.Spacing.screenMargin)
            .padding(.vertical, 10)
            .background(AppTheme.surface)
        }
    }

    private var blockedWarningBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "hand.raised.fill")
                .foregroundStyle(Color(hex: "#FF3B5C"))
            Text("You have blocked this athlete. Unblock to message.")
                .font(AppTheme.captionFont)
                .foregroundStyle(AppTheme.textSecondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(AppTheme.surface)
    }

    private func sendMessage() {
        let text = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        socialManager.sendMessage(text: text, to: activeConversation.participantHandle)
        messageText = ""
    }
}

// MARK: - New Message Athlete Selector Sheet
struct NewMessageRecipientSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var socialManager = SocialPrivacyManager.shared
    let onSelect: (CommunityAthlete) -> Void

    @State private var search = ""

    private var availableAthletes: [CommunityAthlete] {
        Array(socialManager.communityAthletes.values)
            .filter { athlete in
                !socialManager.isBlocked(handle: athlete.handle) &&
                (search.isEmpty ||
                 athlete.name.localizedCaseInsensitiveContains(search) ||
                 athlete.handle.localizedCaseInsensitiveContains(search))
            }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(availableAthletes) { athlete in
                    Button {
                        onSelect(athlete)
                        dismiss()
                    } label: {
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(AppTheme.surfaceElevated)
                                    .frame(width: 44, height: 44)
                                Image(systemName: athlete.avatarSymbol)
                                    .font(.system(size: 18))
                                    .foregroundStyle(athlete.athleteType.badgeColor)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                HStack {
                                    Text(athlete.name)
                                        .font(AppTheme.headlineFont)
                                        .foregroundStyle(AppTheme.primary)
                                    if athlete.isVerifiedAthlete {
                                        Image(systemName: "checkmark.seal.fill")
                                            .font(.system(size: 12))
                                            .foregroundStyle(AppTheme.accent)
                                    }
                                }

                                Text("@\(athlete.handle) · \(athlete.athleteType.rawValue)")
                                    .font(AppTheme.captionFont)
                                    .foregroundStyle(AppTheme.textSecondary)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 12))
                                .foregroundStyle(AppTheme.textSecondary.opacity(0.5))
                        }
                    }
                    .listRowBackground(AppTheme.surface)
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppTheme.ground.ignoresSafeArea())
            .searchable(text: $search, prompt: "Search athletes to message...")
            .navigationTitle("New Message")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }
        }
    }
}

// MARK: - Quick Share Workout Sheet
struct QuickShareWorkoutSheet: View {
    @Environment(\.dismiss) private var dismiss
    let onShare: (String) -> Void

    let presetWorkouts = [
        "Heavy Bench Press: 315 lbs x 3 reps (PR!) 🔥",
        "Morning Trail Run: 6.2 miles @ 7:15 min/mi pace ⚡",
        "Leg Day Volume: 24,500 lbs total tonnage (Squats 405 x 4)",
        "Strict Ring Muscle-Up Complex: 5 unbroken sets 🦾"
    ]

    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Attach Today's Logged Performance").foregroundStyle(AppTheme.textSecondary)) {
                    ForEach(presetWorkouts, id: \.self) { workout in
                        Button {
                            onShare(workout)
                            dismiss()
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "dumbbell.fill")
                                    .foregroundStyle(AppTheme.accent)
                                Text(workout)
                                    .font(AppTheme.bodyFont)
                                    .foregroundStyle(AppTheme.primary)
                            }
                            .padding(.vertical, 4)
                        }
                        .listRowBackground(AppTheme.surface)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppTheme.ground.ignoresSafeArea())
            .navigationTitle("Share Workout Log")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }
        }
    }
}
