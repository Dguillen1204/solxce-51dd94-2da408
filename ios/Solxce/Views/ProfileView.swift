// Views/ProfileView.swift
import SwiftUI
import SwiftData

struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var userProfiles: [UserProfile]
    @Query private var workoutSessions: [WorkoutSession]
    @Query private var runEntries: [RunEntry]
    @Query private var macroTargets: [MacroTarget]
    @ObservedObject private var subManager = SubscriptionManager.shared
    @ObservedObject private var watchManager = AppleWatchSyncManager.shared
    @ObservedObject private var postStore = FeedPostStore.shared
    @AppStorage("solxce_app_appearance") private var appAppearanceRaw: String = AppAppearance.system.rawValue

    @State private var showingEditGoals = false
    @State private var showingPaywall = false
    @State private var showingProgressReport = false
    @State private var showingFastingTracker = false
    @State private var showingEditAthleteType = false
    @State private var showingEditPhotoSheet = false
    @State private var showingWatchHub = false
    @State private var showingSettings = false

    // Profile Post Grid navigation state
    enum ProfileMediaTab: String, CaseIterable {
        case posts = "Posts"
        case reels = "Reels"
        case stats = "Analytics"
    }

    @State private var selectedMediaTab: ProfileMediaTab = .posts
    @State private var selectedPostDetailID: UUID? = nil
    @State private var activeReelPost: AthletePost? = nil
    @State private var showingNewPostSheet = false

    var currentProfile: UserProfile {
        if let existing = userProfiles.first {
            return existing
        }
        let fallback = UserProfile(
            fullName: "Alex Rivera",
            handle: "alex_solxce",
            athleteType: .hybrid,
            bio: "Hybrid athlete chasing heavy lifts and fast miles."
        )
        return fallback
    }

    var totalVolumeLbs: Double {
        workoutSessions.reduce(0) { $0 + $1.totalVolumeLbs }
    }

    var totalRunMiles: Double {
        runEntries.reduce(0) { $0 + $1.distanceMiles }
    }

    var totalSetsCompleted: Int {
        workoutSessions.reduce(0) { $0 + $1.totalSets }
    }

    var target: MacroTarget? {
        macroTargets.first
    }

    private var myPosts: [AthletePost] {
        postStore.userPosts(handle: currentProfile.handle)
    }

    private var myReels: [AthletePost] {
        postStore.userReels(handle: currentProfile.handle)
    }

    private var postGridItems: [FeedGridItem] {
        myPosts.map { post in
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
        myReels.map { post in
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
                VStack(spacing: AppTheme.Spacing.md) {
                    // Profile Header & Avatar
                    profileHeader

                    // Instagram-style Stat Counters (Posts, Followers, Volume)
                    profileSocialCountersRow

                    // Athlete Archetype Pass Card
                    athleteArchetypeCard

                    // Apple Watch Companion Pass Card
                    appleWatchProfileCard

                    // Instagram-Style Profile Content Tab Bar
                    profileMediaSection

                    if selectedMediaTab == .stats {
                        // Solxce Pro Membership Card
                        proMembershipCard

                        // In-Depth Analytics Shortcut
                        inDepthReportShortcut

                        // Aggregate Lifetime Stats
                        lifetimeStatsCard

                        // Nutrition Goals Config Card
                        nutritionGoalsCard

                        // Training Distribution
                        trainingHistoryCard

                        // App Appearance / Theme Mode Card
                        appearanceCard
                    }
                }
                .padding(.horizontal, AppTheme.Spacing.screenMargin)
                .padding(.top, AppTheme.Spacing.sm)
                .padding(.bottom, AppTheme.Spacing.xxl)
            }
            .background(AppTheme.ground.ignoresSafeArea())
            .navigationTitle("Athlete Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 12) {
                        Button {
                            showingNewPostSheet = true
                        } label: {
                            Image(systemName: "plus.square.fill")
                                .font(.system(size: 18))
                                .foregroundStyle(AppTheme.primary)
                        }

                        Button {
                            showingSettings = true
                        } label: {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 17))
                                .foregroundStyle(AppTheme.text)
                        }
                    }
                }
            }
            .sheet(isPresented: $showingEditGoals) {
                if let currentTarget = target {
                    EditMacroGoalsSheet(target: currentTarget)
                }
            }
            .sheet(isPresented: $showingPaywall) {
                PaywallView()
            }
            .sheet(isPresented: $showingProgressReport) {
                ProgressReportView()
            }
            .sheet(isPresented: $showingFastingTracker) {
                FastingTrackerView()
            }
            .sheet(isPresented: $showingEditAthleteType) {
                EditAthleteTypeSheet(profile: currentProfile)
            }
            .sheet(isPresented: $showingEditPhotoSheet) {
                ProfilePhotoPickerSheet(profile: currentProfile)
            }
            .sheet(isPresented: $showingWatchHub) {
                AppleWatchHubView()
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showingNewPostSheet) {
                CreateMediaPostSheet(
                    authorName: currentProfile.fullName,
                    authorHandle: currentProfile.handle,
                    athleteType: currentProfile.athleteType,
                    authorProfileImageData: currentProfile.profileImageData,
                    isPublicAuthor: currentProfile.isPublicProfile,
                    onPost: { newPost in
                        postStore.addPost(newPost)
                    }
                )
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

    // MARK: - Profile Header
    private var profileHeader: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            // Interactive Athlete Avatar with Photo Picker trigger
            AthleteAvatarView(
                imageData: currentProfile.profileImageData,
                symbolFallback: currentProfile.avatarSymbol.isEmpty ? currentProfile.athleteType.iconName : currentProfile.avatarSymbol,
                initials: currentProfile.fullName,
                ringColor: currentProfile.athleteType.badgeColor,
                size: 92,
                showCameraBadge: true,
                isPublic: currentProfile.isPublicProfile,
                onCameraTap: {
                    showingEditPhotoSheet = true
                }
            )
            .onTapGesture {
                showingEditPhotoSheet = true
            }

            VStack(spacing: 6) {
                HStack(spacing: 6) {
                    Text(currentProfile.fullName)
                        .font(AppTheme.largeTitleFont)
                        .foregroundStyle(AppTheme.text)

                    if subManager.isPro {
                        Text("PRO")
                            .font(.system(size: 11, weight: .black))
                            .foregroundStyle(AppTheme.onPrimary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(AppTheme.primary)
                            .clipShape(Capsule())
                    }
                }

                HStack(spacing: 8) {
                    Text("@\(currentProfile.handle)")
                        .font(AppTheme.monoFont)
                        .foregroundStyle(AppTheme.textSecondary)

                    // Public / Private Profile Status Pill
                    HStack(spacing: 4) {
                        Image(systemName: currentProfile.isPublicProfile ? "globe.americas.fill" : "lock.fill")
                            .font(.system(size: 10, weight: .semibold))
                        Text(currentProfile.isPublicProfile ? "Public Profile" : "Private")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundColor(currentProfile.isPublicProfile ? AppTheme.primary : AppTheme.textSecondary)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background((currentProfile.isPublicProfile ? AppTheme.primary : AppTheme.textSecondary).opacity(0.12))
                    .clipShape(Capsule())
                }

                Text(currentProfile.bio)
                    .font(AppTheme.bodyFont)
                    .foregroundStyle(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
                    .padding(.top, 2)

                // Quick Edit Photo & Profile Action Buttons
                HStack(spacing: 12) {
                    Button {
                        showingEditPhotoSheet = true
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 11, weight: .semibold))
                            Text(currentProfile.profileImageData == nil ? "Add Photo" : "Change Photo")
                                .font(AppTheme.eyebrowFont)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(AppTheme.surfaceRaised)
                        .foregroundColor(AppTheme.text)
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(AppTheme.hairline, lineWidth: 1))
                    }

                    Button {
                        showingEditAthleteType = true
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "slider.horizontal.3")
                                .font(.system(size: 11, weight: .semibold))
                            Text("Edit Profile")
                                .font(AppTheme.eyebrowFont)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(AppTheme.surfaceRaised)
                        .foregroundColor(AppTheme.text)
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(AppTheme.hairline, lineWidth: 1))
                    }
                }
                .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppTheme.Spacing.xs)
    }

    // MARK: - Instagram-style Social Counters Row
    private var profileSocialCountersRow: some View {
        HStack(spacing: 0) {
            Button {
                selectedMediaTab = .posts
            } label: {
                VStack(spacing: 2) {
                    Text("\(myPosts.count)")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.text)
                    Text("Posts")
                        .font(AppTheme.captionFont)
                        .foregroundStyle(AppTheme.textSecondary)
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.plain)

            Divider()
                .frame(height: 24)
                .background(AppTheme.hairline)

            VStack(spacing: 2) {
                Text("1.2K")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.text)
                Text("Followers")
                    .font(AppTheme.captionFont)
                    .foregroundStyle(AppTheme.textSecondary)
            }
            .frame(maxWidth: .infinity)

            Divider()
                .frame(height: 24)
                .background(AppTheme.hairline)

            VStack(spacing: 2) {
                Text("\(myPosts.reduce(0) { $0 + $1.likesCount })")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.primary)
                Text("Likes")
                    .font(AppTheme.captionFont)
                    .foregroundStyle(AppTheme.textSecondary)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 10)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.card))
    }

    // MARK: - Profile Media Tab Section (Grid, Reels, Stats)
    private var profileMediaSection: some View {
        VStack(spacing: 12) {
            // Segmented Header
            HStack(spacing: 0) {
                ForEach(ProfileMediaTab.allCases, id: \.self) { tab in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedMediaTab = tab
                        }
                    } label: {
                        VStack(spacing: 8) {
                            HStack(spacing: 6) {
                                switch tab {
                                case .posts:
                                    Image(systemName: "squareshape.split.3x3")
                                        .font(.system(size: 14, weight: selectedMediaTab == tab ? .bold : .regular))
                                case .reels:
                                    Image(systemName: "play.rectangle.on.rectangle")
                                        .font(.system(size: 14, weight: selectedMediaTab == tab ? .bold : .regular))
                                case .stats:
                                    Image(systemName: "chart.bar.fill")
                                        .font(.system(size: 14, weight: selectedMediaTab == tab ? .bold : .regular))
                                }

                                Text(tab.rawValue)
                                    .font(.system(size: 13, weight: selectedMediaTab == tab ? .bold : .medium))
                            }
                            .foregroundStyle(selectedMediaTab == tab ? AppTheme.primary : AppTheme.textSecondary)

                            // Underline indicator
                            Rectangle()
                                .fill(selectedMediaTab == tab ? AppTheme.primary : Color.clear)
                                .frame(height: 2)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.top, 4)

            // Tab Content
            switch selectedMediaTab {
            case .posts:
                if postGridItems.isEmpty {
                    emptyMediaPlaceholder(
                        icon: "camera.fill",
                        title: "No Posts Yet",
                        subtitle: "Share your workout achievements, PRs, and training recaps to your profile."
                    )
                } else {
                    FeedProfileGrid(
                        items: postGridItems,
                        onSelect: { item in
                            if let postID = item.postID {
                                selectedPostDetailID = postID
                            }
                        },
                        config: FeedProfileGridConfig(tileAspect: 1, spacing: 2, columns: 3)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.card))
                }

            case .reels:
                if reelGridItems.isEmpty {
                    emptyMediaPlaceholder(
                        icon: "video.badge.plus",
                        title: "No Reels Yet",
                        subtitle: "Record workout form checks and high-intensity clips to build your reel showcase."
                    )
                } else {
                    FeedProfileGrid(
                        items: reelGridItems,
                        onSelect: { item in
                            if let postID = item.postID,
                               let post = myPosts.first(where: { $0.id == postID }) {
                                activeReelPost = post
                            }
                        },
                        config: FeedProfileGridConfig(tileAspect: 0.75, spacing: 2, columns: 3)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.card))
                }

            case .stats:
                EmptyView()
            }
        }
        .padding(.vertical, 4)
    }

    private func emptyMediaPlaceholder(icon: String, title: String, subtitle: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 36))
                .foregroundStyle(AppTheme.primary.opacity(0.8))

            Text(title)
                .font(AppTheme.headlineFont)
                .foregroundStyle(AppTheme.text)

            Text(subtitle)
                .font(AppTheme.captionFont)
                .foregroundStyle(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            Button {
                showingNewPostSheet = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .bold))
                    Text("Create First Post")
                        .font(AppTheme.captionFont.weight(.bold))
                }
                .foregroundStyle(Color.black)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(AppTheme.primary)
                .clipShape(Capsule())
            }
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.card))
    }

    // MARK: - Apple Watch Profile Card
    private var appleWatchProfileCard: some View {
        Button {
            showingWatchHub = true
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(watchManager.pairingStatus.tintColor.opacity(0.18))
                        .frame(width: 48, height: 48)

                    Image(systemName: watchManager.pairingStatus.iconName)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(watchManager.pairingStatus.tintColor)
                }

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text("Apple Watch & Health")
                            .font(AppTheme.headlineFont)
                            .foregroundStyle(AppTheme.text)

                        Text(watchManager.pairingStatus == .pairedAndReachable ? "LINKED" : "SETUP")
                            .font(AppTheme.eyebrowFont)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(watchManager.pairingStatus.tintColor.opacity(0.2))
                            .foregroundStyle(watchManager.pairingStatus.tintColor)
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.tag))
                    }

                    Text("Live heart rate zones, wrist telemetry & Apple Health biometrics sync.")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(AppTheme.textSecondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                HStack(spacing: 4) {
                    Text("Manage")
                        .font(AppTheme.eyebrowFont)
                        .foregroundStyle(AppTheme.primary)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(AppTheme.primary)
                }
            }
            .padding(AppTheme.Spacing.md)
            .background(
                ZStack {
                    AppTheme.surface
                    LinearGradient(
                        colors: [watchManager.pairingStatus.tintColor.opacity(0.08), Color.clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.card))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Radii.card)
                    .stroke(watchManager.pairingStatus.tintColor.opacity(0.25), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Athlete Archetype Badge Card
    private var athleteArchetypeCard: some View {
        Button {
            showingEditAthleteType = true
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(currentProfile.athleteType.badgeColor.opacity(0.18))
                        .frame(width: 48, height: 48)

                    Image(systemName: currentProfile.athleteType.iconName)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(currentProfile.athleteType.badgeColor)
                }

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(currentProfile.athleteType.rawValue)
                            .font(AppTheme.headlineFont)
                            .foregroundColor(AppTheme.text)

                        Text(currentProfile.athleteType.shortTag)
                            .font(AppTheme.eyebrowFont)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(currentProfile.athleteType.badgeColor.opacity(0.2))
                            .foregroundColor(currentProfile.athleteType.badgeColor)
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.tag))
                    }

                    Text(currentProfile.athleteType.description)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(AppTheme.textSecondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                HStack(spacing: 4) {
                    Text("Change")
                        .font(AppTheme.eyebrowFont)
                        .foregroundColor(AppTheme.primary)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(AppTheme.primary)
                }
            }
            .padding(AppTheme.Spacing.md)
            .background(
                ZStack {
                    AppTheme.surface
                    LinearGradient(
                        colors: [currentProfile.athleteType.badgeColor.opacity(0.08), Color.clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.card))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Radii.card)
                    .stroke(currentProfile.athleteType.badgeColor.opacity(0.4), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Pro Membership Card
    private var proMembershipCard: some View {
        Button {
            showingPaywall = true
        } label: {
            HStack(spacing: AppTheme.Spacing.md) {
                ZStack {
                    Circle()
                        .fill(AppTheme.primary.opacity(0.18))
                        .frame(width: 48, height: 48)
                    Image(systemName: subManager.isPro ? "crown.fill" : "sparkles")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(AppTheme.primary)
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(subManager.isPro ? "Solxce Pro Active" : "Upgrade to Solxce Pro")
                            .font(AppTheme.headlineFont)
                            .foregroundStyle(AppTheme.text)

                        Text(subManager.isPro ? subManager.activePlan.title : "$4.99/mo or $49.99/yr")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(AppTheme.onPrimary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(AppTheme.primary)
                            .clipShape(Capsule())
                    }

                    Text(subManager.isPro ? "Camera food scan, fasting alerts & deep analytics active." : "Unlock camera food scan, fasting alerts & deep analytics.")
                        .font(AppTheme.captionFont)
                        .foregroundStyle(AppTheme.textSecondary)
                        .lineLimit(2)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppTheme.primary)
            }
            .padding(AppTheme.Spacing.md)
            .background(AppTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.card))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Radii.card)
                    .strokeBorder(AppTheme.primary.opacity(0.4), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - In-Depth Report Shortcut
    private var inDepthReportShortcut: some View {
        Button {
            showingProgressReport = true
        } label: {
            HStack {
                Image(systemName: "chart.xyaxis.line")
                    .foregroundStyle(AppTheme.primary)
                Text("View In-Depth Progress Report")
                    .font(AppTheme.headlineFont)
                    .foregroundStyle(AppTheme.text)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppTheme.textMuted)
            }
            .padding(AppTheme.Spacing.md)
            .background(AppTheme.surfaceRaised)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.card))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Lifetime Stats Card
    private var lifetimeStatsCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text("LIFETIME METRICS")
                .font(AppTheme.eyebrowFont)
                .tracking(1.5)
                .foregroundStyle(AppTheme.textSecondary)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppTheme.Spacing.sm) {
                metricCell(
                    title: "WORKOUTS",
                    value: "\(workoutSessions.count)",
                    subtext: "Sessions Completed",
                    color: AppTheme.primary
                )
                metricCell(
                    title: "TOTAL VOLUME",
                    value: "\(Int(totalVolumeLbs))",
                    subtext: "Pounds Lifted",
                    color: AppTheme.proteinColor
                )
                metricCell(
                    title: "TOTAL DISTANCE",
                    value: String(format: "%.1f", totalRunMiles),
                    subtext: "Miles Run",
                    color: AppTheme.carbsColor
                )
                metricCell(
                    title: "TOTAL SETS",
                    value: "\(totalSetsCompleted)",
                    subtext: "Sets Logged",
                    color: AppTheme.fatColor
                )
            }
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.card))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radii.card)
                .strokeBorder(AppTheme.hairline)
        )
    }

    private func metricCell(title: String, value: String, subtext: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(AppTheme.eyebrowFont)
                .foregroundStyle(AppTheme.textMuted)

            Text(value)
                .font(AppTheme.titleFont)
                .bold()
                .foregroundStyle(color)

            Text(subtext)
                .font(AppTheme.captionFont)
                .foregroundStyle(AppTheme.textSecondary)
        }
        .padding(AppTheme.Spacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.surfaceRaised)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.tag))
    }

    // MARK: - Nutrition Goals
    private var nutritionGoalsCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            HStack {
                Text("DAILY MACRO TARGETS")
                    .font(AppTheme.eyebrowFont)
                    .tracking(1.5)
                    .foregroundStyle(AppTheme.textSecondary)

                Spacer()

                Button("Edit Targets") {
                    showingEditGoals = true
                }
                .font(AppTheme.captionFont)
                .bold()
                .foregroundStyle(AppTheme.primary)
            }

            HStack(spacing: AppTheme.Spacing.xs) {
                targetPill(label: "Calories", value: "\(target?.dailyCalories ?? 2400) kcal", color: AppTheme.caloriesColor)
                targetPill(label: "Protein", value: "\(target?.dailyProteinGrams ?? 180)g", color: AppTheme.proteinColor)
                targetPill(label: "Carbs", value: "\(target?.dailyCarbsGrams ?? 240)g", color: AppTheme.carbsColor)
                targetPill(label: "Fat", value: "\(target?.dailyFatGrams ?? 70)g", color: AppTheme.fatColor)
            }
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.card))
    }

    private func targetPill(label: String, value: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(AppTheme.eyebrowFont)
                .foregroundStyle(AppTheme.textSecondary)
            Text(value)
                .font(AppTheme.captionFont)
                .bold()
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity)
        .padding(8)
        .background(AppTheme.surfaceRaised)
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    // MARK: - App Appearance Theme Selector Card
    private var appearanceCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            HStack {
                Text("APPEARANCE")
                    .font(AppTheme.eyebrowFont)
                    .tracking(1.5)
                    .foregroundStyle(AppTheme.textSecondary)

                Spacer()

                HStack(spacing: 4) {
                    Image(systemName: (AppAppearance(rawValue: appAppearanceRaw) ?? .system).iconName)
                        .font(.system(size: 11, weight: .bold))
                    Text((AppAppearance(rawValue: appAppearanceRaw) ?? .system).title)
                        .font(AppTheme.captionFont.weight(.semibold))
                }
                .foregroundStyle(AppTheme.primary)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(AppTheme.primary.opacity(0.12))
                .clipShape(Capsule())
            }

            Text("Customize Solxce with vibrant Dark Mode, crisp Light Mode, or follow your iOS device system preference.")
                .font(AppTheme.captionFont)
                .foregroundStyle(AppTheme.textSecondary)

            // Segmented 3-Way Picker
            HStack(spacing: 8) {
                ForEach(AppAppearance.allCases) { mode in
                    let isSelected = appAppearanceRaw == mode.rawValue
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            appAppearanceRaw = mode.rawValue
                        }
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: mode.iconName)
                                .font(.system(size: 18, weight: isSelected ? .bold : .medium))
                                .foregroundStyle(isSelected ? AppTheme.primary : AppTheme.textSecondary)

                            Text(mode.title)
                                .font(.system(size: 12, weight: isSelected ? .bold : .medium))
                                .foregroundStyle(isSelected ? Color.white : AppTheme.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            isSelected ? Color(red: 0.15, green: 0.15, blue: 0.15) : AppTheme.surfaceRaised
                        )
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.button))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.Radii.button)
                                .strokeBorder(
                                    isSelected ? AppTheme.primary : Color.clear,
                                    lineWidth: 1.5
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.top, 4)
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.card))
    }

    // MARK: - Training History List
    private var trainingHistoryCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text("SESSION HISTORY")
                .font(AppTheme.eyebrowFont)
                .tracking(1.5)
                .foregroundStyle(AppTheme.textSecondary)

            if workoutSessions.isEmpty && runEntries.isEmpty {
                Text("No training logged yet.")
                    .font(AppTheme.captionFont)
                    .foregroundStyle(AppTheme.textMuted)
            } else {
                ForEach(workoutSessions) { session in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(session.title)
                                .font(AppTheme.headlineFont)
                                .foregroundStyle(AppTheme.text)
                            Text("\(session.bodyPartFocus) · \(session.exercises.count) exercises · \(Int(session.totalVolumeLbs)) lbs")
                                .font(AppTheme.captionFont)
                                .foregroundStyle(AppTheme.textSecondary)
                        }

                        Spacer()

                        Text(session.date.formatted(.dateTime.month().day()))
                            .font(AppTheme.captionFont)
                            .foregroundStyle(AppTheme.textMuted)
                    }
                    .padding(AppTheme.Spacing.sm)
                    .background(AppTheme.surfaceRaised)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.tag))
                }
            }
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.card))
    }
}

