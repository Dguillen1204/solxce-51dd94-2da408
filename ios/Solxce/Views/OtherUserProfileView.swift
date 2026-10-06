// Views/OtherUserProfileView.swift
import SwiftUI
import SwiftData

struct OtherUserProfileView: View {
    let athleteHandle: String
    @Environment(\.dismiss) private var dismiss

    @ObservedObject private var socialManager = SocialPrivacyManager.shared
    @ObservedObject private var postStore = FeedPostStore.shared

    @State private var selectedTab: ProfileTab = .posts
    @State private var showingMessageSheet = false
    @State private var showingBlockAlert = false
    @State private var showingReportAlert = false
    @State private var selectedPostDetailID: UUID? = nil
    @State private var activeReelPost: AthletePost? = nil

    enum ProfileTab: String, CaseIterable {
        case posts = "Posts"
        case reels = "Reels"
        case stats = "Stats"
    }

    private var athlete: CommunityAthlete {
        if let found = socialManager.communityAthletes[athleteHandle.lowercased()] {
            return found
        }
        return CommunityAthlete(
            name: athleteHandle.replacingOccurrences(of: "_", with: " ").capitalized,
            handle: athleteHandle,
            athleteType: .hybrid,
            bio: "Solxce Athlete dedicated to daily progression.",
            location: "Solxce Global",
            totalVolumeFormatted: "140K lbs",
            totalMilesFormatted: "320 mi",
            avatarSymbol: "figure.cross-training",
            isVerifiedAthlete: false,
            followersCount: 154,
            followingCount: 92
        )
    }

    private var isFollowing: Bool {
        socialManager.isFollowing(handle: athlete.handle)
    }

    private var isBlocked: Bool {
        socialManager.isBlocked(handle: athlete.handle)
    }

    private var athletePosts: [AthletePost] {
        postStore.userPosts(handle: athlete.handle)
    }

