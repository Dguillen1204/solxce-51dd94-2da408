// Models/SocialRelationshipStore.swift
import SwiftUI
import Combine

public struct AthleteProfileData: Identifiable, Hashable {
    public let id: String
    public let name: String
    public let handle: String
    public let athleteType: AthleteType
    public let bio: String
    public let location: String
    public let weeklyVolumeMiles: Double
    public let weeklyVolumeLbs: Double
    public let totalWorkouts: Int
    public let profileImageName: String?
    public var isVerified: Bool
    public var followersCount: Int
    public var followingCount: Int

    public init(
        id: String,
        name: String,
        handle: String,
        athleteType: AthleteType,
        bio: String,
        location: String = "Austin, TX",
        weeklyVolumeMiles: Double = 26.4,
        weeklyVolumeLbs: Double = 42500,
        totalWorkouts: Int = 184,
        profileImageName: String? = nil,
        isVerified: Bool = true,
        followersCount: Int = 1420,
        followingCount: Int = 380
    ) {
        self.id = id
        self.name = name
        self.handle = handle
        self.athleteType = athleteType
        self.bio = bio
        self.location = location
        self.weeklyVolumeMiles = weeklyVolumeMiles
        self.weeklyVolumeLbs = weeklyVolumeLbs
        self.totalWorkouts = totalWorkouts
        self.profileImageName = profileImageName
        self.isVerified = isVerified
        self.followersCount = followersCount
        self.followingCount = followingCount
    }
}

public enum ProfileVisibility: String, CaseIterable, Identifiable {
    case everyone = "Everyone (Public)"
    case followersOnly = "Followers Only"
    case privateAccount = "Private"

    public var id: String { rawValue }
    public var description: String {
        switch self {
        case .everyone: return "Anyone can see your profile, posts, and stats."
        case .followersOnly: return "Only approved followers can view your workouts."
        case .privateAccount: return "Your profile and activity are hidden."
        }
    }
}

public enum MessagePermission: String, CaseIterable, Identifiable {
    case everyone = "Everyone"
    case peopleIFollow = "Athletes I Follow"
    case noOne = "No One"

    public var id: String { rawValue }
    public var description: String {
        switch self {
        case .everyone: return "Any Solxce member can send you direct messages."
        case .peopleIFollow: return "Only athletes you follow can start a chat."
        case .noOne: return "Disable all incoming direct messages."
        }
    }
}

public final class SocialRelationshipStore: ObservableObject {
    public static let shared = SocialRelationshipStore()

    @AppStorage("solxce_followed_handles") private var followedHandlesRaw: String = "marcus_vance,elena_lifts"
    @AppStorage("solxce_blocked_handles") private var blockedHandlesRaw: String = ""
    @AppStorage("solxce_privacy_visibility") public var profileVisibilityRaw: String = ProfileVisibility.everyone.rawValue
    @AppStorage("solxce_privacy_messages") public var messagePermissionRaw: String = MessagePermission.everyone.rawValue
    @AppStorage("solxce_privacy_hide_splits") public var hideWorkoutSplits: Bool = false
    @AppStorage("solxce_privacy_hide_weight") public var hideBodyWeight: Bool = true
    @AppStorage("solxce_privacy_show_online_status") public var showOnlineStatus: Bool = true

    @Published public private(set) var followedHandles: Set<String> = []
    @Published public private(set) var blockedHandles: Set<String> = []

    public init() {
        self.followedHandles = Set(followedHandlesRaw.split(separator: ",").map(String.init).filter { !$0.isEmpty })
        self.blockedHandles = Set(blockedHandlesRaw.split(separator: ",").map(String.init).filter { !$0.isEmpty })
    }

    public var profileVisibility: ProfileVisibility {
        get { ProfileVisibility(rawValue: profileVisibilityRaw) ?? .everyone }
        set {
            profileVisibilityRaw = newValue.rawValue
            objectWillChange.send()
        }
    }

    public var messagePermission: MessagePermission {
        get { MessagePermission(rawValue: messagePermissionRaw) ?? .everyone }
        set {
            messagePermissionRaw = newValue.rawValue
            objectWillChange.send()
        }
    }

    public func isFollowing(handle: String) -> Bool {
        let clean = handle.lowercased().trimmingCharacters(in: CharacterSet(charactersIn: "@"))
        return followedHandles.contains(clean)
    }

    public func isBlocked(handle: String) -> Bool {
        let clean = handle.lowercased().trimmingCharacters(in: CharacterSet(charactersIn: "@"))
        return blockedHandles.contains(clean)
    }

    public func toggleFollow(handle: String) {
        let clean = handle.lowercased().trimmingCharacters(in: CharacterSet(charactersIn: "@"))
        if followedHandles.contains(clean) {
            unfollow(handle: clean)
        } else {
            follow(handle: clean)
        }
    }