// MARK: - Edit Athlete Type Sheet
struct EditAthleteTypeSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var profile: UserProfile

    @State private var selectedType: AthleteType = .hybrid
    @State private var fullName: String = ""
    @State private var handle: String = ""
    @State private var bio: String = ""
    @State private var isPublic: Bool = true
    @State private var showingPhotoPicker = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.lg) {
                    // Profile Photo & Privacy Status Header
                    VStack(spacing: 12) {
                        AthleteAvatarView(
                            imageData: profile.profileImageData,
                            symbolFallback: profile.avatarSymbol.isEmpty ? profile.athleteType.iconName : profile.avatarSymbol,
                            initials: fullName.isEmpty ? profile.fullName : fullName,
                            ringColor: selectedType.badgeColor,
                            size: 84,
                            showCameraBadge: true,
                            isPublic: isPublic,
                            onCameraTap: {
                                showingPhotoPicker = true
                            }
                        )

                        Button {
                            showingPhotoPicker = true
                        } label: {
                            Text(profile.profileImageData == nil ? "Add Profile Photo" : "Change Profile Photo")
                                .font(AppTheme.headlineFont)
                                .foregroundColor(AppTheme.primary)
                        }
                    }
                    .padding(.top, 8)

                    // Privacy Toggle
                    VStack(alignment: .leading, spacing: 10) {
                        Text("PRIVACY & COMMUNITY")
                            .font(AppTheme.eyebrowFont)
                            .foregroundColor(AppTheme.textSecondary)

                        Toggle(isOn: $isPublic) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Make Profile & Photo Public")
                                    .font(AppTheme.headlineFont)
                                    .foregroundColor(AppTheme.text)
                                Text("Public athletes show up in the Solxce community feed and leaderboards.")
                                    .font(.system(size: 11))
                                    .foregroundColor(AppTheme.textSecondary)
                            }
                        }
                        .tint(AppTheme.primary)
                    }
                    .padding(AppTheme.Spacing.md)
                    .background(AppTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.card))

                    VStack(alignment: .leading, spacing: 12) {
                        Text("SELECT ATHLETE ARCHETYPE")
                            .font(AppTheme.eyebrowFont)
                            .foregroundColor(AppTheme.textSecondary)

                        ForEach(AthleteType.allCases) { type in
                            Button {
                                selectedType = type
                            } label: {
                                HStack(spacing: 12) {
                                    ZStack {
                                        Circle()
                                            .fill(type.badgeColor.opacity(0.2))
                                            .frame(width: 44, height: 44)

                                        Image(systemName: type.iconName)
                                            .font(.system(size: 18, weight: .bold))
                                            .foregroundColor(type.badgeColor)
                                    }

                                    VStack(alignment: .leading, spacing: 2) {
                                        HStack {
                                            Text(type.rawValue)
                                                .font(AppTheme.headlineFont)
                                                .foregroundColor(AppTheme.text)

                                            Spacer()

                                            if selectedType == type {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundColor(AppTheme.primary)
                                            }
                                        }

                                        Text(type.description)
                                            .font(.system(size: 12))
                                            .foregroundColor(AppTheme.textSecondary)
                                            .multilineTextAlignment(.leading)
                                    }
                                }
                                .padding(12)
                                .background(selectedType == type ? AppTheme.surfaceRaised : AppTheme.surface)
                                .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.card))
                                .overlay(
                                    RoundedRectangle(cornerRadius: AppTheme.Radii.card)
                                        .stroke(selectedType == type ? type.badgeColor : AppTheme.hairline, lineWidth: selectedType == type ? 1.5 : 1)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    // Personal details
                    VStack(alignment: .leading, spacing: 12) {
                        Text("PROFILE DETAILS")
                            .font(AppTheme.eyebrowFont)
                            .foregroundColor(AppTheme.textSecondary)

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Name")
                                .font(.system(size: 12))
                                .foregroundColor(AppTheme.textSecondary)
                            TextField("Name", text: $fullName)
                                .padding(10)
                                .background(AppTheme.surfaceRaised)
                                .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.button))
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Handle")
                                .font(.system(size: 12))
                                .foregroundColor(AppTheme.textSecondary)
                            TextField("Handle", text: $handle)
                                .padding(10)
                                .background(AppTheme.surfaceRaised)
                                .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.button))
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Bio")
                                .font(.system(size: 12))
                                .foregroundColor(AppTheme.textSecondary)
                            TextField("Bio", text: $bio)
                                .padding(10)
                                .background(AppTheme.surfaceRaised)
                                .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.button))
                        }
                    }
                    .padding(AppTheme.Spacing.md)
                    .background(AppTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.card))
                }
                .padding(.horizontal, AppTheme.Spacing.screenMargin)
                .padding(.top, 16)
                .padding(.bottom, 32)
            }
            .background(AppTheme.ground.ignoresSafeArea())
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(AppTheme.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                        Button {
                            // Persist to SwiftData
                            profile.athleteType = selectedType
                            profile.isPublicProfile = isPublic
                            if !fullName.isEmpty { profile.fullName = fullName }
                            if !handle.isEmpty { profile.handle = handle }
                            if !bio.isEmpty { profile.bio = bio }
                            try? modelContext.save()

                            // Asynchronously sync profile via TenxData
                            Task {
                                await BackendSyncService.shared.syncProfileData(
                                    name: profile.fullName,
                                    handle: profile.handle,
                                    athleteType: profile.athleteType.rawValue
                                )
                            }
                            dismiss()
                        } label: {
                            Text("Save")
                                .font(AppTheme.headlineFont)
                                .foregroundColor(AppTheme.primary)
                        }
                }
            }
            .sheet(isPresented: $showingPhotoPicker) {
                ProfilePhotoPickerSheet(profile: profile)
            }
            .onAppear {
                selectedType = profile.athleteType
                fullName = profile.fullName
                handle = profile.handle
                bio = profile.bio
                isPublic = profile.isPublicProfile
            }
        }
    }
}

// MARK: - Edit Macro Goals Sheet
struct EditMacroGoalsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var target: MacroTarget

    var body: some View {
        NavigationStack {
            Form {
                Section("Daily Targets") {
                    HStack {
                        Text("Daily Calories")
                        Spacer()
                        TextField("Calories", value: $target.dailyCalories, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }

                    HStack {
                        Text("Protein (g)")
                        Spacer()
                        TextField("Protein", value: $target.dailyProteinGrams, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }

                    HStack {
                        Text("Carbs (g)")
                        Spacer()
                        TextField("Carbs", value: $target.dailyCarbsGrams, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }

                    HStack {
                        Text("Fat (g)")
                        Spacer()
                        TextField("Fat", value: $target.dailyFatGrams, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppTheme.ground.ignoresSafeArea())
            .navigationTitle("Edit Nutrition Goals")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        try? modelContext.save()
                        dismiss()
                    }
                    .font(AppTheme.headlineFont)
                    .foregroundStyle(AppTheme.primary)
                }
            }
        }
    }
}
