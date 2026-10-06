// Views/DirectMessagesView.swift
import SwiftUI

// MARK: - Direct Messages Inbox View
struct DirectMessagesInboxView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var relationshipStore = SocialRelationshipStore.shared
    
    @State private var searchText: String = ""
    @State private var selectedConversation: DirectMessageConversation? = nil
    @State private var showingNewMessageSheet: Bool = false

    private var filteredConversations: [DirectMessageConversation] {
        if searchText.isEmpty {
            return relationshipStore.conversations.filter { !relationshipStore.isBlocked(handle: $0.otherUserHandle) }
        } else {
            return relationshipStore.conversations.filter { convo in
                !relationshipStore.isBlocked(handle: convo.otherUserHandle) &&
                (convo.otherUserName.localizedCaseInsensitiveContains(searchText) ||
                 convo.otherUserHandle.localizedCaseInsensitiveContains(searchText))
            }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search Bar
                searchBarSection

                if filteredConversations.isEmpty {
                    emptyInboxState
                } else {
                    List {
                        ForEach(filteredConversations) { convo in
                            Button {
                                selectedConversation = convo
                            } label: {
                                conversationRow(convo: convo)
                            }
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                            .listRowSeparatorTint(Color.white.opacity(0.08))
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
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingNewMessageSheet = true
                    } label: {
                        Image(systemName: "square.and.pencil")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(AppTheme.primary)
                    }
                }
            }
            .sheet(item: $selectedConversation) { convo in
                let profile = relationshipStore.getProfile(for: convo.otherUserHandle, fallbackName: convo.otherUserName, fallbackType: convo.otherUserAthleteType)
                ConversationChatView(profile: profile)
            }
            .sheet(isPresented: $showingNewMessageSheet) {
                NewMessageDirectorySheet { selectedProfile in
                    showingNewMessageSheet = false
                    selectedConversation = relationshipStore.getOrCreateConversation(with: selectedProfile)
                }
            }
        }
    }

    // MARK: - Search Bar
    private var searchBarSection: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.white.opacity(0.4))
                .font(.system(size: 14))

            TextField("Search athletes or chats...", text: $searchText)
                .font(.system(size: 14))
                .foregroundColor(.white)
                .autocorrectionDisabled()

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.white.opacity(0.4))
                        .font(.system(size: 14))
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    // MARK: - Conversation Row
    private func conversationRow(convo: DirectMessageConversation) -> some View {
        HStack(spacing: 14) {
            // Avatar
            ZStack {
                Circle()
                    .fill(convo.otherUserAthleteType.badgeColor.opacity(0.2))
                    .frame(width: 48, height: 48)
                    .overlay(
                        Circle().stroke(convo.otherUserAthleteType.badgeColor.opacity(0.6), lineWidth: 1.5)
                    )

                Image(systemName: convo.otherUserAvatarSymbol)
                    .font(.system(size: 20))
                    .foregroundColor(convo.otherUserAthleteType.badgeColor)
            }

            // Name + Preview
            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(convo.otherUserName)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)

                    Spacer()

                    if let lastMsg = convo.lastMessage {
                        Text(lastMsg.formattedTime)
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.4))
                    }
                }

                HStack {
                    if let lastMsg = convo.lastMessage {
                        Text(lastMsg.text)
                            .font(.system(size: 13, weight: convo.unreadCount > 0 ? .semibold : .regular))
                            .foregroundColor(convo.unreadCount > 0 ? .white : .white.opacity(0.6))
                            .lineLimit(1)
                    } else {
                        Text("No messages yet")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.4))
                    }

                    Spacer()

                    if convo.unreadCount > 0 {
                        Circle()
                            .fill(AppTheme.primary)
                            .frame(width: 8, height: 8)
                    }
                }
            }
        }
        .contentShape(Rectangle())
    }

    // MARK: - Empty State
    private var emptyInboxState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "bubble.left.and.text.bubble.right.fill")
                .font(.system(size: 48))
                .foregroundColor(AppTheme.primary.opacity(0.7))

            Text("No Messages Yet")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)

            Text("Connect with other athletes, ask for workout advice, or plan training sessions together.")
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button {
                showingNewMessageSheet = true
            } label: {
                Text("Start a Conversation")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(AppTheme.primary)
                    .clipShape(Capsule())
            }
            .padding(.top, 8)

            Spacer()
        }
    }
}

