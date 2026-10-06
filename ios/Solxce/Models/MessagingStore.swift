// Models/MessagingStore.swift
import SwiftUI
import Combine

public struct DirectMessage: Identifiable, Codable {
    public let id: UUID
    public let senderHandle: String
    public let recipientHandle: String
    public let content: String
    public let timestamp: Date
    public var isRead: Bool
    public var workoutShareSummary: String?

    public init(
        id: UUID = UUID(),
        senderHandle: String,
        recipientHandle: String,
        content: String,
        timestamp: Date = Date(),
        isRead: Bool = true,
        workoutShareSummary: String? = nil
    ) {
        self.id = id
        self.senderHandle = senderHandle
        self.recipientHandle = recipientHandle
        self.content = content
        self.timestamp = timestamp
        self.isRead = isRead
        self.workoutShareSummary = workoutShareSummary
    }
}

public struct ConversationSummary: Identifiable {
    public var id: String { otherHandle }
    public let otherHandle: String
    public let otherName: String
    public let athleteType: AthleteType
    public let lastMessage: DirectMessage
    public var unreadCount: Int
    public let isOnline: Bool

    public init(
        otherHandle: String,
        otherName: String,
        athleteType: AthleteType,
        lastMessage: DirectMessage,
        unreadCount: Int = 0,
        isOnline: Bool = true
    ) {
        self.otherHandle = otherHandle
        self.otherName = otherName
        self.athleteType = athleteType
        self.lastMessage = lastMessage
        self.unreadCount = unreadCount
        self.isOnline = isOnline
    }
}

public final class MessagingStore: ObservableObject {
    public static let shared = MessagingStore()

    @Published public var messages: [DirectMessage] = []

    public init() {
        seedSampleMessages()
    }

    private func seedSampleMessages() {
        let now = Date()
        self.messages = [
            DirectMessage(
                senderHandle: "marcus_vance",
                recipientHandle: "current_user",
                content: "Yo! Great pace on that 10k morning tempo run yesterday 🔥",
                timestamp: now.addingTimeInterval(-3600 * 2),
                isRead: true
            ),
            DirectMessage(
                senderHandle: "current_user",
                recipientHandle: "marcus_vance",
                content: "Thanks Marcus! Legs felt fresh. You hitting squats today?",
                timestamp: now.addingTimeInterval(-3600 * 1.8),
                isRead: true
            ),
            DirectMessage(
                senderHandle: "marcus_vance",
                recipientHandle: "current_user",
                content: "Yessir, 5x5 heavy front squats and sled pushes. Let's get it!",
                timestamp: now.addingTimeInterval(-3600 * 1.5),
                isRead: false
            ),
            DirectMessage(
                senderHandle: "elena_lifts",
                recipientHandle: "current_user",
                content: "Hey, what pre-workout timing do you recommend for long fasts?",
                timestamp: now.addingTimeInterval(-86400 * 1.2),
                isRead: true
            ),
            DirectMessage(
                senderHandle: "current_user",
                recipientHandle: "elena_lifts",
                content: "I usually take pure electrolytes with cold water 30 mins before, keeps energy high without breaking the fast!",
                timestamp: now.addingTimeInterval(-86400 * 1.1),
                isRead: true
            ),
            DirectMessage(
                senderHandle: "charlotte_cross",
                recipientHandle: "current_user",
                content: "Check out this Saturday partner WOD if you want to join!",
                timestamp: now.addingTimeInterval(-86400 * 3),
                isRead: true,
                workoutShareSummary: "HYROX Sled & Row Hybrid (45 mins)"
            )
        ]
    }

    public func getMessages(between userA: String, and userB: String) -> [DirectMessage] {
        let cleanA = userA.lowercased().trimmingCharacters(in: CharacterSet(charactersIn: "@"))
        let cleanB = userB.lowercased().trimmingCharacters(in: CharacterSet(charactersIn: "@"))

        return messages.filter { msg in
            let sender = msg.senderHandle.lowercased().trimmingCharacters(in: CharacterSet(charactersIn: "@"))
            let recipient = msg.recipientHandle.lowercased().trimmingCharacters(in: CharacterSet(charactersIn: "@"))

            return (sender == cleanA && recipient == cleanB) || (sender == cleanB && recipient == cleanA) ||
                   ((sender == "current_user" || sender == cleanA) && (recipient == cleanB || recipient == "current_user"))
        }.sorted(by: { $0.timestamp < $1.timestamp })
    }

