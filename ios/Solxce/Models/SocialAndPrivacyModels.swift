// Models/SocialAndPrivacyModels.swift
import Foundation
import SwiftUI
import Combine

// MARK: - Privacy Settings Options
public enum DMReceivePermission: String, CaseIterable, Codable, Identifiable {
    case everyone = "Everyone"
    case athletesIFollow = "Athletes I Follow"
    case nobody = "Nobody"

    public var id: String { rawValue }

    public var description: String {
        switch self {
        case .everyone: return "Any athlete on Solxce can send you a message."
        case .athletesIFollow: return "Only athletes you follow can start a chat."
        case .nobody: return "Disable all incoming direct messages."
        }
    }
}

public enum PostVisibilityRule: String, CaseIterable, Codable, Identifiable {
    case publicCommunity = "Public Community"
    case followersOnly = "Followers Only"
    case privateArchive = "Private (Only You)"

    public var id: String { rawValue }
}

// MARK: - Direct Message Item
public struct DirectMessage: Identifiable, Codable, Equatable {
    public let id: UUID
    public let senderHandle: String
    public let text: String
    public let timestamp: Date
    public let isFromCurrentUser: Bool
    public var workoutShareSummary: String?

    public init(
        id: UUID = UUID(),
        senderHandle: String,
        text: String,
        timestamp: Date = Date(),
        isFromCurrentUser: Bool,
        workoutShareSummary: String? = nil
    ) {
        self.id = id
        self.senderHandle = senderHandle
        self.text = text
        self.timestamp = timestamp
        self.isFromCurrentUser = isFromCurrentUser
        self.workoutShareSummary = workoutShareSummary
    }
}

// MARK: - Message Thread / Conversation
public struct AthleteConversation: Identifiable, Equatable {
    public let id: UUID
    public let participantHandle: String
    public let participantName: String
    public let athleteType: AthleteType
    public let avatarSymbol: String
    public var messages: [DirectMessage]
    public var unreadCount: Int
    public var lastActivity: Date

    public init(
        id: UUID = UUID(),
        participantHandle: String,
        participantName: String,
        athleteType: AthleteType,
        avatarSymbol: String = "figure.run",
        messages: [DirectMessage] = [],
        unreadCount: Int = 0,
        lastActivity: Date = Date()
    ) {
        self.id = id
        self.participantHandle = participantHandle
        self.participantName = participantName
        self.athleteType = athleteType
        self.avatarSymbol = avatarSymbol
        self.messages = messages
        self.unreadCount = unreadCount
        self.lastActivity = lastActivity
    }

    public var lastMessageText: String {
        messages.last?.text ?? "Started a conversation"
    }

    public var lastMessageTimeFormatted: String {
        guard let last = messages.last else { return "Just now" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: last.timestamp, relativeTo: Date())
    }
}

// MARK: - Other Athlete Public Profile Fixture Data
public struct CommunityAthlete: Identifiable, Equatable {
    public var id: String { handle }
    public let name: String
    public let handle: String
    public let athleteType: AthleteType
    public let bio: String
    public let location: String
    public let totalVolumeFormatted: String
    public let totalMilesFormatted: String
    public let avatarSymbol: String
    public var isVerifiedAthlete: Bool
    public var followersCount: Int
    public var followingCount: Int

    public init(
        name: String,
        handle: String,
        athleteType: AthleteType,
        bio: String,
        location: String = "Austin, TX",
        totalVolumeFormatted: String = "182K lbs",
        totalMilesFormatted: String = "420 mi",
        avatarSymbol: String = "figure.strengthtraining.traditional",
        isVerifiedAthlete: Bool = true,
        followersCount: Int = 412,
        followingCount: Int = 189
    ) {
        self.name = name
        self.handle = handle
        self.athleteType = athleteType
        self.bio = bio
        self.location = location
        self.totalVolumeFormatted = totalVolumeFormatted
        self.totalMilesFormatted = totalMilesFormatted
        self.avatarSymbol = avatarSymbol
        self.isVerifiedAthlete = isVerifiedAthlete
        self.followersCount = followersCount
        self.followingCount = followingCount
    }
}