    private var athleteReels: [AthletePost] {
        postStore.userReels(handle: athlete.handle)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.md) {
                    if isBlocked {
                        blockedStateBanner
                    } else {
                        // Profile Header Card
                        profileCard

                        // Action Buttons: Follow/Unfollow, Message, More Menu
                        actionButtonsRow

                        // Stat Highlights (Volume, Miles, Archetype)
                        athleteHighlightsRow

                        // Content Tab Bar (Posts, Reels, Stats)
                        contentTabBar

                        // Tab Content
                        tabContentView
                    }
                }
                .padding(.horizontal, AppTheme.Spacing.screenMargin)
                .padding(.top, AppTheme.Spacing.sm)
                .padding(.bottom, AppTheme.Spacing.xxl)
            }
            .background(AppTheme.ground.ignoresSafeArea())
            .navigationTitle("@\(athlete.handle)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        if isBlocked {
                            Button {
                                socialManager.unblockUser(handle: athlete.handle)
                            } label: {
                                Label("Unblock Athlete", systemImage: "hand.raised.slash")
                            }
                        } else {
                            Button(role: .destructive) {
                                showingBlockAlert = true
                            } label: {
                                Label("Block @\(athlete.handle)", systemImage: "hand.raised.fill")
                            }

                            Button {
                                showingReportAlert = true
                            } label: {
                                Label("Report Profile", systemImage: "flag")
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(AppTheme.textSecondary)
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                }
            }
            .alert("Block @\(athlete.handle)?", isPresented: $showingBlockAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Block", role: .destructive) {
                    withAnimation {
                        socialManager.blockUser(handle: athlete.handle)
                    }
                }
            } message: {
                Text("They won't be able to message you, view your posts, or find your profile on Solxce. You will automatically unfollow each other.")
            }
            .alert("Report Submitted", isPresented: $showingReportAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Thank you for keeping Solxce safe. Our community integrity team will review this profile within 24 hours.")
            }
            .sheet(isPresented: $showingMessageSheet) {
                let conv = socialManager.getOrCreateConversation(with: athlete)
                NavigationStack {
                    ChatConversationView(conversation: conv)
                }
            }
            .sheet(item: Binding(
                get: {
                    if let id = selectedPostDetailID, let post = postStore.posts.first(where: { $0.id == id }) {
                        return post
                    }
                    return nil
                },
                set: { selectedPostDetailID = $0?.id }
            )) { post in
                PostDetailModalSheet(post: post)
            }
            .fullScreenCover(item: $activeReelPost) { reel in
                TikTokReelPlayerModal(
                    post: reel,
                    onDismiss: { activeReelPost = nil }
                )
            }
        }
    }

    // MARK: - Blocked State Banner
    private var blockedStateBanner: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            Image(systemName: "hand.raised.fill")
                .font(.system(size: 48))
                .foregroundStyle(Color(hex: "#FF3B5C"))
                .padding(.top, 40)

            Text("You've Blocked @\(athlete.handle)")
                .font(AppTheme.titleFont)
                .foregroundStyle(AppTheme.primary)

            Text("You cannot see their posts, reels, or message history while they are blocked.")
                .font(AppTheme.bodyFont)
                .foregroundStyle(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            Button {
                withAnimation {
                    socialManager.unblockUser(handle: athlete.handle)
                }
            } label: {
                Text("Unblock Athlete")
                    .font(AppTheme.headlineFont)
                    .foregroundStyle(AppTheme.inverseText)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(AppTheme.primary)
                    .clipShape(Capsule())
            }
            .padding(.top, 16)
        }
        .padding(AppTheme.Spacing.lg)
    }

    // MARK: - Profile Card
    private var profileCard: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            HStack(spacing: AppTheme.Spacing.md) {
                // Avatar Circle with Archetype Ring
                ZStack {
                    Circle()
                        .stroke(athlete.athleteType.badgeColor, lineWidth: 2.5)
                        .frame(width: 76, height: 76)

                    Circle()
                        .fill(AppTheme.surfaceElevated)
                        .frame(width: 68, height: 68)

                    Image(systemName: athlete.avatarSymbol)
                        .font(.system(size: 30))
                        .foregroundStyle(athlete.athleteType.badgeColor)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(athlete.name)
                            .font(AppTheme.titleFont)
                            .foregroundStyle(AppTheme.primary)

                        if athlete.isVerifiedAthlete {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 15))
                                .foregroundStyle(AppTheme.accent)
                        }
                    }

                    Text("@\(athlete.handle)")
                        .font(AppTheme.captionFont)
                        .foregroundStyle(AppTheme.textSecondary)

                    // Archetype badge pill
                    HStack(spacing: 4) {
                        Image(systemName: athlete.athleteType.iconName)
                            .font(.system(size: 10, weight: .bold))
                        Text(athlete.athleteType.shortTag)
                            .font(.system(size: 10, weight: .heavy))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(athlete.athleteType.badgeColor.opacity(0.18))
                    .foregroundStyle(athlete.athleteType.badgeColor)
                    .clipShape(Capsule())
                }

                Spacer()
            }

            // Bio Text
            if !athlete.bio.isEmpty {
                Text(athlete.bio)
                    .font(AppTheme.bodyFont)
                    .foregroundStyle(AppTheme.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 2)
            }

            // Location & Join info
            HStack(spacing: 12) {
                Label(athlete.location, systemImage: "mappin.and.ellipse")
                    .font(AppTheme.captionFont)
                    .foregroundStyle(AppTheme.textSecondary)

                Spacer()
            }

            // Social Counters (Followers, Following, Posts)
            Divider().overlay(Color.white.opacity(0.1))

            HStack(spacing: 0) {
                counterItem(title: "Posts", count: "\(max(athletePosts.count, 4))")
                Spacer()
                counterItem(title: "Followers", count: "\(athlete.followersCount)")
                Spacer()
                counterItem(title: "Following", count: "\(athlete.followingCount)")
            }
        }
        .padding(AppTheme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card)
                .fill(AppTheme.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }

    private func counterItem(title: String, count: String) -> some View {
        VStack(spacing: 2) {
            Text(count)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.primary)
            Text(title)
                .font(AppTheme.captionFont)
                .foregroundStyle(AppTheme.textSecondary)
        }
        .frame(minWidth: 70)
    }

    // MARK: - Action Buttons (Follow / Unfollow & Message)
    private var actionButtonsRow: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            // Follow / Following Button
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    socialManager.toggleFollow(handle: athlete.handle)
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: isFollowing ? "checkmark" : "plus")
                        .font(.system(size: 13, weight: .bold))
                    Text(isFollowing ? "Following" : "Follow")
                        .font(AppTheme.headlineFont)
                }
                .foregroundStyle(isFollowing ? AppTheme.primary : AppTheme.inverseText)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(
                    isFollowing
                        ? AppTheme.surfaceElevated
                        : AppTheme.primary
                )
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(isFollowing ? Color.white.opacity(0.15) : Color.clear, lineWidth: 1)
                )
            }

            // Direct Message Button
            Button {
                showingMessageSheet = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                        .font(.system(size: 13, weight: .bold))
                    Text("Message")
                        .font(AppTheme.headlineFont)
                }
                .foregroundStyle(AppTheme.primary)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(AppTheme.surfaceElevated)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
            }
        }
    }

    // MARK: - Athlete Highlights
    private var athleteHighlightsRow: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            highlightCard(
                icon: "dumbbell.fill",
                title: "Career Volume",
                value: athlete.totalVolumeFormatted,
                tint: Color(hex: "#FF3B5C")
            )

            highlightCard(
                icon: "figure.run",
                title: "Logged Miles",
                value: athlete.totalMilesFormatted,
                tint: Color(hex: "#38BDF8")
            )
        }
    }

    private func highlightCard(icon: String, title: String, value: String, tint: Color) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(tint)
                .frame(width: 36, height: 36)
                .background(tint.opacity(0.15))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppTheme.captionFont)
                    .foregroundStyle(AppTheme.textSecondary)
                Text(value)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.primary)
            }
            Spacer()
        }
        .padding(AppTheme.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card)
                .fill(AppTheme.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
        )
    }

    // MARK: - Tab Bar
    private var contentTabBar: some View {
        HStack(spacing: 0) {
            ForEach(ProfileTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = tab
                    }
                } label: {
                    VStack(spacing: 8) {
                        HStack(spacing: 4) {
                            Image(systemName: tabIcon(tab))
                                .font(.system(size: 13, weight: .semibold))
                            Text(tab.rawValue)
                                .font(AppTheme.headlineFont)
                        }
                        .foregroundStyle(selectedTab == tab ? AppTheme.accent : AppTheme.textSecondary)

                        Rectangle()
                            .fill(selectedTab == tab ? AppTheme.accent : Color.clear)
                            .frame(height: 2.5)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.top, 4)
    }

    private func tabIcon(_ tab: ProfileTab) -> String {
        switch tab {
        case .posts: return "square.grid.3x3.fill"
        case .reels: return "play.square.stack.fill"
        case .stats: return "chart.bar.xaxis"
        }
    }

    // MARK: - Tab Content
    @ViewBuilder
    private var tabContentView: some View {
        switch selectedTab {
        case .posts:
            if athletePosts.isEmpty {
                emptyTabState(
                    icon: "camera.fill",
                    title: "No Posts Yet",
                    subtitle: "@\(athlete.handle) hasn't posted any workout updates yet."
                )
            } else {
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 6),
                    GridItem(.flexible(), spacing: 6),
                    GridItem(.flexible(), spacing: 6)
                ], spacing: 6) {
                    ForEach(athletePosts) { post in
                        Button {
                            if post.mediaType == .video {
                                activeReelPost = post
                            } else {
                                selectedPostDetailID = post.id
                            }
                        } label: {
                            ZStack(alignment: .bottomLeading) {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(
                                        LinearGradient(
                                            colors: post.gradientColors,
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .aspectRatio(1, contentMode: .fit)

                                Image(systemName: post.mediaIconName)
                                    .font(.system(size: 26))
                                    .foregroundStyle(Color.white.opacity(0.7))
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                                if post.mediaType == .video {
                                    Image(systemName: "play.fill")
                                        .font(.system(size: 11))
                                        .foregroundStyle(Color.white)
                                        .padding(5)
                                        .background(Color.black.opacity(0.6))
                                        .clipShape(Circle())
                                        .padding(6)
                                } else if post.mediaItems.count > 1 {
                                    Image(systemName: "square.fill.on.square.fill")
                                        .font(.system(size: 11))
                                        .foregroundStyle(Color.white)
                                        .padding(6)
                                }
                            }
                        }
                    }
                }
            }

        case .reels:
            if athleteReels.isEmpty {
                emptyTabState(
                    icon: "play.tv.fill",
                    title: "No Video Reels",
                    subtitle: "@\(athlete.handle) hasn't uploaded 4K training reels yet."
                )
            } else {
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 6),
                    GridItem(.flexible(), spacing: 6),
                    GridItem(.flexible(), spacing: 6)
                ], spacing: 6) {
                    ForEach(athleteReels) { reel in
                        Button {
                            activeReelPost = reel
                        } label: {
                            ZStack(alignment: .bottomLeading) {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(
                                        LinearGradient(
                                            colors: reel.gradientColors,
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .aspectRatio(0.65, contentMode: .fit)

                                Image(systemName: reel.mediaIconName)
                                    .font(.system(size: 30))
                                    .foregroundStyle(Color.white.opacity(0.7))
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                                HStack(spacing: 3) {
                                    Image(systemName: "play.fill")
                                        .font(.system(size: 9))
                                    Text("\(reel.likesCount * 14 + 120)")
                                        .font(.system(size: 10, weight: .bold))
                                }
                                .foregroundStyle(Color.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(Color.black.opacity(0.6))
                                .clipShape(Capsule())
                                .padding(6)
                            }
                        }
                    }
                }
            }

        case .stats:
            VStack(spacing: AppTheme.Spacing.md) {
                statRow(title: "Primary Archetype", value: athlete.athleteType.rawValue, icon: athlete.athleteType.iconName, tint: athlete.athleteType.badgeColor)
                statRow(title: "Weekly Consistency", value: "94% Standard Hit", icon: "flame.fill", tint: Color(hex: "#F97316"))
                statRow(title: "Avg Workout Volume", value: "18,400 lbs / session", icon: "scalemass.fill", tint: Color(hex: "#A855F7"))
                statRow(title: "Longest Run", value: "13.1 mi (Half Marathon)", icon: "figure.run", tint: Color(hex: "#38BDF8"))
            }
        }
    }

    private func statRow(title: String, value: String, icon: String, tint: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(tint)
                .frame(width: 32, height: 32)
                .background(tint.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            Text(title)
                .font(AppTheme.bodyFont)
                .foregroundStyle(AppTheme.primary)

            Spacer()

            Text(value)
                .font(AppTheme.headlineFont)
                .foregroundStyle(AppTheme.textSecondary)
        }
        .padding(AppTheme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card)
                .fill(AppTheme.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
        )
    }

    private func emptyTabState(icon: String, title: String, subtitle: String) -> some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 34))
                .foregroundStyle(AppTheme.textSecondary.opacity(0.6))
                .padding(.top, 24)
            Text(title)
                .font(AppTheme.titleFont)
                .foregroundStyle(AppTheme.primary)
            Text(subtitle)
                .font(AppTheme.captionFont)
                .foregroundStyle(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity)
        .padding(AppTheme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card)
                .fill(AppTheme.surface)
        )
    }
}
