// Views/FeedView.swift
import SwiftUI
import SwiftData

struct FeedView: View {
    @ObservedObject private var postStore = FeedPostStore.shared
    @ObservedObject private var socialManager = SocialPrivacyManager.shared

    @State private var showingCreatePostSheet = false
    @State private var showingDirectMessages = false
    @State private var showingPrivacySettings = false
    @State private var selectedAthleteForProfile: String? = nil
    @State private var selectedPostDetail: AthletePost? = nil
    @State private var activeReelPost: AthletePost? = nil

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                ScrollView {
                    VStack(spacing: AppTheme.Spacing.md) {
                        // Community Filter Tabs & Stories
                        communityFilterHeader

                        // Athlete Type Quick Filter Bar
                        athleteFilterPills

                        // Posts Feed
                        if postStore.displayedPosts.isEmpty {
                            emptyFeedView
                        } else {
                            LazyVStack(spacing: AppTheme.Spacing.lg) {
                                ForEach(postStore.displayedPosts) { post in
                                    PostCardView(
                                        post: post,
                                        onAuthorTap: {
                                            selectedAthleteForProfile = post.authorHandle
                                        },
                                        onOpenReel: {
                                            activeReelPost = post
                                        },
                                        onOpenComments: {
                                            selectedPostDetail = post
                                        }
                                    )
                                }
                            }
                        }
                    }
                    .padding(.horizontal, AppTheme.Spacing.screenMargin)
                    .padding(.top, AppTheme.Spacing.sm)
                    .padding(.bottom, 80)
                }

