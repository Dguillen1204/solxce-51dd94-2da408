// Views/TikTokReelPlayerModal.swift
import SwiftUI

struct TikTokReelPlayerModal: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var post: AthletePost
    var onAddComment: (PostComment) -> Void

    @State private var isPlaying: Bool = true
    @State private var showHeartBurst: Bool = false
    @State private var showCommentSheet: Bool = false
    @State private var newCommentText: String = ""
    @State private var currentSlideIndex: Int = 0

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            // Main Media Content Viewport (Swipeable Carousel for Photos or Full Screen Video)
            if post.mediaItems.count > 1 {
                TabView(selection: $currentSlideIndex) {
                    ForEach(Array(post.mediaItems.enumerated()), id: \.element.id) { index, item in
                        fullScreenMediaCanvas(for: item)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .ignoresSafeArea()
            } else if let singleItem = post.mediaItems.first {
                fullScreenMediaCanvas(for: singleItem)
                    .ignoresSafeArea()
            } else {
                fullScreenMediaCanvas(for: PostMediaItem(id: "fallback", title: post.workoutTag, iconName: post.mediaIconName, subtitle: post.workoutStats))
                    .ignoresSafeArea()
            }

            // Top Overlay: Dismiss & Music Soundtrack Indicator
            VStack {
                HStack(alignment: .center, spacing: 12) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 40, height: 40)
                            .background(Color.black.opacity(0.45))
                            .clipShape(Circle())
                    }

                    if let audio = post.audioTrack {
                        HStack(spacing: 6) {
                            Image(systemName: audio.platform.iconName)
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(audio.platform.brandColor)

                            EqualizerAnimationView()
                                .frame(width: 12, height: 10)
                                .foregroundColor(AppTheme.primary)

                            Text("\(audio.title) · \(audio.artist)")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white)
                                .lineLimit(1)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.black.opacity(0.55))
                        .clipShape(Capsule())
                    }

                    Spacer()

                    // Photo Carousel Index Indicator (e.g. 1/3)
                    if post.mediaItems.count > 1 {
                        Text("\(currentSlideIndex + 1)/\(post.mediaItems.count)")
                            .font(.system(size: 12, weight: .black, design: .monospaced))
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.black.opacity(0.6))
                            .clipShape(Capsule())
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 50)

                Spacer()
            }

            // Bottom & Right Controls Overlay
            VStack {
                Spacer()

                HStack(alignment: .bottom, spacing: 16) {
                    // Left Column: Author, Workout Tag, Caption & Carousel Dots
                    VStack(alignment: .leading, spacing: 8) {
                        // Multi-photo Dots indicator
                        if post.mediaItems.count > 1 {
                            HStack(spacing: 5) {
                                ForEach(0..<post.mediaItems.count, id: \.self) { dotIdx in
                                    Capsule()
                                        .fill(dotIdx == currentSlideIndex ? AppTheme.primary : Color.white.opacity(0.4))
                                        .frame(width: dotIdx == currentSlideIndex ? 18 : 5, height: 5)
                                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentSlideIndex)
                                }
                            }
                            .padding(.bottom, 4)
                        }

                        // Author Profile Row
                        HStack(spacing: 8) {
                            Circle()
                                .fill(AppTheme.surfaceRaised)
                                .frame(width: 36, height: 36)
                                .overlay(
                                    Image(systemName: post.athleteType.iconName)
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(post.athleteType.badgeColor)
                                )

                            VStack(alignment: .leading, spacing: 1) {
                                HStack(spacing: 6) {
                                    Text(post.authorName)
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.white)

                                    Text(post.athleteType.rawValue.uppercased())
                                        .font(.system(size: 8, weight: .black))
                                        .padding(.horizontal, 5)
                                        .padding(.vertical, 2)
                                        .background(post.athleteType.badgeColor)
                                        .foregroundColor(.black)
                                        .clipShape(Capsule())
                                }

                                Text("@\(post.authorHandle)")
                                    .font(.system(size: 11))
                                    .foregroundColor(.white.opacity(0.75))
                            }
                        }

                        // Workout Tag
                        Text(post.workoutTag)
                            .font(.system(size: 11, weight: .black))
                            .foregroundColor(AppTheme.primary)
                            .tracking(1)

                        // Caption
                        Text(post.caption)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white)
                            .lineLimit(3)
                    }

                    Spacer()

                    // Right Column: Vertical Actions (Like, Comment, Share)
                    VStack(spacing: 20) {
                        // Like Button
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                post.isLiked.toggle()
                                post.likesCount += post.isLiked ? 1 : -1
                            }
                        } label: {
                            VStack(spacing: 4) {
                                Image(systemName: post.isLiked ? "heart.fill" : "heart")
                                    .font(.system(size: 28, weight: .semibold))
                                    .foregroundColor(post.isLiked ? AppTheme.accent : .white)
                                Text("\(post.likesCount)")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                        .buttonStyle(.plain)

                        // Comment Button
                        Button {
                            showCommentSheet = true
                        } label: {
                            VStack(spacing: 4) {
                                Image(systemName: "bubble.right.fill")
                                    .font(.system(size: 26, weight: .semibold))
                                    .foregroundColor(.white)
                                Text("\(post.comments.count)")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                        .buttonStyle(.plain)

                        // Share Button
                        ShareLink(
                            item: "Check out @\(post.authorHandle)'s workout on Solxce: \(post.caption)"
                        ) {
                            VStack(spacing: 4) {
                                Image(systemName: "square.and.arrow.up.fill")
                                    .font(.system(size: 24, weight: .semibold))
                                    .foregroundColor(.white)
                                Text("Share")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }

            // Double Tap Heart Burst
            if showHeartBurst {
                Image(systemName: "heart.fill")
                    .font(.system(size: 96))
                    .foregroundColor(AppTheme.accent)
                    .scaleEffect(1.2)
                    .transition(.scale.combined(with: .opacity))
            }
        }
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
        .sheet(isPresented: $showCommentSheet) {
            commentsDrawer
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Full Screen Media Canvas
    private func fullScreenMediaCanvas(for item: PostMediaItem) -> some View {
        ZStack {
            LinearGradient(
                colors: item.gradientColors.isEmpty ? post.gradientColors : item.gradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 16) {
                Circle()
                    .fill(post.athleteType.badgeColor.opacity(0.18))
                    .frame(width: 110, height: 110)
                    .overlay(
                        Image(systemName: item.iconName)
                            .font(.system(size: 52, weight: .bold))
                            .foregroundColor(post.athleteType.badgeColor)
                    )

                if let sub = item.subtitle, !sub.isEmpty {
                    Text(sub)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white.opacity(0.9))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(Color.black.opacity(0.5))
                        .clipShape(Capsule())
                }

                if let sticker = post.textOverlay, !sticker.isEmpty {
                    Text(sticker)
                        .font(.system(size: 15, weight: .heavy, design: .rounded))
                        .foregroundColor(AppTheme.primary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(Color.black.opacity(0.75))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
    }

    // MARK: - Comments Drawer Sheet
    private var commentsDrawer: some View {
        NavigationStack {
            VStack(spacing: 0) {
                List {
                    ForEach(post.comments) { comment in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(comment.author)
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(AppTheme.text)
                                Spacer()
                                Text(comment.timeAgo)
                                    .font(.system(size: 11))
                                    .foregroundColor(AppTheme.textMuted)
                            }
                            Text(comment.text)
                                .font(.system(size: 13))
                                .foregroundColor(AppTheme.textSecondary)
                        }
                        .listRowBackground(AppTheme.surface)
                        .padding(.vertical, 4)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)

                // Add Comment Input
                HStack(spacing: 10) {
                    TextField("Add a comment...", text: $newCommentText)
                        .font(AppTheme.bodyFont)
                        .padding(10)
                        .background(AppTheme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 10))

                    Button {
                        guard !newCommentText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                        let comment = PostComment(
                            author: "you",
                            athleteType: post.athleteType,
                            text: newCommentText,
                            timeAgo: "Just now"
                        )
                        onAddComment(comment)
                        newCommentText = ""
                    } label: {
                        Text("Post")
                            .font(AppTheme.headlineFont)
                            .foregroundColor(AppTheme.primary)
                    }
                }
                .padding(16)
                .background(AppTheme.surfaceRaised)
            }
            .background(AppTheme.ground.ignoresSafeArea())
            .navigationTitle("Comments (\(post.comments.count))")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { showCommentSheet = false }
                        .foregroundColor(AppTheme.textSecondary)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
