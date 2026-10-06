// Views/FeedView.swift
import SwiftUI
import SwiftData

// MARK: - Local Feed Fixture Model
public struct AthletePost: Identifiable {
    public let id: UUID = UUID()
    public let authorName: String
    public let authorHandle: String
    public let athleteType: AthleteType
    public let authorProfileImageData: Data?
    public let isPublicAuthor: Bool
    public let timeAgo: String
    public let workoutTag: String
    public let workoutStats: String
    public let caption: String
    public let imageName: String
    public let mediaType: PostMediaType
    public let mediaItems: [PostMediaItem]
    public let mediaIconName: String
    public let gradientColors: [Color]
    public let audioTrack: AudioTrack?
    public let videoFilter: PostVideoFilter?
    public let textOverlay: String?
    public var likesCount: Int
    public var isLiked: Bool
    public var comments: [PostComment]

    public init(
        authorName: String,
        authorHandle: String,
        athleteType: AthleteType,
        authorProfileImageData: Data? = nil,
        isPublicAuthor: Bool = true,
        timeAgo: String,
        workoutTag: String,
        workoutStats: String,
        caption: String,
        imageName: String,
        mediaType: PostMediaType = .photo,
        mediaItems: [PostMediaItem] = [],
        mediaIconName: String = "figure.strengthtraining.traditional",
        gradientColors: [Color] = [Color(red: 0.15, green: 0.05, blue: 0.05), Color(red: 0.35, green: 0.1, blue: 0.1)],
        audioTrack: AudioTrack? = AudioTrack.library.first,
        videoFilter: PostVideoFilter? = .normal,
        textOverlay: String? = nil,
        likesCount: Int,
        isLiked: Bool,
        comments: [PostComment]
    ) {
        self.authorName = authorName
        self.authorHandle = authorHandle
        self.athleteType = athleteType
        self.authorProfileImageData = authorProfileImageData
        self.isPublicAuthor = isPublicAuthor
        self.timeAgo = timeAgo
        self.workoutTag = workoutTag
        self.workoutStats = workoutStats
        self.caption = caption
        self.imageName = imageName
        self.mediaType = mediaType
        self.mediaItems = mediaItems.isEmpty ? [
            PostMediaItem(id: UUID().uuidString, title: workoutTag, iconName: mediaIconName, gradientHexes: ["#1F1111", "#3D1A1A"], subtitle: workoutStats, isVideo: mediaType == .video)
        ] : mediaItems
        self.mediaIconName = mediaIconName
        self.gradientColors = gradientColors
        self.audioTrack = audioTrack
        self.videoFilter = videoFilter
        self.textOverlay = textOverlay
        self.likesCount = likesCount
        self.isLiked = isLiked
        self.comments = comments
    }
}

public struct PostComment: Identifiable {
    public let id = UUID()
    public let author: String
    public let athleteType: AthleteType?
    public let text: String
    public let timeAgo: String

    public init(author: String, athleteType: AthleteType?, text: String, timeAgo: String) {
        self.author = author
        self.athleteType = athleteType
        self.text = text
        self.timeAgo = timeAgo
    }
}

public struct AthleteStory: Identifiable {
    public let id = UUID()
    public let name: String
    public let athleteType: AthleteType
    public let hasUnseen: Bool
    public let tag: String

    public init(name: String, athleteType: AthleteType, hasUnseen: Bool, tag: String) {
        self.name = name
        self.athleteType = athleteType
        self.hasUnseen = hasUnseen
        self.tag = tag
    }
}

struct FeedView: View {
    @Query private var userProfiles: [UserProfile]

    var currentUserProfile: UserProfile? {
        userProfiles.first
    }

    var currentUserAthleteType: AthleteType {
        currentUserProfile?.athleteType ?? .hybrid
    }

    var currentUserName: String {
        currentUserProfile?.fullName ?? "You"
    }

    var currentUserHandle: String {
        currentUserProfile?.handle ?? "solxce_athlete"
    }

    @ObservedObject private var postStore = FeedPostStore.shared
    @ObservedObject private var relationshipStore = SocialRelationshipStore.shared

    // Active full screen reel modal
    @State private var activeReelPost: AthletePost? = nil
    @State private var showingCreatePostSheet = false
    @State private var shareSheetItem: ShareTextItem? = nil
    @State private var selectedOtherAthleteHandle: String? = nil
    @State private var showingDirectMessages = false

    private var visiblePosts: [Binding<AthletePost>] {
        $postStore.posts.filter { !relationshipStore.isBlocked(handle: $0.authorHandle.wrappedValue) }
    }