// MARK: - Centralized Social & Privacy Manager
@MainActor
public final class SocialPrivacyManager: ObservableObject {
    public static let shared = SocialPrivacyManager()

    // Follows & Following sets (stored by handle in lowercase)
    @Published public private(set) var followedHandles: Set<String> = [
        "marcus_lifts",
        "elena_runs"
    ]

    // Blocked handles set
    @Published public private(set) var blockedHandles: Set<String> = []

    // Privacy Settings
    @AppStorage("solxce_is_private_account") public var isPrivateAccount: Bool = false
    @AppStorage("solxce_dm_permission") public var dmPermissionRaw: String = DMReceivePermission.everyone.rawValue
    @AppStorage("solxce_post_visibility") public var postVisibilityRaw: String = PostVisibilityRule.publicCommunity.rawValue
    @AppStorage("solxce_show_activity_status") public var showActivityStatus: Bool = true
    @AppStorage("solxce_allow_tagging") public var allowTagging: Bool = true
    @AppStorage("solxce_share_workout_data_publicly") public var shareWorkoutDataPublicly: Bool = true

    // Direct Message Conversations
    @Published public var conversations: [AthleteConversation] = []

    // Known Community Athletes
    @Published public var communityAthletes: [String: CommunityAthlete] = [:]

    private init() {
        loadDefaultCommunityDirectory()
        loadDefaultConversations()
    }

    // MARK: - Follow / Unfollow Actions
    public func isFollowing(handle: String) -> Bool {
        followedHandles.contains(handle.lowercased())
    }

    public func toggleFollow(handle: String) {
        let key = handle.lowercased()
        if followedHandles.contains(key) {
            followedHandles.remove(key)
            if var athlete = communityAthletes[key] {
                athlete.followersCount = max(0, athlete.followersCount - 1)
                communityAthletes[key] = athlete
            }
        } else {
            followedHandles.insert(key)
            if var athlete = communityAthletes[key] {
                athlete.followersCount += 1
                communityAthletes[key] = athlete
            }
        }
    }

    // MARK: - Block / Unblock Actions
    public func isBlocked(handle: String) -> Bool {
        blockedHandles.contains(handle.lowercased())
    }

    public func blockUser(handle: String) {
        let key = handle.lowercased()
        blockedHandles.insert(key)
        // Also unfollow when blocked
        followedHandles.remove(key)
    }

    public func unblockUser(handle: String) {
        let key = handle.lowercased()
        blockedHandles.remove(key)
    }

    // MARK: - Privacy helpers
    public var dmPermission: DMReceivePermission {
        get { DMReceivePermission(rawValue: dmPermissionRaw) ?? .everyone }
        set { dmPermissionRaw = newValue.rawValue }
    }

    public var postVisibility: PostVisibilityRule {
        get { PostVisibilityRule(rawValue: postVisibilityRaw) ?? .publicCommunity }
        set { postVisibilityRaw = newValue.rawValue }
    }

    // MARK: - Direct Messaging Actions
    public func conversation(for handle: String) -> AthleteConversation? {
        conversations.first { $0.participantHandle.lowercased() == handle.lowercased() }
    }

    public func getOrCreateConversation(with athlete: CommunityAthlete) -> AthleteConversation {
        let key = athlete.handle.lowercased()
        if let existing = conversations.first(where: { $0.participantHandle.lowercased() == key }) {
            return existing
        }

        let newConversation = AthleteConversation(
            participantHandle: athlete.handle,
            participantName: athlete.name,
            athleteType: athlete.athleteType,
            avatarSymbol: athlete.avatarSymbol,
            messages: [
                DirectMessage(
                    senderHandle: athlete.handle,
                    text: "Hey! Saw your training split on Solxce. Keep up the high standard! ⚡",
                    timestamp: Date().addingTimeInterval(-3600 * 4),
                    isFromCurrentUser: false
                )
            ],
            unreadCount: 0,
            lastActivity: Date()
        )
        conversations.insert(newConversation, at: 0)
        return newConversation
    }

