// Models/SocialRelationshipStore.swift
import SwiftUI
import Combine

// MARK: - Privacy Rules Configuration Model
public struct UserPrivacyRules: Codable, Equatable {
    public var isPrivateAccount: Bool = false
    public var allowDirectMessagesFrom: DirectMessagePermission = .everyone
    public var showActivityStatus: Bool = true
    public var allowWorkoutSharing: Bool = true
    public var allowTaggingAndMentions: TaggingPermission = .everyone
    public var showLifetimeVolumePublicly: Bool = true
    public var showRunPacePublicly: Bool = true
    public var filterOffensiveComments: Bool = true

    public enum DirectMessagePermission: String, CaseIterable, Codable, Identifiable {
        case everyone = "Everyone"
        case peopleYouFollow = "People You Follow"
        case noOne = "No One"
        
        public var id: String { rawValue }
        
        public var subtitle: String {
            switch self {
            case .everyone: return "Any Solxce athlete can send you a message."
            case .peopleYouFollow: return "Only athletes you follow can start a chat."
            case .noOne: return "Disable incoming direct messages from everyone."
            }
        }
    }

    public enum TaggingPermission: String, CaseIterable, Codable, Identifiable {
        case everyone = "Everyone"
        case peopleYouFollow = "People You Follow"
        case noOne = "No One"
        
        public var id: String { rawValue }
    }
}

// MARK: - Direct Message & Conversation Models
public struct DirectMessageItem: Identifiable, Codable, Equatable {
    public let id: UUID
    public let senderHandle: String
    public let recipientHandle: String
    public let text: String
    public let timestamp: Date
    public let isFromCurrentUser: Bool
    public var isRead: Bool

    public init(
        id: UUID = UUID(),
        senderHandle: String,
        recipientHandle: String,
        text: String,
        timestamp: Date = Date(),
        isFromCurrentUser: Bool,
        isRead: Bool = true
    ) {
        self.id = id
        self.senderHandle = senderHandle
        self.recipientHandle = recipientHandle
        self.text = text
        self.timestamp = timestamp
        self.isFromCurrentUser = isFromCurrentUser
        self.isRead = isRead
    }

    public var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
    }
}

public struct DirectMessageConversation: Identifiable, Equatable {
    public var id: String { otherUserHandle }
    public let otherUserHandle: String
    public let otherUserName: String
    public let otherUserAthleteType: AthleteType
    public let otherUserAvatarSymbol: String
    public var messages: [DirectMessageItem]
    public var unreadCount: Int {
        messages.filter { !$0.isFromCurrentUser && !$0.isRead }.count
    }
    public var lastMessage: DirectMessageItem? {
        messages.last
    }

    public init(
        otherUserHandle: String,
        otherUserName: String,
        otherUserAthleteType: AthleteType,
        otherUserAvatarSymbol: String = "figure.cross-training",
        messages: [DirectMessageItem] = []
    ) {
        self.otherUserHandle = otherUserHandle
        self.otherUserName = otherUserName
        self.otherUserAthleteType = otherUserAthleteType
        self.otherUserAvatarSymbol = otherUserAvatarSymbol
        self.messages = messages
    }
}

// MARK: - Other Athlete Public Profile Data Model
public struct OtherAthleteProfile: Identifiable {
    public var id: String { handle }
    public let handle: String
    public let name: String
    public let athleteType: AthleteType
    public let bio: String
    public let avatarSymbol: String
    public var followersCount: Int
    public var followingCount: Int
    public var totalWorkoutsCount: Int
    public var totalVolumeFormatted: String
    public var best5kPace: String
    public var isVerifiedAthlete: Bool
    public var isFollowing: Bool
    public var isBlocked: Bool

    public init(
        handle: String,
        name: String,
        athleteType: AthleteType,
        bio: String,
        avatarSymbol: String = "figure.cross-training",
        followersCount: Int,
        followingCount: Int,
        totalWorkoutsCount: Int,
        totalVolumeFormatted: String,
        best5kPace: String,
        isVerifiedAthlete: Bool = true,
        isFollowing: Bool = false,
        isBlocked: Bool = false
    ) {
        self.handle = handle
        self.name = name
        self.athleteType = athleteType
        self.bio = bio
        self.avatarSymbol = avatarSymbol
        self.followersCount = followersCount
        self.followingCount = followingCount
        self.totalWorkoutsCount = totalWorkoutsCount
        self.totalVolumeFormatted = totalVolumeFormatted
        self.best5kPace = best5kPace
        self.isVerifiedAthlete = isVerifiedAthlete
        self.isFollowing = isFollowing
        self.isBlocked = isBlocked
    }
}

// MARK: - Social Relationship & Privacy Store
@MainActor
public final class SocialRelationshipStore: ObservableObject {
    public static let shared = SocialRelationshipStore()