    private func handleShare(for post: AthletePost) {
        let text = "Check out @\(post.authorHandle)'s workout on Solxce: \(post.caption)"
        shareSheetItem = ShareTextItem(text: text)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 24) {
                    ForEach(visiblePosts) { $post in
                        SimplePostCardView(
                            post: $post,
                            onTapAuthor: {
                                if post.authorHandle != currentUserHandle {
                                    selectedOtherAthleteHandle = post.authorHandle
                                }
                            },
                            onShare: {
                                handleShare(for: post)
                            },
                            onOpenReel: {
                                activeReelPost = post
                            }
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
            }
            .background(AppTheme.ground.ignoresSafeArea())
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    SolxceLogoView(size: 42, showGlow: false)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 12) {
                        Button {
                            showingDirectMessages = true
                        } label: {
                            ZStack(alignment: .topTrailing) {
                                Image(systemName: "bubble.left.and.bubble.right.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(.white)

                                if relationshipStore.conversations.contains(where: { $0.unreadCount > 0 }) {
                                    Circle()
                                        .fill(AppTheme.primary)
                                        .frame(width: 8, height: 8)
                                        .offset(x: 3, y: -3)
                                }
                            }
                        }

                        Button {
                            showingCreatePostSheet = true
                        } label: {
                            HStack(spacing: 5) {
                                Image(systemName: "plus")
                                    .font(.system(size: 14, weight: .bold))
                                Text("New Post")
                                    .font(AppTheme.headlineFont)
                            }
                            .foregroundColor(AppTheme.primary)
                        }
                    }
                }
            }
            .sheet(isPresented: $showingDirectMessages) {
                DirectMessagesInboxView()
            }
            .sheet(isPresented: Binding(
                get: { selectedOtherAthleteHandle != nil },
                set: { if !$0 { selectedOtherAthleteHandle = nil } }
            )) {
                if let handle = selectedOtherAthleteHandle {
                    OtherUserProfileView(handle: handle)
                }
            }
            .sheet(isPresented: $showingCreatePostSheet) {
                CreateMediaPostSheet(
                    authorName: currentUserName,
                    authorHandle: currentUserHandle,
                    athleteType: currentUserAthleteType,
                    authorProfileImageData: currentUserProfile?.profileImageData,
                    isPublicAuthor: currentUserProfile?.isPublicProfile ?? true,
                    onPost: { newPost in
                        postStore.addPost(newPost)
                    }
                )
            }
            .sheet(item: $shareSheetItem) { item in
                ShareActivitySheet(text: item.text)
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
        .preferredColorScheme(AppAppearance(rawValue: UserDefaults.standard.string(forKey: "solxce_app_appearance") ?? "")?.colorScheme)
    }
}

// MARK: - Super Simple 9:16 Aspect Post Card with Multi-Picture Carousel & Video
struct SimplePostCardView: View {
    @Binding var post: AthletePost
    var onTapAuthor: (() -> Void)? = nil
    var onShare: () -> Void
    var onOpenReel: () -> Void

    @State private var selectedMediaIndex: Int = 0
    @State private var isCommenting: Bool = false
    @State private var commentText: String = ""
    @State private var showHeartBurst: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 9:16 Aspect Media Card Viewport with Swipeable Multi-Picture Carousel or Single Video
            ZStack(alignment: .bottom) {
                // Swipeable Media Content
                if post.mediaItems.count > 1 {
                    // Multi-picture horizontal swipeable carousel
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
                    // Single media item (Photo or Video)
                    mediaSlideView(for: singleItem)
                        .aspectRatio(9.0 / 16.0, contentMode: .fit)
                        .clipped()
                } else {
                    // Fallback gradient canvas
                    LinearGradient(
                        colors: post.gradientColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .aspectRatio(9.0 / 16.0, contentMode: .fit)
                    .clipped()
                }

                // Top: Author Info + Music on Top + Carousel Index Badge
                VStack(spacing: 0) {
                    HStack(spacing: 10) {
                        // Author Avatar & Handle
                        Button {
                            onTapAuthor?()
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
                                            Image(systemName: "globe.americas.fill")
                                                .font(.system(size: 9))
                                                .foregroundColor(AppTheme.primary)
                                        }
                                    }

                                    Text("@\(post.authorHandle)")
                                        .font(.system(size: 10))
                                        .foregroundColor(.white.opacity(0.8))
                                }
                            }
                        }
                        .buttonStyle(.plain)

                        Spacer()

                        // Multi-picture page badge (e.g., "1/3")
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
                            .overlay(
                                Capsule().stroke(Color.white.opacity(0.18), lineWidth: 0.5)
                            )
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

                        // Music on Top Bar / Pill
                        if let audio = post.audioTrack {
                            HStack(spacing: 5) {
                                Image(systemName: audio.platform.iconName)
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(audio.platform.brandColor)

                                EqualizerAnimationView()
                                    .frame(width: 12, height: 10)
                                    .foregroundColor(AppTheme.primary)

                                Text("\(audio.title) · \(audio.artist)")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                                    .frame(maxWidth: 110, alignment: .leading)
                            }
                            .padding(.horizontal, 9)
                            .padding(.vertical, 5)
                            .background(Color.black.opacity(0.65))
                            .clipShape(Capsule())
                            .overlay(
                                Capsule().stroke(Color.white.opacity(0.15), lineWidth: 0.5)
                            )
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.top, 14)

