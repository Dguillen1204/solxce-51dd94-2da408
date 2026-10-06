// Views/AthletePublicProfileView.swift
import SwiftUI

public struct AthletePublicProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var relationshipStore = SocialRelationshipStore.shared
    @ObservedObject private var postStore = FeedPostStore.shared
    @ObservedObject private var messagingStore = MessagingStore.shared

    let athleteHandle: String
    let fallbackName: String
    let fallbackType: AthleteType
    let currentUserHandle: String

    @State private var selectedTab: ProfileTab = .posts
    @State private var showingDirectMessage = false
    @State private var showingBlockAlert = false
    @State private var showingActionSheet = false
    @State private var activeReelPost: AthletePost? = nil
    @State private var toastMessage: String? = nil

    enum ProfileTab: String, CaseIterable {
        case posts = "Posts"
        case reels = "Reels"
        case stats = "Telemetry"
    }

    private var profile: AthleteProfileData {
        relationshipStore.getAthleteProfile(for: athleteHandle, fallbackName: fallbackName, fallbackType: fallbackType)
    }

    private var isFollowing: Bool {
        relationshipStore.isFollowing(handle: athleteHandle)
    }

    private var isBlocked: Bool {
        relationshipStore.isBlocked(handle: athleteHandle)
    }

    private var athletePosts: [AthletePost] {
        postStore.userPosts(handle: athleteHandle)
    }

    private var athleteReels: [AthletePost] {
        postStore.userReels(handle: athleteHandle)
    }

    public init(
        athleteHandle: String,
        fallbackName: String = "Athlete",
        fallbackType: AthleteType = .hybrid,
        currentUserHandle: String = "solxce_athlete"
    ) {
        self.athleteHandle = athleteHandle
        self.fallbackName = fallbackName
        self.fallbackType = fallbackType
        self.currentUserHandle = currentUserHandle
    }

    public var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                AppTheme.ground.ignoresSafeArea()

                if isBlocked {
                    blockedStateView
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: AppTheme.Spacing.md) {
                            // Header Banner & Profile Card
                            athleteHeaderCard

                            // Action Buttons (Follow / Unfollow / Message / Share)
                            actionButtonsRow

                            // High-performance stats telemetry strip
                            telemetryStrip

                            // Bio & Discipline Highlights
                            bioAndMetaSection

                            // Tabs: Posts / Reels / Telemetry
                            tabsPickerSection

                            // Tab Content
                            tabContentSection
                        }
                        .padding(.horizontal, AppTheme.Spacing.screenMargin)
                        .padding(.top, AppTheme.Spacing.sm)
                        .padding(.bottom, 60)
                    }
                }

                // Temporary Toast
                if let toast = toastMessage {
                    toastBanner(toast)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .padding(.bottom, 20)
                }
            }
            .navigationTitle("@\(profile.handle)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(AppTheme.text)
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingActionSheet = true
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                }
            }
            .confirmationDialog("Athlete Actions", isPresented: $showingActionSheet, titleVisibility: .visible) {
                if isBlocked {
                    Button("Unblock Athlete", role: .none) {
                        relationshipStore.unblock(handle: athleteHandle)
                        showToast("Unblocked @\(profile.handle)")
                    }
                } else {
                    Button(isFollowing ? "Unfollow" : "Follow") {
                        relationshipStore.toggleFollow(handle: athleteHandle)
                        showToast(isFollowing ? "Unfollowed @\(profile.handle)" : "Following @\(profile.handle)")
                    }
                    Button("Block @\(profile.handle)", role: .destructive) {
                        showingBlockAlert = true
                    }
                }
                Button("Report Profile", role: .destructive) {
                    showToast("Thank you. Report received for review.")
                }
                Button("Cancel", role: .cancel) {}
            }
            .alert("Block @\(profile.handle)?", isPresented: $showingBlockAlert) {
                Button("Block", role: .destructive) {
                    relationshipStore.block(handle: athleteHandle)
                    showToast("Blocked @\(profile.handle)")
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("They will not be able to view your profile, send you messages, or see your posts in their feed. Their posts will also be hidden from you.")
            }
            .sheet(isPresented: $showingDirectMessage) {
                DirectMessageChatView(
                    otherHandle: profile.handle,
                    otherName: profile.name,
                    athleteType: profile.athleteType,
                    currentUserHandle: currentUserHandle
                )
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

    // MARK: - Blocked State View
    private var blockedStateView: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            Image(systemName: "hand.raised.slash.fill")
                .font(.system(size: 48))
                .foregroundStyle(AppTheme.textSecondary)

            Text("Athlete Blocked")
                .font(AppTheme.titleFont)
                .foregroundStyle(AppTheme.text)

            Text("You blocked @\(profile.handle). You cannot see their posts or message each other.")
                .font(AppTheme.bodyFont)
                .foregroundStyle(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button {
                relationshipStore.unblock(handle: athleteHandle)
                showToast("Unblocked @\(profile.handle)")
            } label: {
                Text("Unblock Athlete")
                    .font(AppTheme.headlineFont)
                    .foregroundStyle(.black)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(AppTheme.primary)
                    .clipShape(Capsule())
            }
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Header Profile Card
    private var athleteHeaderCard: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            AthleteAvatarView(
                imageData: nil,
                symbolFallback: profile.athleteType.iconName,
                initials: profile.name,
                ringColor: profile.athleteType.badgeColor,
                size: 76,
                showCameraBadge: false,
                isPublic: true
            )

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(profile.name)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.text)

                    if profile.isVerified {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(AppTheme.primary)
                    }
                }

                HStack(spacing: 6) {
                    Image(systemName: profile.athleteType.iconName)
                        .font(.system(size: 11, weight: .bold))
                    Text(profile.athleteType.displayName)
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundStyle(profile.athleteType.badgeColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(profile.athleteType.badgeColor.opacity(0.14))
                .clipShape(Capsule())

                HStack(spacing: 4) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 10))
                    Text(profile.location)
                        .font(.system(size: 12))
                }
                .foregroundStyle(AppTheme.textSecondary)
            }

            Spacer()
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.elevated)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card, style: .continuous)
                .stroke(AppTheme.hairline, lineWidth: 1)
        )
    }

    // MARK: - Action Buttons
    private var actionButtonsRow: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            // Follow / Unfollow Button
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    relationshipStore.toggleFollow(handle: athleteHandle)
                }
                showToast(isFollowing ? "Following @\(profile.handle)" : "Unfollowed @\(profile.handle)")
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: isFollowing ? "checkmark" : "person.badge.plus.fill")
                        .font(.system(size: 14, weight: .bold))
                    Text(isFollowing ? "Following" : "Follow")
                        .font(AppTheme.headlineFont)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(isFollowing ? AppTheme.elevated : AppTheme.primary)
                .foregroundStyle(isFollowing ? AppTheme.text : .black)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.button, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.button, style: .continuous)
                        .stroke(isFollowing ? AppTheme.hairline : Color.clear, lineWidth: 1)
                )
            }

            // Message Button
            Button {
                showingDirectMessage = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                        .font(.system(size: 14, weight: .bold))
                    Text("Message")
                        .font(AppTheme.headlineFont)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(AppTheme.elevated)
                .foregroundStyle(AppTheme.text)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.button, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.button, style: .continuous)
                        .stroke(AppTheme.hairline, lineWidth: 1)
                )
            }
        }
    }

    // MARK: - Telemetry Strip
    private var telemetryStrip: some View {
        HStack(spacing: 0) {
            telemetryMetric(
                title: "Followers",
                value: "\(profile.followersCount)",
                icon: "person.2.fill",
                accent: AppTheme.text
            )

            Divider()
                .frame(height: 28)
                .background(AppTheme.hairline)

            telemetryMetric(
                title: "Weekly Run",
                value: String(format: "%.1f mi", profile.weeklyVolumeMiles),
                icon: "figure.run",
                accent: AppTheme.primary
            )

            Divider()
                .frame(height: 28)
                .background(AppTheme.hairline)

            telemetryMetric(
                title: "Tonnage",
                value: "\(Int(profile.weeklyVolumeLbs / 1000))k lbs",
                icon: "dumbbell.fill",
                accent: profile.athleteType.badgeColor
            )
        }
        .padding(.vertical, 12)
        .background(AppTheme.elevated)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card, style: .continuous)
                .stroke(AppTheme.hairline, lineWidth: 1)
        )
    }

    private func telemetryMetric(title: String, value: String, icon: String, accent: Color) -> some View {
        VStack(spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(accent)
                Text(value)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.text)
            }
            Text(title)
                .font(AppTheme.captionFont)
                .foregroundStyle(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Bio and Meta
    private var bioAndMetaSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(profile.bio)
                .font(AppTheme.bodyFont)
                .foregroundStyle(AppTheme.text)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 12) {
                Label("\(profile.totalWorkouts) Total Workouts", systemImage: "flame.fill")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(AppTheme.textSecondary)

                Label("\(profile.followingCount) Following", systemImage: "person.crop.circle.badge.checkmark")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(AppTheme.textSecondary)
            }
            .padding(.top, 2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.elevated)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card, style: .continuous))
    }

    // MARK: - Tabs Picker
    private var tabsPickerSection: some View {
        HStack(spacing: 8) {
            ForEach(ProfileTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = tab
                    }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: tab == .posts ? "square.grid.3x3.fill" : (tab == .reels ? "play.rectangle.fill" : "chart.line.uptrend.xyaxis"))
                            .font(.system(size: 12, weight: .bold))
                        Text(tab.rawValue)
                            .font(.system(size: 13, weight: .bold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(selectedTab == tab ? AppTheme.primary : AppTheme.elevated)
                    .foregroundStyle(selectedTab == tab ? .black : AppTheme.textSecondary)
                    .clipShape(Capsule())
                }
            }
        }
    }

    // MARK: - Tab Content Section
    @ViewBuilder
    private var tabContentSection: some View {
        switch selectedTab {
        case .posts:
            if athletePosts.isEmpty {
                emptyTabPlaceholder(title: "No Feed Posts Yet", message: "@\(profile.handle) hasn't posted workouts to the main feed yet.")
            } else {
                postsGridView
            }
        case .reels:
            if athleteReels.isEmpty {
                emptyTabPlaceholder(title: "No Video Reels", message: "Check back later for training reels and clip highlights.")
            } else {
                reelsGridView
            }
        case .stats:
            statsTelemetryView
        }
    }

    // MARK: - Grid of Posts
    private var postsGridView: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)], spacing: 8) {
            ForEach(athletePosts) { post in
                Button {
                    if post.mediaType == .video {
                        activeReelPost = post
                    }
                } label: {
                    ZStack(alignment: .bottomLeading) {
                        LinearGradient(colors: post.gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing)
                            .aspectRatio(1, contentMode: .fill)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                        VStack(alignment: .leading, spacing: 2) {
                            Image(systemName: post.mediaIconName)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(.white)
                            Text(post.workoutTag)
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.white)
                                .lineLimit(1)
                        }
                        .padding(8)
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Reels Grid
    private var reelsGridView: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)], spacing: 8) {
            ForEach(athleteReels) { reel in
                Button {
                    activeReelPost = reel
                } label: {
                    ZStack(alignment: .bottomLeading) {
                        LinearGradient(colors: reel.gradientColors, startPoint: .top, endPoint: .bottom)
                            .aspectRatio(9/16, contentMode: .fit)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(.white.opacity(0.85))
                            .frame(maxWidth: .infinity, maxHeight: .infinity)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(reel.workoutTag)
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(.white)
                            Text("\(reel.likesCount) likes")
                                .font(.system(size: 9))
                                .foregroundStyle(.white.opacity(0.8))
                        }
                        .padding(8)
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Stats Telemetry
    private var statsTelemetryView: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            statMetricRow(title: "Discipline", value: profile.athleteType.displayName, icon: profile.athleteType.iconName)
            statMetricRow(title: "Weekly Distance", value: String(format: "%.1f Miles", profile.weeklyVolumeMiles), icon: "figure.run")
            statMetricRow(title: "Weekly Tonnage", value: "\(Int(profile.weeklyVolumeLbs)) lbs", icon: "dumbbell.fill")
            statMetricRow(title: "Lifetime Sessions", value: "\(profile.totalWorkouts) Logs", icon: "calendar.badge.clock")
        }
    }

    private func statMetricRow(title: String, value: String, icon: String) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppTheme.primary)
                .frame(width: 24)

            Text(title)
                .font(AppTheme.subheadlineFont)
                .foregroundStyle(AppTheme.textSecondary)

            Spacer()

            Text(value)
                .font(AppTheme.headlineFont)
                .foregroundStyle(AppTheme.text)
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.elevated)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card, style: .continuous))
    }

    private func emptyTabPlaceholder(title: String, message: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: "tray.fill")
                .font(.system(size: 32))
                .foregroundStyle(AppTheme.textSecondary.opacity(0.6))
            Text(title)
                .font(AppTheme.headlineFont)
                .foregroundStyle(AppTheme.text)
            Text(message)
                .font(AppTheme.captionFont)
                .foregroundStyle(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private func showToast(_ text: String) {
        withAnimation {
            toastMessage = text
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            withAnimation {
                if toastMessage == text {
                    toastMessage = nil
                }
            }
        }
    }

    private func toastBanner(_ text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(AppTheme.primary)
            Text(text)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.black.opacity(0.85))
        .clipShape(Capsule())
        .overlay(Capsule().stroke(AppTheme.primary.opacity(0.4), lineWidth: 1))
        .shadow(radius: 10)
    }
}
