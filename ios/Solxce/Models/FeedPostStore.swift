// Models/FeedPostStore.swift
import Foundation
import SwiftUI
import Combine

@MainActor
public final class FeedPostStore: ObservableObject {
    public static let shared = FeedPostStore()

    @Published public var posts: [AthletePost] = []
    @Published public var filteredAthleteType: AthleteType? = nil
    @Published public var communityFilter: CommunityFilter = .forYou

    public enum CommunityFilter: String, CaseIterable, Identifiable {
        case forYou = "For You"
        case following = "Following"
        case local = "Austin Hub"

        public var id: String { rawValue }
    }

    private init() {
        loadInitialPosts()
    }

    public var displayedPosts: [AthletePost] {
        let socialManager = SocialPrivacyManager.shared
        return posts.filter { post in
            // Filter out posts from blocked athletes
            if socialManager.isBlocked(handle: post.authorHandle) {
                return false
            }

            // Following filter check
            if communityFilter == .following {
                let isFollowed = socialManager.isFollowing(handle: post.authorHandle)
                let isSelf = post.authorHandle == "solxce_athlete"
                if !isFollowed && !isSelf {
                    return false
                }
            }

            // Athlete type filter
            if let filter = filteredAthleteType, post.athleteType != filter {
                return false
            }
            return true
        }
    }

    public func userPosts(handle: String) -> [AthletePost] {
        let key = handle.lowercased()
        let matching = posts.filter { $0.authorHandle.lowercased() == key }
        if matching.isEmpty {
            // Return synthetic posts for directory athletes so their profile grid is never barren
            return [
                AthletePost(
                    authorName: handle.replacingOccurrences(of: "_", with: " ").capitalized,
                    authorHandle: handle,
                    athleteType: .hybrid,
                    workoutTag: "STRENGTH & CONDITIONING",
                    caption: "Locked in on the progressive overload targets for the week. ⚡",
                    timeAgo: "2d ago",
                    likesCount: 184,
                    commentsCount: 22,
                    gradientColors: [Color(hex: "#1F2937"), Color(hex: "#111827")],
                    mediaIconName: "figure.strengthtraining.traditional",
                    isVerified: true
                ),
                AthletePost(
                    authorName: handle.replacingOccurrences(of: "_", with: " ").capitalized,
                    authorHandle: handle,
                    athleteType: .hybrid,
                    workoutTag: "AEROBIC BASE",
                    caption: "Zone 2 aerobic threshold miles at sunrise. Keeping heart rate locked at 145 bpm.",
                    timeAgo: "4d ago",
                    likesCount: 295,
                    commentsCount: 31,
                    gradientColors: [Color(hex: "#0F766E"), Color(hex: "#115E59")],
                    mediaIconName: "figure.run",
                    isVerified: true
                ),
                AthletePost(
                    authorName: handle.replacingOccurrences(of: "_", with: " ").capitalized,
                    authorHandle: handle,
                    athleteType: .hybrid,
                    workoutTag: "HEAVY RECOVERY",
                    caption: "Active mobility, cold plunge, and sauna protocol.",
                    timeAgo: "6d ago",
                    likesCount: 142,
                    commentsCount: 16,
                    gradientColors: [Color(hex: "#374151"), Color(hex: "#1F2937")],
                    mediaIconName: "flame.fill",
                    isVerified: true
                )
            ]
        }
        return matching
    }

    public func userReels(handle: String) -> [AthletePost] {
        let userAll = userPosts(handle: handle)
        let reels = userAll.filter { $0.mediaType == .video }
        if reels.isEmpty {
            return [
                AthletePost(
                    authorName: handle.replacingOccurrences(of: "_", with: " ").capitalized,
                    authorHandle: handle,
                    athleteType: .hybrid,
                    workoutTag: "COMPETITION SET",
                    caption: "405 lbs Barbell Squat pause double. High bar mechanics.",
                    timeAgo: "1w ago",
                    likesCount: 520,
                    commentsCount: 64,
                    gradientColors: [Color(hex: "#4F46E5"), Color(hex: "#312E81")],
                    mediaType: .video,
                    mediaIconName: "play.circle.fill",
                    isVerified: true
                )
            ]
        }
        return reels
    }