    public func sendMessage(text: String, to handle: String, workoutShare: String? = nil) {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || workoutShare != nil else { return }

        let key = handle.lowercased()
        let newMsg = DirectMessage(
            senderHandle: "solxce_athlete",
            text: text,
            timestamp: Date(),
            isFromCurrentUser: true,
            workoutShareSummary: workoutShare
        )

        if let index = conversations.firstIndex(where: { $0.participantHandle.lowercased() == key }) {
            conversations[index].messages.append(newMsg)
            conversations[index].lastActivity = Date()
            let conv = conversations.remove(at: index)
            conversations.insert(conv, at: 0)
        } else {
            let athlete = communityAthletes[key] ?? CommunityAthlete(
                name: handle.capitalized,
                handle: handle,
                athleteType: .hybrid,
                bio: "Solxce Athlete"
            )
            var conv = AthleteConversation(
                participantHandle: athlete.handle,
                participantName: athlete.name,
                athleteType: athlete.athleteType,
                avatarSymbol: athlete.avatarSymbol,
                messages: [newMsg],
                unreadCount: 0,
                lastActivity: Date()
            )
            conversations.insert(conv, at: 0)
        }

        // Mock automated athlete reply after short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
            guard let self = self, !self.isBlocked(handle: handle) else { return }
            if let idx = self.conversations.firstIndex(where: { $0.participantHandle.lowercased() == key }) {
                let replies = [
                    "Appreciate the message! Crushing today's session.",
                    "Solid numbers! Let's lock in for this week's volume.",
                    "Thanks! Catch you on the leaderboard ⚡",
                    "Keep that pace up! Form looking razor sharp."
                ]
                let randomReply = replies.randomElement() ?? "Let's work!"
                let replyMsg = DirectMessage(
                    senderHandle: handle,
                    text: randomReply,
                    timestamp: Date(),
                    isFromCurrentUser: false
                )
                self.conversations[idx].messages.append(replyMsg)
                self.conversations[idx].lastActivity = Date()
            }
        }
    }

    public func markConversationRead(handle: String) {
        if let index = conversations.firstIndex(where: { $0.participantHandle.lowercased() == handle.lowercased() }) {
            conversations[index].unreadCount = 0
        }
    }

    // MARK: - Initial Directory & Seeds
    private func loadDefaultCommunityDirectory() {
        let list: [CommunityAthlete] = [
            CommunityAthlete(
                name: "Marcus Vance",
                handle: "marcus_lifts",
                athleteType: .powerlifter,
                bio: "Raw Powerlifting · SBD 1,650 lbs total · Strength Coach & Athlete.",
                location: "Denver, CO",
                totalVolumeFormatted: "320K lbs",
                totalMilesFormatted: "84 mi",
                avatarSymbol: "figure.strengthtraining.traditional",
                isVerifiedAthlete: true,
                followersCount: 1420,
                followingCount: 230
            ),
            CommunityAthlete(
                name: "Elena Rostova",
                handle: "elena_runs",
                athleteType: .runner,
                bio: "Sub-3:00 Marathoner · Ultra trail runner · Aerobic base architect 🏃‍♀️",
                location: "Boulder, CO",
                totalVolumeFormatted: "45K lbs",
                totalMilesFormatted: "1,240 mi",
                avatarSymbol: "figure.run",
                isVerifiedAthlete: true,
                followersCount: 2840,
                followingCount: 310
            ),
            CommunityAthlete(
                name: "Kai Takahashi",
                handle: "kai_athletic",
                athleteType: .hybrid,
                bio: "Lifting 405 + Running sub-20 5Ks. Dual-threat training standard.",
                location: "Seattle, WA",
                totalVolumeFormatted: "260K lbs",
                totalMilesFormatted: "680 mi",
                avatarSymbol: "bolt.shield.fill",
                isVerifiedAthlete: true,
                followersCount: 1980,
                followingCount: 420
            ),
            CommunityAthlete(
                name: "Maya Lin",
                handle: "maya_rings",
                athleteType: .calisthenics,
                bio: "Bodyweight mastery, gymnastic rings, lever holds & strict muscle ups.",
                location: "San Francisco, CA",
                totalVolumeFormatted: "110K lbs",
                totalMilesFormatted: "140 mi",
                avatarSymbol: "figure.gymnastics",
                isVerifiedAthlete: true,
                followersCount: 3120,
                followingCount: 180
            ),
            CommunityAthlete(
                name: "Sarah Jenkins",
                handle: "sarah_lifts",
                athleteType: .bodybuilder,
                bio: "Hypertrophy & progressive overload enthusiast. Science-backed lifting.",
                location: "Austin, TX",
                totalVolumeFormatted: "410K lbs",
                totalMilesFormatted: "115 mi",
                avatarSymbol: "figure.arms.open",
                isVerifiedAthlete: true,
                followersCount: 1890,
                followingCount: 260
            ),
            CommunityAthlete(
                name: "Coach Dave",
                handle: "coach_dave",
                athleteType: .functional,
                bio: "CrossFit Level 3 Coach · WOD programmer · High-output conditioning.",
                location: "San Diego, CA",
                totalVolumeFormatted: "295K lbs",
                totalMilesFormatted: "510 mi",
                avatarSymbol: "flame.fill",
                isVerifiedAthlete: true,
                followersCount: 2240,
                followingCount: 340
            )
        ]

        for athlete in list {
            communityAthletes[athlete.handle.lowercased()] = athlete
        }
    }

    private func loadDefaultConversations() {
        let marcus = communityAthletes["marcus_lifts"]!
        let elena = communityAthletes["elena_runs"]!

        conversations = [
            AthleteConversation(
                participantHandle: marcus.handle,
                participantName: marcus.name,
                athleteType: marcus.athleteType,
                avatarSymbol: marcus.avatarSymbol,
                messages: [
                    DirectMessage(
                        senderHandle: marcus.handle,
                        text: "Great bench speed on that 315 lbs working set yesterday! Crisp lockout.",
                        timestamp: Date().addingTimeInterval(-3600 * 2),
                        isFromCurrentUser: false
                    ),
                    DirectMessage(
                        senderHandle: "solxce_athlete",
                        text: "Thanks Marcus! Focused on keeping the lats tight and driving through the floor.",
                        timestamp: Date().addingTimeInterval(-3600 * 1.5),
                        isFromCurrentUser: true
                    ),
                    DirectMessage(
                        senderHandle: marcus.handle,
                        text: "That bar path was pure efficiency. Keep pushing for that 335 single!",
                        timestamp: Date().addingTimeInterval(-1800),
                        isFromCurrentUser: false
                    )
                ],
                unreadCount: 1,
                lastActivity: Date().addingTimeInterval(-1800)
            ),
            AthleteConversation(
                participantHandle: elena.handle,
                participantName: elena.name,
                athleteType: elena.athleteType,
                avatarSymbol: elena.avatarSymbol,
                messages: [
                    DirectMessage(
                        senderHandle: elena.handle,
                        text: "Are you running the 10-mile trail route this Saturday morning?",
                        timestamp: Date().addingTimeInterval(-86400 * 1.2),
                        isFromCurrentUser: false
                    ),
                    DirectMessage(
                        senderHandle: "solxce_athlete",
                        text: "Yes! Planning for an early 7:00 AM start before the temperature spikes.",
                        timestamp: Date().addingTimeInterval(-86400 * 1.1),
                        isFromCurrentUser: true
                    )
                ],
                unreadCount: 0,
                lastActivity: Date().addingTimeInterval(-86400 * 1.1)
            )
        ]
    }
}