    public func sendMessage(from sender: String, to recipient: String, content: String, workoutShareSummary: String? = nil) {
        let cleanSender = sender.lowercased().trimmingCharacters(in: CharacterSet(charactersIn: "@"))
        let cleanRecipient = recipient.lowercased().trimmingCharacters(in: CharacterSet(charactersIn: "@"))

        let newMsg = DirectMessage(
            senderHandle: cleanSender.isEmpty ? "current_user" : cleanSender,
            recipientHandle: cleanRecipient,
            content: content,
            timestamp: Date(),
            isRead: true,
            workoutShareSummary: workoutShareSummary
        )

        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
            messages.append(newMsg)
        }

        // Simulate simulated reply if chat is with Marcus or Elena
        if cleanRecipient == "marcus_vance" || cleanRecipient == "elena_lifts" {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                guard let self = self else { return }
                let replies = [
                    "Let's lock in! Consistency is everything 🚀",
                    "Great work today. Keep the standard high!",
                    "Solid grind. See you on the leaderboard!",
                    "Love the energy, keep pushing that threshold!"
                ]
                let reply = DirectMessage(
                    senderHandle: cleanRecipient,
                    recipientHandle: cleanSender.isEmpty ? "current_user" : cleanSender,
                    content: replies.randomElement() ?? "Right on! 💪",
                    timestamp: Date(),
                    isRead: false
                )
                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                    self.messages.append(reply)
                }
            }
        }
    }

    public func getConversations(currentUserHandle: String) -> [ConversationSummary] {
        let cleanMe = currentUserHandle.lowercased().trimmingCharacters(in: CharacterSet(charactersIn: "@"))
        var conversationsMap: [String: [DirectMessage]] = [:]

        for msg in messages {
            let sender = msg.senderHandle.lowercased().trimmingCharacters(in: CharacterSet(charactersIn: "@"))
            let recipient = msg.recipientHandle.lowercased().trimmingCharacters(in: CharacterSet(charactersIn: "@"))

            let other = (sender == "current_user" || sender == cleanMe) ? recipient : sender
            if other.isEmpty || other == "current_user" || other == cleanMe { continue }

            conversationsMap[other, default: []].append(msg)
        }

        let relationships = SocialRelationshipStore.shared

        return conversationsMap.compactMap { (otherHandle, msgs) -> ConversationSummary? in
            // Filter out blocked users
            if relationships.isBlocked(handle: otherHandle) { return nil }

            guard let last = msgs.sorted(by: { $0.timestamp < $1.timestamp }).last else { return nil }
            let profile = relationships.getAthleteProfile(for: otherHandle)
            let unread = msgs.filter {
                $0.recipientHandle == "current_user" || $0.recipientHandle == cleanMe
            }.filter { !$0.isRead }.count

            return ConversationSummary(
                otherHandle: otherHandle,
                otherName: profile.name,
                athleteType: profile.athleteType,
                lastMessage: last,
                unreadCount: unread,
                isOnline: true
            )
        }.sorted(by: { $0.lastMessage.timestamp > $1.lastMessage.timestamp })
    }

    public func markAsRead(otherHandle: String, currentUserHandle: String) {
        let cleanOther = otherHandle.lowercased().trimmingCharacters(in: CharacterSet(charactersIn: "@"))
        let cleanMe = currentUserHandle.lowercased().trimmingCharacters(in: CharacterSet(charactersIn: "@"))

        for idx in messages.indices {
            let sender = messages[idx].senderHandle.lowercased().trimmingCharacters(in: CharacterSet(charactersIn: "@"))
            let recipient = messages[idx].recipientHandle.lowercased().trimmingCharacters(in: CharacterSet(charactersIn: "@"))

            if sender == cleanOther && (recipient == "current_user" || recipient == cleanMe) {
                messages[idx].isRead = true
            }
        }
    }
}