    public func addPost(
        caption: String,
        workoutTag: String,
        mediaItems: [PostMediaItem],
        athleteType: AthleteType,
        audioTrack: AudioTrack? = nil
    ) {
        let newPost = AthletePost(
            authorName: "Alex Rivera",
            authorHandle: "solxce_athlete",
            athleteType: athleteType,
            workoutTag: workoutTag.uppercased(),
            caption: caption,
            timeAgo: "Just now",
            likesCount: 1,
            commentsCount: 0,
            gradientColors: [Color(hex: "#00E5FF"), Color(hex: "#0072FF")],
            mediaType: (mediaItems.first?.type == .video) ? .video : .photo,
            mediaIconName: (mediaItems.first?.type == .video) ? "play.circle.fill" : "camera.fill",
            isVerified: true,
            audioTrack: audioTrack,
            mediaItems: mediaItems.isEmpty ? [PostMediaItem(type: .photo, placeholderGradient: [Color(hex: "#18181B"), Color(hex: "#09090B")])] : mediaItems
        )
        posts.insert(newPost, at: 0)
    }

    private func loadInitialPosts() {
        posts = [
            AthletePost(
                authorName: "Marcus Vance",
                authorHandle: "marcus_lifts",
                athleteType: .powerlifter,
                workoutTag: "HEAVY BENCH DAY",
                caption: "Hit 335 lbs for a crisp pause single before working down to 285 lbs 4x5. Bar path felt completely dialed in today.",
                timeAgo: "2h ago",
                likesCount: 248,
                commentsCount: 34,
                gradientColors: [Color(hex: "#EF4444"), Color(hex: "#7F1D1D")],
                mediaType: .multiPhoto,
                mediaIconName: "figure.strengthtraining.traditional",
                isVerified: true,
                audioTrack: AudioTrack(title: "Can't Be Touched", artist: "Roy Jones Jr.", platform: .appleMusic),
                mediaItems: [
                    PostMediaItem(type: .photo, placeholderGradient: [Color(hex: "#DC2626"), Color(hex: "#450A0A")]),
                    PostMediaItem(type: .photo, placeholderGradient: [Color(hex: "#991B1B"), Color(hex: "#1E1E24")]),
                    PostMediaItem(type: .photo, placeholderGradient: [Color(hex: "#7F1D1D"), Color(hex: "#111827")])
                ]
            ),
            AthletePost(
                authorName: "Elena Rostova",
                authorHandle: "elena_runs",
                athleteType: .runner,
                workoutTag: "MORNING THRESHOLD",
                caption: "12-mile progressive tempo through the hills. Splits averaged 6:42 min/mi. Aerobic engine feels stronger than ever.",
                timeAgo: "4h ago",
                likesCount: 412,
                commentsCount: 56,
                gradientColors: [Color(hex: "#06B6D4"), Color(hex: "#0E7490")],
                mediaType: .video,
                mediaIconName: "figure.run",
                isVerified: true,
                audioTrack: AudioTrack(title: "Midnight City", artist: "M83", platform: .spotify),
                mediaItems: [
                    PostMediaItem(type: .video, placeholderGradient: [Color(hex: "#0891B2"), Color(hex: "#164E63")])
                ]
            ),
            AthletePost(
                authorName: "Kai Takahashi",
                authorHandle: "kai_athletic",
                athleteType: .hybrid,
                workoutTag: "DUAL HYBRID TEST",
                caption: "Deadlifted 500 lbs at 7 AM followed by an 8-mile aerobic run at dusk. Proving strength and endurance belong together.",
                timeAgo: "6h ago",
                likesCount: 589,
                commentsCount: 82,
                gradientColors: [Color(hex: "#F59E0B"), Color(hex: "#78350F")],
                mediaType: .photo,
                mediaIconName: "bolt.shield.fill",
                isVerified: true,
                audioTrack: AudioTrack(title: "Stronger", artist: "Kanye West", platform: .appleMusic),
                mediaItems: [
                    PostMediaItem(type: .photo, placeholderGradient: [Color(hex: "#D97706"), Color(hex: "#451A03")])
                ]
            ),
            AthletePost(
                authorName: "Maya Lin",
                authorHandle: "maya_rings",
                athleteType: .calisthenics,
                workoutTag: "RING MASTERY",
                caption: "Full layout front lever holds into strict ring muscle ups. Clean form and zero momentum.",
                timeAgo: "8h ago",
                likesCount: 374,
                commentsCount: 45,
                gradientColors: [Color(hex: "#8B5CF6"), Color(hex: "#4C1D95")],
                mediaType: .multiPhoto,
                mediaIconName: "figure.gymnastics",
                isVerified: true,
                audioTrack: AudioTrack(title: "Intro", artist: "The xx", platform: .spotify),
                mediaItems: [
                    PostMediaItem(type: .photo, placeholderGradient: [Color(hex: "#7C3AED"), Color(hex: "#2E1065")]),
                    PostMediaItem(type: .photo, placeholderGradient: [Color(hex: "#6D28D9"), Color(hex: "#1E1B4B")])
                ]
            )
        ]
    }
}
