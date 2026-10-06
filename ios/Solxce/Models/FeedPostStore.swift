// Models/FeedPostStore.swift
import SwiftUI
import Combine

/// Centralized post store managing community and user posts across Feed and Profile views.
@MainActor
public final class FeedPostStore: ObservableObject {
    public static let shared = FeedPostStore()

    @Published public var posts: [AthletePost] = []

    public init() {
        self.posts = Self.initialPosts
    }

    /// User posts matching the current user's handle
    public func userPosts(handle: String) -> [AthletePost] {
        posts.filter { $0.authorHandle.lowercased() == handle.lowercased() }
    }

    /// User reel/video posts
    public func userReels(handle: String) -> [AthletePost] {
        userPosts(handle: handle).filter { $0.mediaType == .video }
    }

    /// Add a newly created post at the top of the feed & profile
    public func addPost(_ post: AthletePost) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            posts.insert(post, at: 0)
        }
    }

    /// Toggle like state on a post
    public func toggleLike(for postID: UUID) {
        guard let index = posts.firstIndex(where: { $0.id == postID }) else { return }
        withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
            if posts[index].isLiked {
                posts[index].isLiked = false
                posts[index].likesCount = max(0, posts[index].likesCount - 1)
            } else {
                posts[index].isLiked = true
                posts[index].likesCount += 1
            }
        }
    }

    /// Append comment
    public func addComment(_ comment: PostComment, to postID: UUID) {
        guard let index = posts.firstIndex(where: { $0.id == postID }) else { return }
        withAnimation(.spring()) {
            posts[index].comments.append(comment)
        }
    }

    /// Default seed posts for community feed & demo user profile
    public static var initialPosts: [AthletePost] {
        [
            // User's own showcase post 1 (Multi-photo Carousel)
            AthletePost(
                authorName: "Alex Rivera",
                authorHandle: "alex_solxce",
                athleteType: .hybrid,
                timeAgo: "1h ago",
                workoutTag: "HYBRID OVERLOAD",
                workoutStats: "5 sets · 315 lbs Bench + 5K Aerobic Split",
                caption: "Morning session unlocked a new milestone. 315 lbs moved with crisp bar path velocity before hitting the track for a 19:40 5K! ⚡",
                imageName: "dumbbell.fill",
                mediaType: .photo,
                mediaItems: [
                    PostMediaItem(id: "user_photo_1", title: "315 lbs Lockout", iconName: "dumbbell.fill", gradientHexes: ["#240D0D", "#4A1818"], subtitle: "Photo 1 of 3 · Set 5 PR", isVideo: false),
                    PostMediaItem(id: "user_photo_2", title: "5K Split & Pace", iconName: "figure.run", gradientHexes: ["#0D2429", "#15424D"], subtitle: "Photo 2 of 3 · 6:20 /mi Pace", isVideo: false),
                    PostMediaItem(id: "user_photo_3", title: "Recovery & Macro Target", iconName: "flame.fill", gradientHexes: ["#291A08", "#4A2F0F"], subtitle: "Photo 3 of 3 · 210g Protein", isVideo: false)
                ],
                mediaIconName: "dumbbell.fill",
                gradientColors: [Color(red: 0.25, green: 0.05, blue: 0.05), Color(red: 0.45, green: 0.1, blue: 0.1)],
                audioTrack: AudioTrack.library[0],
                textOverlay: "315 LBS + 5K SPLIT 🔥",
                likesCount: 94,
                isLiked: false,
                comments: [
                    PostComment(author: "marcus_lifts", athleteType: .powerlifter, text: "Great bench speed on that set!", timeAgo: "40m ago"),
                    PostComment(author: "elena_runs", athleteType: .runner, text: "That 5k split right after lifting is unreal 🙌", timeAgo: "20m ago")
                ]
            ),
            // User's own showcase post 2 (Video Reel)
            AthletePost(
                authorName: "Alex Rivera",
                authorHandle: "alex_solxce",
                athleteType: .hybrid,
                timeAgo: "2d ago",
                workoutTag: "DEADLIFT FORM CHECK",
                workoutStats: "405 lbs x 4 Reps · RPE 8.5",
                caption: "Form check on the 405 lbs working set. Strict hip drive and locked lats. Sound on for workout soundtrack! 🎵",
                imageName: "bolt.shield.fill",
                mediaType: .video,
                mediaItems: [
                    PostMediaItem(id: "user_vid_1", title: "405 lbs Deadlift 4K Reel", iconName: "bolt.shield.fill", gradientHexes: ["#1F0E0E", "#3D1A1A"], subtitle: "4K 60fps Form Clip", isVideo: true)
                ],
                mediaIconName: "bolt.shield.fill",
                gradientColors: [Color(red: 0.15, green: 0.05, blue: 0.05), Color(red: 0.35, green: 0.1, blue: 0.1)],
                audioTrack: AudioTrack.library[6],
                textOverlay: "405 LBS WORKING SET",
                likesCount: 156,
                isLiked: true,
                comments: [
                    PostComment(author: "coach_dave", athleteType: .functional, text: "Flawless bar path from the floor.", timeAgo: "1d ago")
                ]
            ),
            // User's own showcase post 3 (Photo)
            AthletePost(
                authorName: "Alex Rivera",
                authorHandle: "alex_solxce",
                athleteType: .hybrid,
                timeAgo: "4d ago",
                workoutTag: "OUTDOOR TRAIL 10 MILE",
                workoutStats: "10.02 mi · 1:12:45 · 7'15\" /mi",
                caption: "Long aerobic base run through the hills. Testing pace endurance and hydration strategy.",
                imageName: "figure.run",
                mediaType: .photo,
                mediaItems: [
                    PostMediaItem(id: "user_photo_4", title: "Elevation & Heart Rate", iconName: "figure.run", gradientHexes: ["#0B1B2B", "#163452"], subtitle: "Photo 1 of 2 · Zone 3 Heart Rate", isVideo: false),
                    PostMediaItem(id: "user_photo_5", title: "Summit View", iconName: "mountain.2.fill", gradientHexes: ["#0E261D", "#1C4A39"], subtitle: "Photo 2 of 2 · 840 ft Elevation Gain", isVideo: false)
                ],
                mediaIconName: "figure.run",
                gradientColors: [Color(red: 0.05, green: 0.15, blue: 0.25), Color(red: 0.1, green: 0.3, blue: 0.4)],
                audioTrack: AudioTrack.library[10],
                textOverlay: "TRAIL ENDURANCE ⚡",
                likesCount: 112,
                isLiked: false,
                comments: []
            ),
            // User's own showcase post 4 (Reel)
            AthletePost(
                authorName: "Alex Rivera",
                authorHandle: "alex_solxce",
                athleteType: .hybrid,
                timeAgo: "6d ago",
                workoutTag: "PLYOMETRIC BOX JUMPS",
                workoutStats: "42-inch Box Jump Explosiveness",
                caption: "Working on power output and ankle stiffness. Explosive power day in full effect.",
                imageName: "figure.jumprope",
                mediaType: .video,
                mediaItems: [
                    PostMediaItem(id: "user_vid_2", title: "42-inch Box Jump Clip", iconName: "figure.jumprope", gradientHexes: ["#14240B", "#253E13"], subtitle: "4K High Speed Capture", isVideo: true)
                ],
                mediaIconName: "figure.jumprope",
                gradientColors: [Color(red: 0.1, green: 0.2, blue: 0.05), Color(red: 0.2, green: 0.35, blue: 0.1)],
                audioTrack: AudioTrack.library[8],
                textOverlay: "EXPLOSIVE VELOCITY 🚀",
                likesCount: 88,
                isLiked: true,
                comments: []
            ),
            // User's own showcase post 5 (Photo)
            AthletePost(
                authorName: "Alex Rivera",
                authorHandle: "alex_solxce",
                athleteType: .hybrid,
                timeAgo: "1w ago",
                workoutTag: "MACRO RECOVERY MEAL",
                workoutStats: "2,400 kcal · 195g Protein · 240g Carbs",
                caption: "Fueling the engine after high-intensity training. High protein, clean fuel, optimal recovery.",
                imageName: "fork.knife",
                mediaType: .photo,
                mediaItems: [
                    PostMediaItem(id: "user_photo_6", title: "Post-Workout Nutrition", iconName: "fork.knife", gradientHexes: ["#241505", "#472808"], subtitle: "Photo 1 of 1 · Nutrient Dense Plate", isVideo: false)
                ],
                mediaIconName: "fork.knife",
                gradientColors: [Color(red: 0.2, green: 0.12, blue: 0.05), Color(red: 0.35, green: 0.22, blue: 0.1)],
                audioTrack: AudioTrack.library[3],
                textOverlay: "FUEL THE ENGINE 🥗",
                likesCount: 73,
                isLiked: false,
                comments: []
            ),
            // Community Post: Marcus Vance
            AthletePost(
                authorName: "Marcus Vance",
                authorHandle: "marcus_lifts",
                athleteType: .powerlifter,
                timeAgo: "2h ago",
                workoutTag: "CHEST & TRICEPS",
                workoutStats: "6 exercises · 22 sets · 18,400 lbs volume",
                caption: "New PR on bench today! 315 lbs for a clean double. Swipe right to check the lockout and velocity bar path charts! 👉",
                imageName: "dumbbell.fill",
                mediaType: .photo,
                mediaItems: [
                    PostMediaItem(id: "mv_1", title: "315 lbs Bench Lockout", iconName: "dumbbell.fill", gradientHexes: ["#240D0D", "#4A1818"], subtitle: "Photo 1 of 3 · Set 4 Double", isVideo: false),
                    PostMediaItem(id: "mv_2", title: "Bar Path & Velocity", iconName: "chart.line.uptrend.xyaxis", gradientHexes: ["#141926", "#212B42"], subtitle: "Photo 2 of 3 · 0.44 m/s", isVideo: false),
                    PostMediaItem(id: "mv_3", title: "Post-Bench Hypertrophy", iconName: "figure.arms.open", gradientHexes: ["#291A08", "#4A2F0F"], subtitle: "Photo 3 of 3 · Chest Finisher", isVideo: false)
                ],
                mediaIconName: "dumbbell.fill",
                gradientColors: [Color(red: 0.25, green: 0.05, blue: 0.05), Color(red: 0.45, green: 0.1, blue: 0.1)],
                audioTrack: AudioTrack.library[0],
                textOverlay: "315 LBS BENCH DOUBLE 🔥",
                likesCount: 142,
                isLiked: false,
                comments: [
                    PostComment(author: "elena_runs", athleteType: .runner, text: "Insane bench numbers man! Clean form 🔥", timeAgo: "1h ago"),
                    PostComment(author: "coach_dave", athleteType: .functional, text: "Chest drive looking sharp. Keep recovering well.", timeAgo: "45m ago")
                ]
            ),
            // Community Post: Elena Rostova
            AthletePost(
                authorName: "Elena Rostova",
                authorHandle: "elena_runs",
                athleteType: .runner,
                timeAgo: "4h ago",
                workoutTag: "TEMPO RUN",
                workoutStats: "6.20 mi · 44:18 · 7'08\" /mi pace",
                caption: "Early 10K around the bay before sunrise. Crisp morning air and steady cadence throughout.",
                imageName: "figure.run",
                mediaType: .video,
                mediaItems: [
                    PostMediaItem(id: "er_vid", title: "Bay Sunrise 10K 4K Clip", iconName: "figure.run", gradientHexes: ["#081729", "#133152"], subtitle: "4K 60fps Video Clip", isVideo: true)
                ],
                mediaIconName: "figure.run",
                gradientColors: [Color(red: 0.05, green: 0.15, blue: 0.3), Color(red: 0.1, green: 0.3, blue: 0.5)],
                audioTrack: AudioTrack.library[10],
                textOverlay: "SUB-45 10K SUNSET ⚡",
                likesCount: 89,
                isLiked: true,
                comments: [
                    PostComment(author: "marcus_lifts", athleteType: .powerlifter, text: "That 7:08 pace is flying!", timeAgo: "3h ago")
                ]
            ),
            // Community Post: Kai Takahashi
            AthletePost(
                authorName: "Kai Takahashi",
                authorHandle: "kai_athletic",
                athleteType: .hybrid,
                timeAgo: "7h ago",
                workoutTag: "HYBRID ENGINE",
                workoutStats: "Heavy Deadlifts 405 + 4-Mile Aerobic Base",
                caption: "Dual-threat training day. Swipe right to see the deadlift unrack and zone-2 pace split. Macros hit at 210g protein.",
                imageName: "bolt.shield.fill",
                mediaType: .photo,
                mediaItems: [
                    PostMediaItem(id: "kt_1", title: "405 lbs Deadlift Pull", iconName: "bolt.shield.fill", gradientHexes: ["#1B240B", "#2F3D14"], subtitle: "Photo 1 of 2 · 3 Reps", isVideo: false),
                    PostMediaItem(id: "kt_2", title: "4-Mile Aerobic Route", iconName: "figure.run", gradientHexes: ["#0D2429", "#15424D"], subtitle: "Photo 2 of 2 · 142 BPM Zone 2", isVideo: false)
                ],
                mediaIconName: "bolt.shield.fill",
                gradientColors: [Color(red: 0.15, green: 0.2, blue: 0.05), Color(red: 0.25, green: 0.35, blue: 0.1)],
                audioTrack: AudioTrack.library[6],
                textOverlay: "HYBRID OVERLOAD",
                likesCount: 215,
                isLiked: false,
                comments: [
                    PostComment(author: "sarah_lifts", athleteType: .bodybuilder, text: "The definition of hybrid athletic output!", timeAgo: "5h ago")
                ]
            ),
            // Community Post: Maya Lin
            AthletePost(
                authorName: "Maya Lin",
                authorHandle: "maya_rings",
                athleteType: .calisthenics,
                timeAgo: "12h ago",
                workoutTag: "RINGS & BARS",
                workoutStats: "Straddle Planche + 5 Strict Muscle-Ups",
                caption: "Full bodyweight control routine. Clean lockout on every repetition in 4K.",
                imageName: "figure.gymnastics",
                mediaType: .video,
                mediaItems: [
                    PostMediaItem(id: "ml_vid", title: "Full Straddle Planche Reel", iconName: "figure.gymnastics", gradientHexes: ["#0B2418", "#14422D"], subtitle: "Full Video Reel", isVideo: true)
                ],
                mediaIconName: "figure.gymnastics",
                gradientColors: [Color(red: 0.05, green: 0.2, blue: 0.15), Color(red: 0.1, green: 0.35, blue: 0.25)],
                audioTrack: AudioTrack.library[8],
                textOverlay: "STRICT RINGS",
                likesCount: 167,
                isLiked: true,
                comments: [
                    PostComment(author: "kai_athletic", athleteType: .hybrid, text: "That planche hold was flawless.", timeAgo: "9h ago")
                ]
            )
        ]
    }
}