                // Floating Action Button for Create Post
                createPostFloatingButton
            }
            .background(AppTheme.ground.ignoresSafeArea())
            .navigationTitle("Community")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showingPrivacySettings = true
                    } label: {
                        Image(systemName: "hand.raised.shield")
                            .font(.system(size: 16))
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingDirectMessages = true
                    } label: {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: "bubble.left.and.bubble.right.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(AppTheme.primary)

                            let unread = socialManager.conversations.reduce(0) { $0 + $1.unreadCount }
                            if unread > 0 {
                                Circle()
                                    .fill(AppTheme.accent)
                                    .frame(width: 8, height: 8)
                                    .offset(x: 4, y: -2)
                            }
                        }
                        .frame(width: 36, height: 36)
                    }
                }
            }
            .sheet(isPresented: $showingCreatePostSheet) {
                NavigationStack {
                    CreatePostView { newPost in
                        postStore.addPost(
                            caption: newPost.caption,
                            workoutTag: newPost.workoutTag,
                            mediaItems: newPost.mediaItems,
                            athleteType: newPost.athleteType,
                            audioTrack: newPost.audioTrack
                        )
                    }
                }
            }
            .sheet(isPresented: $showingDirectMessages) {
                DirectMessagesListView()
            }
            .sheet(isPresented: $showingPrivacySettings) {
                PrivacyAndSecurityView()
            }
            .sheet(item: Binding(
                get: {
                    if let handle = selectedAthleteForProfile {
                        return ProfileHandleWrapper(handle: handle)
                    }
                    return nil
                },
                set: { selectedAthleteForProfile = $0?.handle }
            )) { wrapper in
                OtherUserProfileView(athleteHandle: wrapper.handle)
            }
            .sheet(item: $selectedPostDetail) { post in
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

    // MARK: - Community Filter Header
    private var communityFilterHeader: some View {
        HStack(spacing: 8) {
            ForEach(FeedPostStore.CommunityFilter.allCases) { filter in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        postStore.communityFilter = filter
                    }
                } label: {
                    Text(filter.rawValue)
                        .font(AppTheme.headlineFont)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(
                            postStore.communityFilter == filter
                                ? AppTheme.accent
                                : AppTheme.surface
                        )
                        .foregroundStyle(
                            postStore.communityFilter == filter
                                ? AppTheme.inverseText
                                : AppTheme.textSecondary
                        )
                        .clipShape(Capsule())
                }
            }
            Spacer()
        }
        .padding(.vertical, 2)
    }

    // MARK: - Athlete Filter Pills
    private var athleteFilterPills: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        postStore.filteredAthleteType = nil
                    }
                } label: {
                    Text("All Disciplines")
                        .font(AppTheme.captionFont.weight(.semibold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            postStore.filteredAthleteType == nil
                                ? AppTheme.surfaceElevated
                                : AppTheme.surface
                        )
                        .foregroundStyle(
                            postStore.filteredAthleteType == nil
                                ? AppTheme.primary
                                : AppTheme.textSecondary
                        )
                        .clipShape(Capsule())
                        .overlay(
                            Capsule().stroke(Color.white.opacity(postStore.filteredAthleteType == nil ? 0.2 : 0.05), lineWidth: 1)
                        )
                }

                ForEach(AthleteType.allCases, id: \.self) { type in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            postStore.filteredAthleteType = (postStore.filteredAthleteType == type) ? nil : type
                        }
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: type.iconName)
                                .font(.system(size: 11))
                            Text(type.rawValue)
                                .font(AppTheme.captionFont.weight(.semibold))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            postStore.filteredAthleteType == type
                                ? type.badgeColor.opacity(0.2)
                                : AppTheme.surface
                        )
                        .foregroundStyle(
                            postStore.filteredAthleteType == type
                                ? type.badgeColor
                                : AppTheme.textSecondary
                        )
                        .clipShape(Capsule())
                        .overlay(
                            Capsule().stroke(postStore.filteredAthleteType == type ? type.badgeColor : Color.white.opacity(0.05), lineWidth: 1)
                        )
                    }
                }
            }
        }
    }

    // MARK: - Empty Feed State
    private var emptyFeedView: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.2.slash")
                .font(.system(size: 40))
                .foregroundStyle(AppTheme.textSecondary.opacity(0.5))
                .padding(.top, 40)

            Text("No Posts in Feed")
                .font(AppTheme.headlineFont)
                .foregroundStyle(AppTheme.primary)

            Text(postStore.communityFilter == .following
                 ? "You aren't following any athletes yet or your followed accounts haven't posted."
                 : "No posts match the active discipline and privacy filters.")
                .font(AppTheme.captionFont)
                .foregroundStyle(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)

            if postStore.communityFilter == .following {
                Button {
                    postStore.communityFilter = .forYou
                } label: {
                    Text("Explore For You")
                        .font(AppTheme.captionFont.weight(.bold))
                        .foregroundStyle(AppTheme.inverseText)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(AppTheme.accent)
                        .clipShape(Capsule())
                }
                .padding(.top, 8)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
    }

    // MARK: - Floating Create Button
    private var createPostFloatingButton: some View {
        Button {
            showingCreatePostSheet = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "plus")
                    .font(.system(size: 16, weight: .bold))
                Text("Log Post")
                    .font(AppTheme.headlineFont)
            }
            .foregroundStyle(AppTheme.inverseText)
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .background(AppTheme.accent)
            .clipShape(Capsule())
            .shadow(color: AppTheme.accent.opacity(0.4), radius: 10, x: 0, y: 4)
        }
        .padding(.trailing, AppTheme.Spacing.screenMargin)
        .padding(.bottom, 20)
    }
}

// Wrapper for Identifiable string
struct ProfileHandleWrapper: Identifiable {
    var id: String { handle }
    let handle: String
}

// MARK: - Post Card View
struct PostCardView: View {
    @State var post: AthletePost
    let onAuthorTap: () -> Void
    let onOpenReel: () -> Void
    let onOpenComments: () -> Void