                    Spacer()
                }

                // Bottom Gradient Scrim for readable Caption overlay
                LinearGradient(
                    colors: [Color.clear, Color.black.opacity(0.85)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 130)

                // Bottom Caption Overlay + Page Dots
                VStack(alignment: .leading, spacing: 6) {
                    // Multi-picture dots indicator
                    if post.mediaItems.count > 1 {
                        HStack(spacing: 5) {
                            ForEach(0..<post.mediaItems.count, id: \.self) { dotIdx in
                                Capsule()
                                    .fill(dotIdx == selectedMediaIndex ? AppTheme.primary : Color.white.opacity(0.4))
                                    .frame(width: dotIdx == selectedMediaIndex ? 16 : 5, height: 5)
                                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedMediaIndex)
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

                // Double Tap Heart Animation
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

            // Just the Likes, Comments, and Share Button
            HStack(spacing: 24) {
                // Like Button
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        post.isLiked.toggle()
                        post.likesCount += post.isLiked ? 1 : -1
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: post.isLiked ? "heart.fill" : "heart")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(post.isLiked ? AppTheme.accent : AppTheme.text)
                        Text("\(post.likesCount)")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(AppTheme.text)
                    }
                }
                .buttonStyle(.plain)

                // Comment Button
                Button {
                    withAnimation(.spring()) {
                        isCommenting.toggle()
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "bubble.right")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(AppTheme.text)
                        Text("\(post.comments.count)")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(AppTheme.text)
                    }
                }
                .buttonStyle(.plain)

                // Share Button
                Button {
                    onShare()
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(AppTheme.text)
                }
                .buttonStyle(.plain)

                Spacer()
            }
            .padding(.horizontal, 4)
            .padding(.top, 12)

            // Inline quick comments section
            if isCommenting {
                VStack(alignment: .leading, spacing: 8) {
                    Divider().background(AppTheme.hairline)

                    ForEach(post.comments) { comment in
                        HStack(alignment: .top, spacing: 8) {
                            Text(comment.author)
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(AppTheme.text)
                            Text(comment.text)
                                .font(.system(size: 12))
                                .foregroundColor(AppTheme.textSecondary)
                            Spacer()
                            Text(comment.timeAgo)
                                .font(.system(size: 10))
                                .foregroundColor(AppTheme.textMuted)
                        }
                    }

                    HStack(spacing: 8) {
                        TextField("Add a comment...", text: $commentText)
                            .font(.system(size: 13))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(AppTheme.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 8))

                        Button {
                            guard !commentText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                            let newComment = PostComment(
                                author: "you",
                                athleteType: post.athleteType,
                                text: commentText,
                                timeAgo: "Just now"
                            )
                            post.comments.append(newComment)
                            commentText = ""
                        } label: {
                            Text("Post")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(AppTheme.primary)
                        }
                    }
                    .padding(.top, 4)
                }
                .padding(.top, 8)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    // MARK: - Slide View for Individual Carousel Item or Video
    private func mediaSlideView(for item: PostMediaItem) -> some View {
        ZStack {
            if let customData = item.customImageData, let uiImage = UIImage(data: customData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
            } else {
                LinearGradient(
                    colors: item.gradientColors.isEmpty ? post.gradientColors : item.gradientColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(post.athleteType.badgeColor.opacity(0.18))
                            .frame(width: 84, height: 84)

                        Image(systemName: item.iconName)
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(post.athleteType.badgeColor)
                    }

                    if let sub = item.subtitle, !sub.isEmpty {
                        Text(sub)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white.opacity(0.85))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.black.opacity(0.55))
                            .clipShape(Capsule())
                    }

                    if let sticker = post.textOverlay, !sticker.isEmpty {
                        TikTokTextBadgeView(
                            text: sticker,
                            fontStyle: .neon,
                            highlightMode: .filled,
                            textColor: Color(hex: "#CCFF00"),
                            fontSize: 14
                        )
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}

// MARK: - Equalizer Sound Animation
struct EqualizerAnimationView: View {
    @State private var animating = false

    var body: some View {
        HStack(alignment: .bottom, spacing: 2) {
            bar(height: animating ? 10 : 3, delay: 0.0)
            bar(height: animating ? 6 : 8, delay: 0.15)
            bar(height: animating ? 10 : 4, delay: 0.3)
        }
        .onAppear {
            animating = true
        }
    }

    private func bar(height: CGFloat, delay: Double) -> some View {
        RoundedRectangle(cornerRadius: 1)
            .fill(AppTheme.primary)
            .frame(width: 2, height: height)
            .animation(
                Animation.easeInOut(duration: 0.4)
                    .repeatForever(autoreverses: true)
                    .delay(delay),
                value: animating
            )
    }
}

// MARK: - Share Item Wrapper
struct ShareTextItem: Identifiable {
    let id = UUID()
    let text: String
}

// MARK: - Native Share Sheet Helper
struct ShareActivitySheet: UIViewControllerRepresentable {
    let text: String

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [text], applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
