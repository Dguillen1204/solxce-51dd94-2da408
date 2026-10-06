// Views/DirectMessageChatView.swift
import SwiftUI

public struct DirectMessageChatView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var messagingStore = MessagingStore.shared
    @ObservedObject private var relationshipStore = SocialRelationshipStore.shared

    let otherHandle: String
    let otherName: String
    let athleteType: AthleteType
    let currentUserHandle: String

    @State private var inputText: String = ""
    @State private var showingBlockAlert = false
    @State private var showingQuickWorkoutShare = false

    public init(
        otherHandle: String,
        otherName: String,
        athleteType: AthleteType,
        currentUserHandle: String = "solxce_athlete"
    ) {
        self.otherHandle = otherHandle
        self.otherName = otherName
        self.athleteType = athleteType
        self.currentUserHandle = currentUserHandle
    }

    private var messages: [DirectMessage] {
        messagingStore.getMessages(between: currentUserHandle, and: otherHandle)
    }

    private var isBlocked: Bool {
        relationshipStore.isBlocked(handle: otherHandle)
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Online & Privacy Info Banner
                athleteChatHeaderBanner

                // Message Thread
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            // Encrypted banner
                            encryptedNoticeHeader

                            ForEach(messages) { msg in
                                messageBubble(msg)
                                    .id(msg.id)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                    .onChange(of: messages.count) { _ in
                        if let lastID = messages.last?.id {
                            withAnimation(.easeOut(duration: 0.25)) {
                                proxy.scrollTo(lastID, anchor: .bottom)
                            }
                        }
                    }
                    .onAppear {
                        if let lastID = messages.last?.id {
                            proxy.scrollTo(lastID, anchor: .bottom)
                        }
                    }
                }

                Divider().background(AppTheme.hairline)

                // Input Bar or Blocked Notice
                if isBlocked {
                    blockedChatNotice
                } else {
                    messageInputBar
                }
            }
            .background(AppTheme.ground.ignoresSafeArea())
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 8) {
                        AthleteAvatarView(
                            imageData: nil,
                            symbolFallback: athleteType.iconName,
                            initials: otherName,
                            ringColor: athleteType.badgeColor,
                            size: 28,
                            showCameraBadge: false,
                            isPublic: true
                        )

                        VStack(alignment: .leading, spacing: 1) {
                            Text(otherName)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(AppTheme.text)
                            Text("@\(otherHandle)")
                                .font(.system(size: 11))
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                    }
                }

                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                    .font(AppTheme.subheadlineFont)
                    .foregroundStyle(AppTheme.textSecondary)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(relationshipStore.isFollowing(handle: otherHandle) ? "Unfollow" : "Follow") {
                            relationshipStore.toggleFollow(handle: otherHandle)
                        }
                        if isBlocked {
                            Button("Unblock Athlete") {
                                relationshipStore.unblock(handle: otherHandle)
                            }
                        } else {
                            Button("Block Athlete", role: .destructive) {
                                showingBlockAlert = true
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                }
            }
            .alert("Block @\(otherHandle)?", isPresented: $showingBlockAlert) {
                Button("Block", role: .destructive) {
                    relationshipStore.block(handle: otherHandle)
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("They will no longer be able to message you or see your workouts.")
            }
            .onAppear {
                messagingStore.markAsRead(otherHandle: otherHandle, currentUserHandle: currentUserHandle)
            }
        }
    }

    // MARK: - Athlete Chat Header Banner
    private var athleteChatHeaderBanner: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(Color.green)
                .frame(width: 8, height: 8)

            Text("Active in Training • \(athleteType.displayName)")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(AppTheme.textSecondary)

            Spacer()

            if relationshipStore.isFollowing(handle: otherHandle) {
                Text("Mutual Athlete")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(AppTheme.primary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(AppTheme.primary.opacity(0.12))
                    .clipShape(Capsule())
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(AppTheme.elevated)
        .overlay(Divider().background(AppTheme.hairline), alignment: .bottom)
    }

    private var encryptedNoticeHeader: some View {
        HStack(spacing: 6) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 11))
                .foregroundStyle(AppTheme.textSecondary)
            Text("Direct Athlete Messaging is private and on-device secured.")
                .font(.system(size: 11))
                .foregroundStyle(AppTheme.textSecondary)
        }
        .padding(.vertical, 8)
    }

    // MARK: - Message Bubble
    @ViewBuilder
    private func messageBubble(_ msg: DirectMessage) -> some View {
        let isMe = msg.senderHandle.lowercased() == currentUserHandle.lowercased() || msg.senderHandle == "current_user"

        HStack {
            if isMe { Spacer(minLength: 48) }

            VStack(alignment: isMe ? .trailing : .leading, spacing: 4) {
                // Workout snippet share card if attached
                if let workoutCard = msg.workoutShareSummary {
                    HStack(spacing: 8) {
                        Image(systemName: "flame.circle.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(AppTheme.primary)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Shared Workout")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(AppTheme.primary)
                            Text(workoutCard)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(.white)
                        }
                    }
                    .padding(8)
                    .background(Color.black.opacity(0.35))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                Text(msg.content)
                    .font(AppTheme.bodyFont)
                    .foregroundStyle(isMe ? .black : AppTheme.text)

                Text(formatTimestamp(msg.timestamp))
                    .font(.system(size: 9))
                    .foregroundStyle(isMe ? Color.black.opacity(0.6) : AppTheme.textSecondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(isMe ? AppTheme.primary : AppTheme.elevated)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isMe ? Color.clear : AppTheme.hairline, lineWidth: 1)
            )

            if !isMe { Spacer(minLength: 48) }
        }
    }

    // MARK: - Message Input Bar
    private var messageInputBar: some View {
        HStack(spacing: 10) {
            // Quick Workout Share Button
            Menu {
                Button {
                    messagingStore.sendMessage(
                        from: currentUserHandle,
                        to: otherHandle,
                        content: "Check out my latest workout split!",
                        workoutShareSummary: "5x5 Back Squat + 5mi Tempo Run"
                    )
                } label: {
                    Label("Share Today's Workout", systemImage: "flame.fill")
                }

                Button {
                    messagingStore.sendMessage(
                        from: currentUserHandle,
                        to: otherHandle,
                        content: "Let's log a partner session this week!",
                        workoutShareSummary: "HYROX Sled & Erg Session"
                    )
                } label: {
                    Label("Send Workout Invite", systemImage: "figure.run.square.stack")
                }
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(AppTheme.primary)
            }

            // Text Input
            TextField("Message @\(otherHandle)...", text: $inputText)
                .font(AppTheme.bodyFont)
                .foregroundStyle(AppTheme.text)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(AppTheme.elevated)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(AppTheme.hairline, lineWidth: 1))
                .submitLabel(.send)
                .onSubmit {
                    sendCurrentMessage()
                }

            // Send Button
            Button {
                sendCurrentMessage()
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? AppTheme.textSecondary.opacity(0.4) : AppTheme.primary)
            }
            .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(AppTheme.ground)
    }

    private var blockedChatNotice: some View {
        HStack(spacing: 8) {
            Image(systemName: "hand.raised.fill")
                .foregroundStyle(AppTheme.textSecondary)
            Text("You blocked @\(otherHandle). Unblock them to send messages.")
                .font(AppTheme.captionFont)
                .foregroundStyle(AppTheme.textSecondary)
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .background(AppTheme.elevated)
    }

    private func sendCurrentMessage() {
        let clean = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }
        messagingStore.sendMessage(from: currentUserHandle, to: otherHandle, content: clean)
        inputText = ""
    }

    private func formatTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}