    public func follow(handle: String) {
        let clean = handle.lowercased().trimmingCharacters(in: CharacterSet(charactersIn: "@"))
        guard !clean.isEmpty else { return }
        // If user was blocked, unblock them
        if blockedHandles.contains(clean) {
            unblock(handle: clean)
        }
        followedHandles.insert(clean)
        persistFollowed()
    }

    public func unfollow(handle: String) {
        let clean = handle.lowercased().trimmingCharacters(in: CharacterSet(charactersIn: "@"))
        followedHandles.remove(clean)
        persistFollowed()
    }

    public func block(handle: String) {
        let clean = handle.lowercased().trimmingCharacters(in: CharacterSet(charactersIn: "@"))
        guard !clean.isEmpty else { return }
        followedHandles.remove(clean)
        persistFollowed()
        blockedHandles.insert(clean)
        persistBlocked()
    }

    public func unblock(handle: String) {
        let clean = handle.lowercased().trimmingCharacters(in: CharacterSet(charactersIn: "@"))
        blockedHandles.remove(clean)
        persistBlocked()
    }

    private func persistFollowed() {
        followedHandlesRaw = followedHandles.joined(separator: ",")
        objectWillChange.send()
    }

    private func persistBlocked() {
        blockedHandlesRaw = blockedHandles.joined(separator: ",")
        objectWillChange.send()
    }

    public static let sampleAthletes: [String: AthleteProfileData] = [
        "marcus_vance": AthleteProfileData(
            id: "marcus_vance",
            name: "Marcus Vance",
            handle: "marcus_vance",
            athleteType: .hybrid,
            bio: "Sub-3 marathoner & 500lb deadlifter. Chasing peak hybrid human performance.",
            location: "Denver, CO",
            weeklyVolumeMiles: 38.5,
            weeklyVolumeLbs: 68400,
            totalWorkouts: 412,
            followersCount: 3890,
            followingCount: 412
        ),
        "elena_lifts": AthleteProfileData(
            id: "elena_lifts",
            name: "Elena Rostova",
            handle: "elena_lifts",
            athleteType: .powerlifter,
            bio: "IPF 63kg Powerlifter. 3x National Champ. Heavy squats and high volume.",
            location: "Miami, FL",
            weeklyVolumeMiles: 6.2,
            weeklyVolumeLbs: 94200,
            totalWorkouts: 580,
            followersCount: 5420,
            followingCount: 290
        ),
        "charlotte_cross": AthleteProfileData(
            id: "charlotte_cross",
            name: "Charlotte Davis",
            handle: "charlotte_cross",
            athleteType: .crossfit,
            bio: "Semifinals CrossFit athlete. Gymnastics, barbell cycling, and diesel engine capacity.",
            location: "Austin, TX",
            weeklyVolumeMiles: 18.0,
            weeklyVolumeLbs: 52100,
            totalWorkouts: 340,
            followersCount: 2190,
            followingCount: 310
        ),
        "jordan_miles": AthleteProfileData(
            id: "jordan_miles",
            name: "Jordan Hayes",
            handle: "jordan_miles",
            athleteType: .runner,
            bio: "Ultra endurance runner (50k / 100k). High-altitude mountain trails.",
            location: "Boulder, CO",
            weeklyVolumeMiles: 64.2,
            weeklyVolumeLbs: 12400,
            totalWorkouts: 480,
            followersCount: 4210,
            followingCount: 195
        ),
        "kai_zen": AthleteProfileData(
            id: "kai_zen",
            name: "Kai Nakamura",
            handle: "kai_zen",
            athleteType: .hyrox,
            bio: "HYROX Pro Men's racer. Sled push specialist. Pushing threshold every session.",
            location: "San Diego, CA",
            weeklyVolumeMiles: 29.8,
            weeklyVolumeLbs: 48900,
            totalWorkouts: 290,
            followersCount: 1840,
            followingCount: 220
        )
    ]

    public func getAthleteProfile(for handle: String, fallbackName: String = "Athlete", fallbackType: AthleteType = .hybrid) -> AthleteProfileData {
        let clean = handle.lowercased().trimmingCharacters(in: CharacterSet(charactersIn: "@"))
        if let found = Self.sampleAthletes[clean] {
            var mutable = found
            if isFollowing(handle: clean) {
                mutable.followersCount += 1
            }
            return mutable
        }
        return AthleteProfileData(
            id: clean,
            name: fallbackName.isEmpty ? clean.capitalized : fallbackName,
            handle: clean,
            athleteType: fallbackType,
            bio: "Solxce Athlete pushing limits and building consistency every single day.",
            location: "Everywhere",
            weeklyVolumeMiles: 22.4,
            weeklyVolumeLbs: 35000,
            totalWorkouts: 120,
            followersCount: 840 + (isFollowing(handle: clean) ? 1 : 0),
            followingCount: 240
        )
    }
}
