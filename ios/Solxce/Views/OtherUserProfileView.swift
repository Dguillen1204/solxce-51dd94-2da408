// Views/OtherUserProfileView.swift
import SwiftUI

struct OtherUserProfileView: View {
    @Environment(\.dismiss) private var dismiss
    let handle: String
    let initialName: String?
    let initialAthleteType: AthleteType?

    @ObservedObject private var relationshipStore = SocialRelationshipStore.shared
    @ObservedObject private var postStore = FeedPostStore.shared

    @State private var selectedTab: ProfileMediaTab = .posts
    @State private var showBlockConfirmation: Bool = false
    @State private var showUnblockConfirmation: Bool = false
    @State private var showActionMenu: Bool = false
    @State private var showDirectMessageView: Bool = false
    @State private var showPrivacyNoticeAlert: Bool = false
    @State private var privacyNoticeMessage: String = ""
    @State private var selectedPostDetailID: UUID? = nil
    @State private var activeReelPost: AthletePost? = nil

    enum ProfileMediaTab: String, CaseIterable {
        case posts = "Posts"
        case reels = "Reels"
        case stats = "PRs & Stats"
    }

    public init(handle: String, initialName: String? = nil, initialAthleteType: AthleteType? = nil) {
        self.handle = handle
        self.initialName = initialName
        self.initialAthleteType = initialAthleteType
    }

    private var profile: OtherAthleteProfile {
        relationshipStore.getProfile(for: handle, fallbackName: initialName, fallbackType: initialAthleteType)
    }

    private var authorPosts: [AthletePost] {
        postStore.userPosts(handle: handle)
    }

    private var authorReels: [AthletePost] {
        postStore.userReels(handle: handle)
    }

    private var postGridItems: [FeedGridItem] {
        authorPosts.map { post in
            let badge: FeedGridBadge = post.mediaType == .video ? .reel : (post.mediaItems.count > 1 ? .carousel : .none)
            return FeedGridItem(
                postID: post.id,
                seed: post.workoutTag,
                badge: badge,
                viewCount: post.mediaType == .video ? (post.likesCount * 14 + 120) : nil,
                accessibilityLabel: post.caption,
                iconName: post.mediaIconName,
                gradientColors: post.gradientColors,
                textOverlay: post.textOverlay
            )
        }
    }

