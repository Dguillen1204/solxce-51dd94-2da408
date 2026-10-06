// Views/DirectMessagesListView.swift
import SwiftUI

public struct DirectMessagesListView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var messagingStore = MessagingStore.shared
    @ObservedObject private var relationshipStore = SocialRelationshipStore.shared

    let currentUserHandle: String
    @State private var searchText: String = ""
    @State private var selectedConversation: ConversationSummary? = nil
    @State private var showingNewMessageSheet = false

    public init(currentUserHandle: String = "solxce_athlete") {
        self.currentUserHandle = currentUserHandle
    }

    private var conversations: [ConversationSummary] {
        let all = messagingStore.getConversations(currentUserHandle: currentUserHandle)
        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return all
        }
        return all.filter {
            $0.otherName.localizedCaseInsensitiveContains(searchText) ||
            $0.otherHandle.localizedCaseInsensitiveContains(searchText) ||
            $0.lastMessage.content.localizedCaseInsensitiveContains(searchText)
        }
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search Bar
                searchBar

                // Conversations List
                if conversations.isEmpty {
                    emptyMessagesPlaceholder
                } else {
                    List {
                        ForEach(conversations) { conv in
                            Button {
                                selectedConversation = conv
                            } label: {
                                conversationRow(conv)
                            }
                            .listRowBackground(AppTheme.ground)
                            .listRowSeparatorTint(AppTheme.hairline)
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
                    Button("Done") {
                        dismiss()
                    }
                    .font(AppTheme.headlineFont)
                    .foregroundStyle(AppTheme.primary)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingNewMessageSheet = true
                    } label: {
                        Image(systemName: "square.and.pencil")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(AppTheme.primary)
                    }
                }
            }
            .sheet(item: $selectedConversation) { conv in
                DirectMessageChatView(
                    otherHandle: conv.otherHandle,
                    otherName: conv.otherName,
                    athleteType: conv.athleteType,
                    currentUserHandle: currentUserHandle
                )
            }
            .sheet(isPresented: $showingNewMessageSheet) {
                NewMessagePickerSheet(
                    currentUserHandle: currentUserHandle,
                    onSelectAthlete: { handle, name, type in
                        selectedConversation = ConversationSummary(
                            otherHandle: handle,
                            otherName: name,
                            athleteType: type,
                            lastMessage: DirectMessage(senderHandle: currentUserHandle, recipientHandle: handle, content: "")
                        )
                    }
                )
            }
        }
    }

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(AppTheme.textSecondary)

            TextField("Search athletes & messages...", text: $searchText)
                .font(AppTheme.bodyFont)
                .foregroundColor(AppTheme.text)

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(AppTheme.textSecondary)
                }
            }
        }
        .padding(10)
        .background(AppTheme.elevated)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    private func conversationRow(_ conv: ConversationSummary) -> some View {
        HStack(spacing: 12) {
            ZStack(alignment: .bottomTrailing) {
                AthleteAvatarView(
                    imageData: nil,
                    symbolFallback: conv.athleteType.iconName,
                    initials: conv.otherName,
                    ringColor: conv.athleteType.badgeColor,
                    size: 46,
                    showCameraBadge: false,
                    isPublic: true
                )

                if conv.isOnline {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 10, height: 10)
                        .overlay(Circle().stroke(AppTheme.ground, lineWidth: 2))
                }
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(conv.otherName)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(AppTheme.text)

                    Text("@\(conv.otherHandle)")
                        .font(.system(size: 12))
                        .foregroundStyle(AppTheme.textSecondary)

                    Spacer()

                    Text(timeAgoString(conv.lastMessage.timestamp))
                        .font(.system(size: 11))
                        .foregroundStyle(conv.unreadCount > 0 ? AppTheme.primary : AppTheme.textSecondary)
                }

                HStack {
                    Text(conv.lastMessage.content.isEmpty ? "Started a new chat" : conv.lastMessage.content)
                        .font(AppTheme.subheadlineFont)
                        .foregroundStyle(conv.unreadCount > 0 ? AppTheme.text : AppTheme.textSecondary)
                        .lineLimit(1)

                    Spacer()

                    if conv.unreadCount > 0 {
                        Text("\(conv.unreadCount)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.black)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(AppTheme.primary)
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var emptyMessagesPlaceholder: some View {
        VStack(spacing: 12) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 44))
                .foregroundStyle(AppTheme.textSecondary.opacity(0.5))

            Text("No Messages Yet")
                .font(AppTheme.titleFont)
                .foregroundStyle(AppTheme.text)

            Text("Connect with other athletes, ask for training advice, or share your workout achievements.")
                .font(AppTheme.bodyFont)
                .foregroundStyle(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button {
                showingNewMessageSheet = true
            } label: {
                Text("Start a Conversation")
                    .font(AppTheme.headlineFont)
                    .foregroundStyle(.black)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(AppTheme.primary)
                    .clipShape(Capsule())
            }
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func timeAgoString(_ date: Date) -> String {
        let diff = Int(Date().timeIntervalSince(date))
        if diff < 60 { return "now" }
        if diff < 3600 { return "\(diff / 60)m" }
        if diff < 86400 { return "\(diff / 3600)h" }
        return "\(diff / 86400)d"
    }
}

// MARK: - New Message Picker
struct NewMessagePickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var relationshipStore = SocialRelationshipStore.shared

    let currentUserHandle: String
    var onSelectAthlete: (String, String, AthleteType) -> Void

    var body: some View {
        NavigationStack {
            List {
                Section("Athletes You Follow") {
                    ForEach(Array(SocialRelationshipStore.sampleAthletes.values)) { athlete in
                        if !relationshipStore.isBlocked(handle: athlete.handle) {
                            Button {
                                onSelectAthlete(athlete.handle, athlete.name, athlete.athleteType)
                                dismiss()
                            } label: {
                                HStack(spacing: 12) {
                                    AthleteAvatarView(
                                        imageData: nil,
                                        symbolFallback: athlete.athleteType.iconName,
                                        initials: athlete.name,
                                        ringColor: athlete.athleteType.badgeColor,
                                        size: 40,
                                        showCameraBadge: false,
                                        isPublic: true
                                    )

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(athlete.name)
                                            .font(AppTheme.headlineFont)
                                            .foregroundStyle(AppTheme.text)
                                        Text("@\(athlete.handle) • \(athlete.athleteType.displayName)")
                                            .font(AppTheme.captionFont)
                                            .foregroundStyle(AppTheme.textSecondary)
                                    }

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundStyle(AppTheme.textSecondary)
                                }
                            }
                            .listRowBackground(AppTheme.elevated)
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppTheme.ground.ignoresSafeArea())
            .navigationTitle("New Message")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(AppTheme.primary)
                }
            }
        }
    }
}