    // Followed user handles
    @Published public var followedHandles: Set<String> = ["marcus_lifts", "elena_runs"]
    
    // Blocked user handles
    @Published public var blockedHandles: Set<String> = []

    // User's own Privacy Rules
    @Published public var privacyRules: UserPrivacyRules = UserPrivacyRules()

    // Direct Message Conversations
    @Published public var conversations: [DirectMessageConversation] = []

    // Seeded Directory of Community Athletes
    @Published public var athleteDirectory: [String: OtherAthleteProfile] = [:]

    private init() {
        loadDirectory()
        loadConversations()
    }

    // MARK: - Directory Initialization
    private func loadDirectory() {
        let profiles = [
            OtherAthleteProfile(
                handle: "marcus_lifts",
                name: "Marcus Vance",
                athleteType: .powerlifter,
                bio: "Competitive Powerlifter 🏋️‍♂️ | Bench 405 • Squat 585 • Deadlift 675. Coaching athletes to exceed their PRs daily.",
                avatarSymbol: "dumbbell.fill",
                followersCount: 1420,
                followingCount: 380,
                totalWorkoutsCount: 412,
                totalVolumeFormatted: "2.4M lbs",
                best5kPace: "8'45\" /mi",
                isVerifiedAthlete: true,
                isFollowing: true,
                isBlocked: false
            ),
            OtherAthleteProfile(
                handle: "elena_runs",
                name: "Elena Rostova",
                athleteType: .runner,
                bio: "Sub-3 Marathoner 🏃‍♀️ • Track & Trail Endurance • Fueling high cadence workouts with plant power.",
                avatarSymbol: "figure.run",
                followersCount: 3180,
                followingCount: 420,
                totalWorkoutsCount: 520,
                totalVolumeFormatted: "480k lbs",
                best5kPace: "5'42\" /mi",
                isVerifiedAthlete: true,
                isFollowing: true,
                isBlocked: false
            ),
            OtherAthleteProfile(
                handle: "kai_athletic",
                name: "Kai Takahashi",
                athleteType: .hybrid,
                bio: "Hybrid Conditioning Specialist ⚡️ | Heavy Squats & Sub-20 5K Splits | Standard Over Excuses.",
                avatarSymbol: "bolt.shield.fill",
                followersCount: 2890,
                followingCount: 512,
                totalWorkoutsCount: 340,
                totalVolumeFormatted: "1.8M lbs",
                best5kPace: "6'12\" /mi",
                isVerifiedAthlete: true,
                isFollowing: false,
                isBlocked: false
            ),
            OtherAthleteProfile(
                handle: "maya_rings",
                name: "Maya Lin",
                athleteType: .calisthenics,
                bio: "Gymnastics rings & bodyweight mastery 🤸‍♀️ | Planche • Front Lever • Strict Muscle-ups.",
                avatarSymbol: "figure.gymnastics",
                followersCount: 1950,
                followingCount: 260,
                totalWorkoutsCount: 290,
                totalVolumeFormatted: "890k lbs",
                best5kPace: "7'30\" /mi",
                isVerifiedAthlete: true,
                isFollowing: false,
                isBlocked: false
            ),
            OtherAthleteProfile(
                handle: "coach_dave",
                name: "Coach Dave Sterling",
                athleteType: .functional,
                bio: "Strength & Conditioning Coach 🛡️ | Kettlebells, Barbell Mechanics & Zone 2 Base Building.",
                avatarSymbol: "shield.lefthalf.filled",
                followersCount: 4890,
                followingCount: 180,
                totalWorkoutsCount: 780,
                totalVolumeFormatted: "3.2M lbs",
                best5kPace: "6'55\" /mi",
                isVerifiedAthlete: true,
                isFollowing: false,
                isBlocked: false
            ),
            OtherAthleteProfile(
                handle: "sarah_lifts",
                name: "Sarah Jenkins",
                athleteType: .bodybuilder,
                bio: "Hypertrophy science & physique prep 💥 | Progressive overload obsessed | 210g protein daily.",
                avatarSymbol: "figure.arms.open",
                followersCount: 2100,
                followingCount: 310,
                totalWorkoutsCount: 390,
                totalVolumeFormatted: "1.9M lbs",
                best5kPace: "8'15\" /mi",
                isVerifiedAthlete: true,
                isFollowing: false,
                isBlocked: false
            )
        ]

        for p in profiles {
            var mutable = p
            mutable.isFollowing = followedHandles.contains(p.handle)
            mutable.isBlocked = blockedHandles.contains(p.handle)
            athleteDirectory[p.handle] = mutable
        }
    }