    @State private var selectedMediaIndex: Int = 0
    @State private var showHeartBurst = false
    @State private var showingShareSheet = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 9:16 Aspect Media Card Viewport
            ZStack(alignment: .bottom) {
                if post.mediaItems.count > 1 {
                    TabView(selection: $selectedMediaIndex) {
                        ForEach(Array(post.mediaItems.enumerated()), id: \.element.id) { index, item in
                            mediaSlideView(for: item)
                                .tag(index)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .aspectRatio(9.0 / 16.0, contentMode: .fit)
                    .clipped()
                } else if let singleItem = post.mediaItems.first {
                    mediaSlideView(for: singleItem)
                        .aspectRatio(9.0 / 16.0, contentMode: .fit)
                        .clipped()
                } else {
                    LinearGradient(
                        colors: post.gradientColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .aspectRatio(9.0 / 16.0, contentMode: .fit)
                    .clipped()
                }

                // Top: Author Info Bar
                VStack(spacing: 0) {
                    HStack(spacing: 10) {
                        Button {
                            onAuthorTap()
                        } label: {
                            HStack(spacing: 8) {
                                AthleteAvatarView(
                                    imageData: post.authorProfileImageData,
                                    symbolFallback: post.athleteType.iconName,
                                    initials: post.authorName,
                                    ringColor: post.athleteType.badgeColor,
                                    size: 34,
                                    showCameraBadge: false,
                                    isPublic: post.isPublicAuthor
                                )

                                VStack(alignment: .leading, spacing: 1) {
                                    HStack(spacing: 4) {
                                        Text(post.authorName)
                                            .font(.system(size: 13, weight: .bold))
                                            .foregroundColor(.white)

                                        if post.isPublicAuthor {
                                            Image(systemName: "checkmark.seal.fill")
                                                .font(.system(size: 10))
                                                .foregroundColor(AppTheme.accent)
                                        }
                                    }

                                    Text("@\(post.authorHandle)")
                                        .font(.system(size: 10))
                                        .foregroundColor(.white.opacity(0.8))
                                }
                            }
                        }

                        Spacer()

                        if post.mediaItems.count > 1 {
                            HStack(spacing: 4) {
                                Image(systemName: "square.stack.3d.forward.dottedline.fill")
                                    .font(.system(size: 10, weight: .bold))
                                Text("\(selectedMediaIndex + 1)/\(post.mediaItems.count)")
                                    .font(.system(size: 11, weight: .black, design: .monospaced))
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.black.opacity(0.65))
                            .foregroundColor(.white)
                            .clipShape(Capsule())
                        } else if post.mediaType == .video {
                            HStack(spacing: 4) {
                                Image(systemName: "video.fill")
                                    .font(.system(size: 9, weight: .bold))
                                Text("REEL")
                                    .font(.system(size: 10, weight: .black))
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.black.opacity(0.65))
                            .foregroundColor(AppTheme.primary)
                            .clipShape(Capsule())
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.top, 14)

                    Spacer()
                }

                // Bottom Gradient Scrim
                LinearGradient(
                    colors: [Color.clear, Color.black.opacity(0.85)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 130)

                // Bottom Caption & Tags
                VStack(alignment: .leading, spacing: 6) {
                    if post.mediaItems.count > 1 {
                        HStack(spacing: 5) {
                            ForEach(0..<post.mediaItems.count, id: \.self) { dotIdx in
                                Capsule()
                                    .fill(dotIdx == selectedMediaIndex ? AppTheme.primary : Color.white.opacity(0.4))
                                    .frame(width: dotIdx == selectedMediaIndex ? 16 : 5, height: 5)
                            }
                        }
                        .padding(.bottom, 2)
                    }

                    HStack {
                        Text(post.workoutTag)
                            .font(.system(size: 10, weight: .black))
                            .foregroundColor(AppTheme.primary)
                            .tracking(1)

                        Spacer()

                        Text(post.timeAgo)
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.7))
                    }

                    Text(post.caption)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white)
                        .lineLimit(2)
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 14)

                if showHeartBurst {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 72))
                        .foregroundColor(AppTheme.accent)
                        .scaleEffect(1.2)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(AppTheme.hairline, lineWidth: 1)
            )
            .contentShape(Rectangle())
            .onTapGesture(count: 2) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    showHeartBurst = true
                    if !post.isLiked {
                        post.isLiked = true
                        post.likesCount += 1
                    }
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    withAnimation { showHeartBurst = false }
                }
            }
            .onTapGesture(count: 1) {
                onOpenReel()
            }

            // Likes, Comments, Author Profile, and Share
            HStack(spacing: 24) {
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        post.isLiked.toggle()
                        post.likesCount += post.isLiked ? 1 : -1
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: post.isLiked ? "heart.fill" : "heart")
                            .font(.system(size: 17))
                            .foregroundColor(post.isLiked ? Color(hex: "#FF3B5C") : AppTheme.primary)
                        Text("\(post.likesCount)")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundColor(AppTheme.primary)
                    }
                }

                Button {
                    onOpenComments()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "bubble.right")
                            .font(.system(size: 16))
                            .foregroundColor(AppTheme.primary)
                        Text("\(post.commentsCount)")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundColor(AppTheme.primary)
                    }
                }

                Button {
                    onAuthorTap()
                } label: {
                    Image(systemName: "person.crop.circle")
                        .font(.system(size: 17))
                        .foregroundColor(AppTheme.primary)
                }

                Spacer()

                Button {
                    showingShareSheet = true
                } label: {
                    Image(systemName: "paperplane")
                        .font(.system(size: 16))
                        .foregroundColor(AppTheme.primary)
                }
            }
            .padding(.horizontal, 10)
            .padding(.top, 12)
            .padding(.bottom, 6)
        }
        .padding(.bottom, 6)
    }

    @ViewBuilder
    private func mediaSlideView(for item: PostMediaItem) -> some View {
        if let data = item.imageData, let uiImage = UIImage(data: data) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
        } else {
            ZStack {
                LinearGradient(
                    colors: item.placeholderGradient,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                Image(systemName: item.type == .video ? "play.circle.fill" : "dumbbell.fill")
                    .font(.system(size: 42))
                    .foregroundColor(Color.white.opacity(0.8))
            }
        }
    }
}