// MARK: - Conversation Chat View
struct ConversationChatView: View {
    @Environment(\.dismiss) private var dismiss
    let profile: OtherAthleteProfile

    @ObservedObject private var relationshipStore = SocialRelationshipStore.shared
    @State private var messageInput: String = ""
    @State private var showBlockAlert: Bool = false
    @State private var showOtherUserProfile: Bool = false

    private var conversation: DirectMessageConversation? {
        relationshipStore.conversations.first(where: { $0.otherUserHandle.lowercased() == profile.handle.lowercased() })
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Chat Message Stream
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 14) {
                            // Top Profile Intro Pill
                            topProfileIntroHeader

                            if let messages = conversation?.messages, !messages.isEmpty {
                                ForEach(messages) { msg in
                                    messageBubble(msg: msg)
                                        .id(msg.id)
                                }
                            } else {
                                emptyChatPrompt
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 16)
                    }
                    .onChange(of: conversation?.messages.count) { _ in
                        if let lastID = conversation?.messages.last?.id {
                            withAnimation(.easeOut(duration: 0.25)) {
                                proxy.scrollTo(lastID, anchor: .bottom)
                            }
                        }
                    }
                }

                Divider().background(Color.white.opacity(0.1))

                // Bottom Input Bar
                bottomInputSection
            }
            .background(AppTheme.ground.ignoresSafeArea())
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    HStack(spacing: 10) {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                        }

                        Button {
                            showOtherUserProfile = true
                        } label: {
                            HStack(spacing: 8) {
                                ZStack {
                                    Circle()
                                        .fill(profile.athleteType.badgeColor.opacity(0.3))
                                        .frame(width: 32, height: 32)
                                    Image(systemName: profile.avatarSymbol)
                                        .font(.system(size: 14))
                                        .foregroundColor(profile.athleteType.badgeColor)
                                }

                                VStack(alignment: .leading, spacing: 1) {
                                    Text(profile.name)
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(.white)

                                    Text("@\(profile.handle)")
                                        .font(.system(size: 10))
                                        .foregroundColor(AppTheme.primary)
                                }
                            }
                        }
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(relationshipStore.isFollowing(handle: profile.handle) ? "Unfollow @\(profile.handle)" : "Follow @\(profile.handle)") {
                            relationshipStore.toggleFollow(for: profile.handle)
                        }

                        Button("View Full Profile") {
                            showOtherUserProfile = true
                        }

                        Button("Block Athlete", role: .destructive) {
                            showBlockAlert = true
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.system(size: 18))
                            .foregroundColor(.white)
                    }
                }
            }
            .onAppear {
                relationshipStore.markConversationAsRead(for: profile.handle)
            }
            .sheet(isPresented: $showOtherUserProfile) {
                OtherUserProfileView(handle: profile.handle, initialName: profile.name, initialAthleteType: profile.athleteType)
            }
            .alert("Block @\(profile.handle)?", isPresented: $showBlockAlert) {
                Button("Block", role: .destructive) {
                    relationshipStore.blockUser(handle: profile.handle)
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("They won't be able to message you or see your workouts.")
            }
        }
    }

    // MARK: - Top Profile Intro Header
    private var topProfileIntroHeader: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(profile.athleteType.badgeColor.opacity(0.25))
                    .frame(width: 60, height: 60)
                    .overlay(Circle().stroke(profile.athleteType.badgeColor, lineWidth: 2))

                Image(systemName: profile.avatarSymbol)
                    .font(.system(size: 26))
                    .foregroundColor(profile.athleteType.badgeColor)
            }
            .padding(.top, 10)

            Text(profile.name)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)

            Text("@\(profile.handle) • \(profile.athleteType.displayName)")
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.6))

            Text("This is the beginning of your direct chat history with @\(profile.handle). Keep training conversations respectful and motivating.")
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.4))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
                .padding(.top, 4)

            Divider()
                .background(Color.white.opacity(0.08))
                .padding(.top, 12)
        }
    }

    // MARK: - Message Bubble
    private func messageBubble(msg: DirectMessageItem) -> some View {
        HStack {
            if msg.isFromCurrentUser {
                Spacer(minLength: 40)
            }

            VStack(alignment: msg.isFromCurrentUser ? .trailing : .leading, spacing: 3) {
                Text(msg.text)
                    .font(.system(size: 14))
                    .foregroundColor(msg.isFromCurrentUser ? .black : .white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        msg.isFromCurrentUser ? AppTheme.primary : Color.white.opacity(0.12)
                    )
                    .clipShape(
                        RoundedRectangle(cornerRadius: 16)
                    )

                Text(msg.formattedTime)
                    .font(.system(size: 9))
                    .foregroundColor(.white.opacity(0.4))
                    .padding(.horizontal, 4)
            }

            if !msg.isFromCurrentUser {
                Spacer(minLength: 40)
            }
        }
    }

    // MARK: - Empty Chat Prompt
    private var emptyChatPrompt: some View {
        VStack(spacing: 8) {
            Text("Say hi to @\(profile.handle)!")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white.opacity(0.6))
        }
        .padding(.vertical, 24)
    }

    // MARK: - Bottom Input Section
    private var bottomInputSection: some View {
        HStack(spacing: 10) {
            TextField("Message @\(profile.handle)...", text: $messageInput, axis: .vertical)
                .font(.system(size: 14))
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .lineLimit(1...4)

            Button {
                sendCurrentMessage()
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 30))
                    .foregroundColor(messageInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.white.opacity(0.2) : AppTheme.primary)
            }
            .disabled(messageInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.black.opacity(0.4))
    }

    private func sendCurrentMessage() {
        let text = messageInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        messageInput = ""
        relationshipStore.sendMessage(to: profile.handle, text: text)
    }
}