    // MARK: - Conversations Initialization
    private func loadConversations() {
        let initialConversations = [
            DirectMessageConversation(
                otherUserHandle: "marcus_lifts",
                otherUserName: "Marcus Vance",
                otherUserAthleteType: .powerlifter,
                otherUserAvatarSymbol: "dumbbell.fill",
                messages: [
                    DirectMessageItem(
                        senderHandle: "marcus_lifts",
                        recipientHandle: "alex_solxce",
                        text: "Hey Alex! Saw your 315 lbs bench set this morning. Solid bar path and lockout!",
                        timestamp: Date().addingTimeInterval(-3600 * 3),
                        isFromCurrentUser: false,
                        isRead: true
                    ),
                    DirectMessageItem(
                        senderHandle: "alex_solxce",
                        recipientHandle: "marcus_lifts",
                        text: "Thanks Marcus! Focused on leg drive and lat tightness. Appreciate the feedback!",
                        timestamp: Date().addingTimeInterval(-3600 * 2),
                        isFromCurrentUser: true,
                        isRead: true
                    ),
                    DirectMessageItem(
                        senderHandle: "marcus_lifts",
                        recipientHandle: "alex_solxce",
                        text: "Let me know when you run that 5K weekend split. Let's get a session in!",
                        timestamp: Date().addingTimeInterval(-1800),
                        isFromCurrentUser: false,
                        isRead: false
                    )
                ]
            ),
            DirectMessageConversation(
                otherUserHandle: "elena_runs",
                otherUserName: "Elena Rostova",
                otherUserAthleteType: .runner,
                otherUserAvatarSymbol: "figure.run",
                messages: [
                    DirectMessageItem(
                        senderHandle: "elena_runs",
                        recipientHandle: "alex_solxce",
                        text: "Hey! What trail did you run on that 10-miler?",
                        timestamp: Date().addingTimeInterval(-86400 * 2),
                        isFromCurrentUser: false,
                        isRead: true
                    ),
                    DirectMessageItem(
                        senderHandle: "alex_solxce",
                        recipientHandle: "elena_runs",
                        text: "It was Skyline Ridge Trail! Elevation gain is around 840 ft. Highly recommended for aerobic base work.",
                        timestamp: Date().addingTimeInterval(-86400 * 2 + 1800),
                        isFromCurrentUser: true,
                        isRead: true
                    ),
                    DirectMessageItem(
                        senderHandle: "elena_runs",
                        recipientHandle: "alex_solxce",
                        text: "Adding it to my weekend long run schedule. Thanks!",
                        timestamp: Date().addingTimeInterval(-86400 + 400),
                        isFromCurrentUser: false,
                        isRead: true
                    )
                ]
            )
        ]
        self.conversations = initialConversations
    }

    // MARK: - Follow / Unfollow Operations
    public func isFollowing(handle: String) -> Bool {
        followedHandles.contains(handle.lowercased())
    }

    public func toggleFollow(for handle: String) {
        let key = handle.lowercased()
        if followedHandles.contains(key) {
            followedHandles.remove(key)
            if var profile = athleteDirectory[key] {
                profile.isFollowing = false
                profile.followersCount = max(0, profile.followersCount - 1)
                athleteDirectory[key] = profile
            }
        } else {
            // Cannot follow if blocked
            if blockedHandles.contains(key) {
                unblockUser(handle: key)
            }
            followedHandles.insert(key)
            if var profile = athleteDirectory[key] {
                profile.isFollowing = true
                profile.followersCount += 1
                athleteDirectory[key] = profile
            }
        }
    }

    // MARK: - Blocking / Unblocking Operations
    public func isBlocked(handle: String) -> Bool {
        blockedHandles.contains(handle.lowercased())
    }

    public func blockUser(handle: String) {
        let key = handle.lowercased()
        blockedHandles.insert(key)
        followedHandles.remove(key)
        if var profile = athleteDirectory[key] {
            profile.isBlocked = true
            profile.isFollowing = false
            athleteDirectory[key] = profile
        }
    }

    public func unblockUser(handle: String) {
        let key = handle.lowercased()
        blockedHandles.remove(key)
        if var profile = athleteDirectory[key] {
            profile.isBlocked = false
            athleteDirectory[key] = profile
        }
    }