    private var reelGridItems: [FeedGridItem] {
        authorReels.map { post in
            FeedGridItem(
                postID: post.id,
                seed: post.workoutTag,
                badge: .reel,
                viewCount: post.likesCount * 14 + 120,
                accessibilityLabel: post.caption,
                iconName: post.mediaIconName,
                gradientColors: post.gradientColors,
                textOverlay: post.textOverlay
            )
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if profile.isBlocked {
                        blockedStateBanner
                    } else {
                        // Profile Header with Avatar, Name, Handle, and Badges
                        headerSection

                        // Quick Stats Row (Followers, Following, Workouts)
                        socialStatsRow

                        // Bio & Athlete Archetype Badge
                        bioSection

                        // Main Action Buttons (Follow / Unfollow, Direct Message, More Options)
                        actionButtonsRow

                        // Key Athlete PRs & Highlights Card
                        athleteHighlightsCard

                        // Media Section (Posts Grid, Reels Grid, Detailed Stats)
                        profileContentSection
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 36)
            }
            .background(AppTheme.ground.ignoresSafeArea())
            .navigationTitle("@\(profile.handle)")
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
                        showActionMenu = true
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                    }
                }
            }
            .confirmationDialog("Options for @\(profile.handle)", isPresented: $showActionMenu, titleVisibility: .visible) {
                actionMenuButtons
            }
            .alert("Block @\(profile.handle)?", isPresented: $showBlockConfirmation) {
                blockAlertButtons
            } message: {
                Text("They won't be able to message you, view your profile, or find your posts on Solxce. They won't be notified that you blocked them.")
            }
            .alert("Unblock @\(profile.handle)?", isPresented: $showUnblockConfirmation) {
                unblockAlertButtons
            } message: {
                Text("They will be able to see your public workouts and send you messages based on your privacy rules.")
            }
            .alert("Privacy & Moderation", isPresented: $showPrivacyNoticeAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(privacyNoticeMessage)
            }
            .sheet(isPresented: $showDirectMessageView) {
                ConversationChatView(profile: profile)
            }
            .sheet(isPresented: Binding(
                get: { selectedPostDetailID != nil },
                set: { if !$0 { selectedPostDetailID = nil } }
            )) {
                if let postID = selectedPostDetailID {
                    PostDetailModalSheet(
                        postID: postID,
                        onOpenReel: { reelPost in
                            selectedPostDetailID = nil
                            activeReelPost = reelPost
                        }
                    )
                }
            }
            .fullScreenCover(item: $activeReelPost) { reelPost in
                if let index = postStore.posts.firstIndex(where: { $0.id == reelPost.id }) {
                    TikTokReelPlayerModal(
                        post: $postStore.posts[index],
                        onAddComment: { newComment in
                            postStore.posts[index].comments.append(newComment)
                        }
                    )
                }
            }
        }
    }

    @ViewBuilder
    private var actionMenuButtons: some View {
        if profile.isBlocked {
            Button("Unblock Athlete", role: .none) {
                showUnblockConfirmation = true
            }
        } else {
            Button(profile.isFollowing ? "Unfollow @\(profile.handle)" : "Follow @\(profile.handle)") {
                relationshipStore.toggleFollow(for: profile.handle)
            }

            Button("Block Athlete", role: .destructive) {
                showBlockConfirmation = true
            }
        }

        Button("Report Account", role: .destructive) {
            privacyNoticeMessage = "Report submitted. Our community moderation team will review this profile within 24 hours."
            showPrivacyNoticeAlert = true
        }

        Button("Cancel", role: .cancel) {}
    }

    @ViewBuilder
    private var blockAlertButtons: some View {
        Button("Block", role: .destructive) {
            relationshipStore.blockUser(handle: profile.handle)
        }
        Button("Cancel", role: .cancel) {}
    }

    @ViewBuilder
    private var unblockAlertButtons: some View {
        Button("Unblock") {
            relationshipStore.unblockUser(handle: profile.handle)
        }
        Button("Cancel", role: .cancel) {}
    }

    // MARK: - Blocked State View
    private var blockedStateBanner: some View {
        VStack(spacing: 20) {
            Image(systemName: "hand.raised.slash.fill")
                .font(.system(size: 54))
                .foregroundColor(.red)
                .padding(.top, 40)

            Text("You Have Blocked @\(profile.handle)")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)

            Text("You cannot see their posts, workout logs, or send messages while they are blocked.")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            Button {
                relationshipStore.unblockUser(handle: profile.handle)
            } label: {
                Text("Unblock Athlete")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.black)
                    .frame(maxWidth: 240)
                    .padding(.vertical, 12)
                    .background(AppTheme.primary)
                    .clipShape(Capsule())
            }
            .padding(.top, 12)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    // MARK: - Header Section
    private var headerSection: some View {
        HStack(spacing: 16) {
            // Profile Avatar
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [profile.athleteType.badgeColor.opacity(0.4), Color.black],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 86, height: 86)
                    .overlay(
                        Circle().stroke(profile.athleteType.badgeColor, lineWidth: 2.5)
                    )

                Image(systemName: profile.avatarSymbol)
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundColor(profile.athleteType.badgeColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(profile.name)
                        .font(.system(size: 20, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)

                    if profile.isVerifiedAthlete {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 15))
                            .foregroundColor(AppTheme.primary)
                    }
                }

                Text("@\(profile.handle)")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppTheme.primary)

                HStack(spacing: 6) {
                    Image(systemName: profile.athleteType.iconName)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(profile.athleteType.badgeColor)

                    Text(profile.athleteType.displayName.uppercased())
                        .font(.system(size: 10, weight: .black, design: .rounded))
                        .foregroundColor(profile.athleteType.badgeColor)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(profile.athleteType.badgeColor.opacity(0.15))
                .clipShape(Capsule())
                .padding(.top, 2)
            }

            Spacer()
        }
    }

    // MARK: - Social Stats Row
    private var socialStatsRow: some View {
        HStack(spacing: 0) {
            statItem(title: "Workouts", value: "\(profile.totalWorkoutsCount)")
            Divider().background(Color.white.opacity(0.12)).frame(height: 32)
            statItem(title: "Followers", value: "\(profile.followersCount)")
            Divider().background(Color.white.opacity(0.12)).frame(height: 32)
            statItem(title: "Following", value: "\(profile.followingCount)")
        }
        .padding(.vertical, 14)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    private func statItem(title: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 18, weight: .heavy, design: .rounded))
                .foregroundColor(.white)
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Bio Section
    private var bioSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(profile.bio)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.white.opacity(0.9))
                .lineSpacing(3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Action Buttons (Follow / Unfollow & Message)
    private var actionButtonsRow: some View {
        HStack(spacing: 10) {
            // Follow / Unfollow Button
            Button {
                relationshipStore.toggleFollow(for: profile.handle)
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: profile.isFollowing ? "person.badge.minus.fill" : "person.badge.plus.fill")
                        .font(.system(size: 14, weight: .bold))

                    Text(profile.isFollowing ? "Following" : "Follow")
                        .font(.system(size: 14, weight: .bold))
                }
                .foregroundColor(profile.isFollowing ? .white : .black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 11)
                .background(profile.isFollowing ? Color.white.opacity(0.12) : AppTheme.primary)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(profile.isFollowing ? Color.white.opacity(0.2) : Color.clear, lineWidth: 1)
                )
            }

            // Message Button
            Button {
                let check = relationshipStore.canMessage(handle: profile.handle)
                if check.allowed {
                    showDirectMessageView = true
                } else {
                    privacyNoticeMessage = check.reason ?? "Cannot send message."
                    showPrivacyNoticeAlert = true
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                        .font(.system(size: 14, weight: .bold))
                    Text("Message")
                        .font(.system(size: 14, weight: .bold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 11)
                .background(Color.white.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
            }
        }
    }

    // MARK: - Athlete Highlights Card
    private var athleteHighlightsCard: some View {
        HStack(spacing: 12) {
            // Lifetime Volume
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 5) {
                    Image(systemName: "dumbbell.fill")
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.primary)
                    Text("LIFETIME VOLUME")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white.opacity(0.6))
                }
                Text(profile.totalVolumeFormatted)
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(Color.white.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            // Best 5K Pace
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 5) {
                    Image(systemName: "figure.run")
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "#00E5FF"))
                    Text("BEST 5K PACE")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white.opacity(0.6))
                }
                Text(profile.best5kPace)
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(Color.white.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - Profile Content & Grids
    private var profileContentSection: some View {
        VStack(spacing: 16) {
            // Tab Selector
            HStack(spacing: 0) {
                ForEach(ProfileMediaTab.allCases, id: \.self) { tab in
                    Button {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                            selectedTab = tab
                        }
                    } label: {
                        VStack(spacing: 6) {
                            Text(tab.rawValue)
                                .font(.system(size: 13, weight: selectedTab == tab ? .heavy : .semibold))
                                .foregroundColor(selectedTab == tab ? AppTheme.primary : .white.opacity(0.5))

                            Rectangle()
                                .fill(selectedTab == tab ? AppTheme.primary : Color.clear)
                                .frame(height: 2)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.top, 8)

            // Content per tab
            switch selectedTab {
            case .posts:
                if authorPosts.isEmpty {
                    emptyMediaState(icon: "photo.stack", text: "No posts shared yet.")
                } else {
                    FeedProfileGrid(
                        items: postGridItems,
                        onSelect: { item in
                            selectedPostDetailID = item.postID
                        }
                    )
                }

            case .reels:
                if authorReels.isEmpty {
                    emptyMediaState(icon: "video.badge.plus", text: "No video reels shared yet.")
                } else {
                    FeedProfileGrid(
                        items: reelGridItems,
                        onSelect: { item in
                            if let found = authorReels.first(where: { $0.id == item.postID }) {
                                activeReelPost = found
                            }
                        }
                    )
                }

            case .stats:
                athleteDetailedStatsCard
            }
        }
    }

    private func emptyMediaState(icon: String, text: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundColor(.white.opacity(0.3))
            Text(text)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private var athleteDetailedStatsCard: some View {
        VStack(spacing: 12) {
            HStack {
                Text("ATHLETIC BENCHMARKS")
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .foregroundColor(AppTheme.primary)
                Spacer()
                Text("VERIFIED LOGS")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.white.opacity(0.5))
            }

            VStack(spacing: 8) {
                benchmarkRow(name: "Total Sessions Logged", value: "\(profile.totalWorkoutsCount) workouts", icon: "flame.fill")
                benchmarkRow(name: "Total Tonnage Lifted", value: profile.totalVolumeFormatted, icon: "scalemass.fill")
                benchmarkRow(name: "Peak Pace Standard", value: profile.best5kPace, icon: "timer")
                benchmarkRow(name: "Athlete Archetype", value: profile.athleteType.displayName, icon: profile.athleteType.iconName)
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func benchmarkRow(name: String, value: String, icon: String) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundColor(AppTheme.primary)
                .frame(width: 20)

            Text(name)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white.opacity(0.8))

            Spacer()

            Text(value)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.white)
        }
        .padding(.vertical, 4)
    }
}