// MARK: - Post Detail Modal Sheet
struct PostDetailModalSheet: View {
    @State var post: AthletePost
    @Environment(\.dismiss) private var dismiss
    @State private var commentText = ""
    @State private var comments: [PostComment] = [
        PostComment(authorName: "Marcus Vance", authorHandle: "marcus_lifts", text: "Incredible tempo and lockouts! ⚡", timeAgo: "1h ago"),
        PostComment(authorName: "Elena Rostova", authorHandle: "elena_runs", text: "Consistency at its highest level.", timeAgo: "30m ago")
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                List {
                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(post.workoutTag)
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(AppTheme.accent)
                            Text(post.caption)
                                .font(AppTheme.bodyFont)
                                .foregroundStyle(AppTheme.primary)
                        }
                        .padding(.vertical, 4)
                    }

                    Section(header: Text("Athlete Comments (\(comments.count))").foregroundStyle(AppTheme.textSecondary)) {
                        ForEach(comments) { comment in
                            VStack(alignment: .leading, spacing: 2) {
                                HStack {
                                    Text("@\(comment.authorHandle)")
                                        .font(AppTheme.headlineFont)
                                        .foregroundStyle(AppTheme.primary)
                                    Spacer()
                                    Text(comment.timeAgo)
                                        .font(AppTheme.captionFont)
                                        .foregroundStyle(AppTheme.textSecondary)
                                }
                                Text(comment.text)
                                    .font(AppTheme.bodyFont)
                                    .foregroundStyle(AppTheme.textSecondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                .scrollContentBackground(.hidden)

                // Comment input
                HStack(spacing: 8) {
                    TextField("Add a comment for @\(post.authorHandle)...", text: $commentText)
                        .font(AppTheme.bodyFont)
                        .foregroundStyle(AppTheme.primary)

                    if !commentText.isEmpty {
                        Button("Post") {
                            comments.append(
                                PostComment(
                                    authorName: "Alex Rivera",
                                    authorHandle: "solxce_athlete",
                                    text: commentText,
                                    timeAgo: "Just now"
                                )
                            )
                            commentText = ""
                        }
                        .font(AppTheme.headlineFont)
                        .foregroundStyle(AppTheme.accent)
                    }
                }
                .padding(12)
                .background(AppTheme.surfaceElevated)
                .clipShape(Capsule())
                .padding()
            }
            .background(AppTheme.ground.ignoresSafeArea())
            .navigationTitle("Comments")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }
        }
    }
}