    // MARK: - Profile Lookup
    public func getProfile(for handle: String, fallbackName: String? = nil, fallbackType: AthleteType? = nil) -> OtherAthleteProfile {
        let key = handle.lowercased()
        if let existing = athleteDirectory[key] {
            var updated = existing
            updated.isFollowing = followedHandles.contains(key)
            updated.isBlocked = blockedHandles.contains(key)
            return updated
        }

        // Generate profile dynamic fallback
        let newProfile = OtherAthleteProfile(
            handle: handle,
            name: fallbackName ?? handle.capitalized.replacingOccurrences(of: "_", with: " "),
            athleteType: fallbackType ?? .hybrid,
            bio: "Solxce Athlete pushing the daily performance standard. Tracking workouts, lifts, and miles.",
            avatarSymbol: fallbackType?.iconName ?? "figure.cross-training",
            followersCount: 128,
            followingCount: 94,
            totalWorkoutsCount: 65,
            totalVolumeFormatted: "340k lbs",
            best5kPace: "7'15\" /mi",
            isVerifiedAthlete: false,
            isFollowing: followedHandles.contains(key),
            isBlocked: blockedHandles.contains(key)
        )
        athleteDirectory[key] = newProfile
        return newProfile
    }

    // MARK: - Messaging Operations
    public func canMessage(handle: String) -> (allowed: Bool, reason: String?) {
        let key = handle.lowercased()
        if blockedHandles.contains(key) {
            return (false, "You have blocked this athlete. Unblock them to send a message.")
        }
        
        switch privacyRules.allowDirectMessagesFrom {
        case .everyone:
            return (true, nil)
        case .peopleYouFollow:
            if followedHandles.contains(key) {
                return (true, nil)
            } else {
                return (false, "Direct messages are limited to athletes you follow under your privacy rules.")
            }
        case .noOne:
            return (false, "Direct messaging is currently disabled in your privacy settings.")
        }
    }

    public func getOrCreateConversation(with profile: OtherAthleteProfile) -> DirectMessageConversation {
        let key = profile.handle.lowercased()
        if let index = conversations.firstIndex(where: { $0.otherUserHandle.lowercased() == key }) {
            return conversations[index]
        }
        
        let newConvo = DirectMessageConversation(
            otherUserHandle: profile.handle,
            otherUserName: profile.name,
            otherUserAthleteType: profile.athleteType,
            otherUserAvatarSymbol: profile.avatarSymbol,
            messages: []
        )
        conversations.insert(newConvo, at: 0)
        return newConvo
    }

    public func sendMessage(to recipientHandle: String, text: String, myHandle: String = "alex_solxce") {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        let key = recipientHandle.lowercased()

        let message = DirectMessageItem(
            senderHandle: myHandle,
            recipientHandle: recipientHandle,
            text: text,
            timestamp: Date(),
            isFromCurrentUser: true,
            isRead: true
        )

        if let index = conversations.firstIndex(where: { $0.otherUserHandle.lowercased() == key }) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                conversations[index].messages.append(message)
                let item = conversations.remove(at: index)
                conversations.insert(item, at: 0)
            }
        } else {
            let profile = getProfile(for: recipientHandle)
            var newConvo = DirectMessageConversation(
                otherUserHandle: profile.handle,
                otherUserName: profile.name,
                otherUserAthleteType: profile.athleteType,
                otherUserAvatarSymbol: profile.avatarSymbol,
                messages: [message]
            )
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                conversations.insert(newConvo, at: 0)
            }
        }

        // Simulate realistic reply if chatting with community athletes
        if key == "marcus_lifts" || key == "elena_runs" || key == "kai_athletic" {
            scheduleSimulatedReply(for: key, recipientText: text)
        }
    }

    private func scheduleSimulatedReply(for handle: String, recipientText: String) {
        let replies: [String: [String]] = [
            "marcus_lifts": [
                "Lethal mindset! Keep pushing the progression.",
                "Let's lock in that workout session soon. Keep the velocity high!",
                "Great work on keeping the form strict."
            ],
            "elena_runs": [
                "Love the dedication! What cadence are you targeting next?",
                "That route has great elevation. Stay hydrated and crush it!",
                "See you out on the trails! ⚡"
            ],
            "kai_athletic": [
                "Hybrid standard all day. Barbell + miles = unstoppable.",
                "Hit those macros tonight for optimal recovery!"
            ]
        ]

        let options = replies[handle] ?? ["Let's get it! Strong work."]
        let replyText = options.randomElement() ?? "Right on! Keep at it."

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) { [weak self] in
            guard let self = self else { return }
            let simulatedMsg = DirectMessageItem(
                senderHandle: handle,
                recipientHandle: "alex_solxce",
                text: replyText,
                timestamp: Date(),
                isFromCurrentUser: false,
                isRead: false
            )
            if let index = self.conversations.firstIndex(where: { $0.otherUserHandle.lowercased() == handle }) {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    self.conversations[index].messages.append(simulatedMsg)
                }
            }
        }
    }

    public func markConversationAsRead(for handle: String) {
        let key = handle.lowercased()
        guard let index = conversations.firstIndex(where: { $0.otherUserHandle.lowercased() == key }) else { return }
        for i in 0..<conversations[index].messages.count {
            conversations[index].messages[i].isRead = true
        }
    }
}