// MARK: - New Message Directory Sheet
struct NewMessageDirectorySheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var relationshipStore = SocialRelationshipStore.shared
    var onSelectAthlete: (OtherAthleteProfile) -> Void

    @State private var searchText: String = ""

    private var availableProfiles: [OtherAthleteProfile] {
        let all = Array(relationshipStore.athleteDirectory.values)
            .filter { !relationshipStore.isBlocked(handle: $0.handle) }
        if searchText.isEmpty {
            return all
        } else {
            return all.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.handle.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search Bar
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.white.opacity(0.4))
                        .font(.system(size: 14))

                    TextField("Search by name or @handle...", text: $searchText)
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                        .autocorrectionDisabled()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .background(Color.white.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 16)
                .padding(.vertical, 10)

                List {
                    ForEach(availableProfiles) { profile in
                        Button {
                            onSelectAthlete(profile)
                        } label: {
                            HStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(profile.athleteType.badgeColor.opacity(0.2))
                                        .frame(width: 42, height: 42)
                                    Image(systemName: profile.avatarSymbol)
                                        .font(.system(size: 18))
                                        .foregroundColor(profile.athleteType.badgeColor)
                                }

                                VStack(alignment: .leading, spacing: 2) {
                                    HStack {
                                        Text(profile.name)
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundColor(.white)
                                        if profile.isVerifiedAthlete {
                                            Image(systemName: "checkmark.seal.fill")
                                                .font(.system(size: 12))
                                                .foregroundColor(AppTheme.primary)
                                        }
                                    }

                                    Text("@\(profile.handle) • \(profile.athleteType.displayName)")
                                        .font(.system(size: 11))
                                        .foregroundColor(.white.opacity(0.5))
                                }

                                Spacer()

                                if relationshipStore.isFollowing(handle: profile.handle) {
                                    Text("Following")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(AppTheme.primary)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .background(AppTheme.primary.opacity(0.12))
                                        .clipShape(Capsule())
                                }
                            }
                        }
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        .listRowSeparatorTint(Color.white.opacity(0.08))
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
            .background(AppTheme.ground.ignoresSafeArea())
            .navigationTitle("New Message")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white.opacity(0.7))
                }
            }
        }
    }
}
