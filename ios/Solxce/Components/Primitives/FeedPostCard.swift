// 10x primitive: instagram/post-card v1
import SwiftUI

/// Reaction chip line data used in the action bar when inline counts are on.
@available(iOS 17.0, *)
struct FeedPostCounts {
    var likes: Int = 0
    var comments: Int = 0
    var reposts: Int = 0
    var shares: Int = 0
}

/// Layout knobs for `FeedPostCard`. Defaults match observed values; override
/// sparingly and keep changes theme-wide.
@available(iOS 17.0, *)
struct FeedPostCardConfig {
    /// Media aspect ratio (width / height). Observed feeds mix 1:1 and 4:5.
    var mediaAspect: CGFloat = 4.0 / 5.0
    /// Show counts inline beside the action glyphs (the observed alternate
    /// treatment) instead of a bold likes line below.
    var inlineCounts = false
    /// Localized labels.
    var likesSuffix = "likes"
    var moreLabel = "more"
    var viewCommentsFormat = "View all %d comments"
}

/// The feed's atom: author header row, an edge-to-edge media slot, the
/// like/comment/repost/share action bar with a trailing save, then likes,
/// caption, comments-teaser, and timestamp lines. Media is a neutral gradient
/// scene by default — hosts pass real media through `media`.
@available(iOS 17.0, *)
struct FeedPostCard<Media: View>: View {
    var authorName: String
    var subtitle: String? = nil
    var isVerified = false
    var ring: FeedStoryRingState = .none
    var counts = FeedPostCounts()
    var caption: String? = nil
    var timeLabel: String? = nil
    var pageCount: Int = 1
    var pageIndex: Int = 0
    var isLiked = false
    var isSaved = false
    var onLike: (() -> Void)? = nil
    var onComment: (() -> Void)? = nil
    var onRepost: (() -> Void)? = nil
    var onShare: (() -> Void)? = nil
    var onSave: (() -> Void)? = nil
    var onMore: (() -> Void)? = nil
    var config = FeedPostCardConfig()
    @ViewBuilder var media: Media

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            mediaSlot
            actionBar
            captionBlock
        }
        .background(FeedTokens.ground)
    }

    init(
        authorName: String,
        subtitle: String? = nil,
        isVerified: Bool = false,
        ring: FeedStoryRingState = .none,
        counts: FeedPostCounts = FeedPostCounts(),
        caption: String? = nil,
        timeLabel: String? = nil,
        pageCount: Int = 1,
        pageIndex: Int = 0,
        isLiked: Bool = false,
        isSaved: Bool = false,
        onLike: (() -> Void)? = nil,
        onComment: (() -> Void)? = nil,
        onRepost: (() -> Void)? = nil,
        onShare: (() -> Void)? = nil,
        onSave: (() -> Void)? = nil,
        onMore: (() -> Void)? = nil,
        config: FeedPostCardConfig = FeedPostCardConfig(),
        @ViewBuilder media: () -> Media
    ) {
        self.authorName = authorName
        self.subtitle = subtitle
        self.isVerified = isVerified
        self.ring = ring
        self.counts = counts
        self.caption = caption
        self.timeLabel = timeLabel
        self.pageCount = pageCount
        self.pageIndex = pageIndex
        self.isLiked = isLiked
        self.isSaved = isSaved
        self.onLike = onLike
        self.onComment = onComment
        self.onRepost = onRepost
        self.onShare = onShare
        self.onSave = onSave
        self.onMore = onMore
        self.config = config
        self.media = media()
    }

    // MARK: Header

    private var header: some View {
        HStack(spacing: 10) {
            FeedAvatar(name: authorName, size: 32, ring: ring)
            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 4) {
                    Text(authorName)
                        .font(FeedTokens.nameFont)
                        .foregroundStyle(FeedTokens.ink)
                        .lineLimit(1)
                    if isVerified { FeedVerifiedBadge() }
                }
                if let subtitle {
                    Text(subtitle)
                        .font(FeedTokens.metaFont)
                        .foregroundStyle(FeedTokens.inkSecondary)
                        .lineLimit(1)
                }
            }
            Spacer(minLength: 8)
            if let onMore {
                Button(action: onMore) {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(FeedTokens.ink)
                        .frame(width: 40, height: 40)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("More options")
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(headerAccessibilityLabel)
    }

    private var headerAccessibilityLabel: String {
        var parts = [authorName]
        if isVerified { parts.append("Verified") }
        if let subtitle { parts.append(subtitle) }
        if ring == .unread { parts.append("Has a new story") }
        return parts.joined(separator: ", ")
    }

    // MARK: Media

    private var mediaSlot: some View {
        media
            .aspectRatio(config.mediaAspect, contentMode: .fill)
            .frame(maxWidth: .infinity)
            .clipped()
            .overlay(alignment: .topTrailing) {
                if pageCount > 1 {
                    Text("\(pageIndex + 1)/\(pageCount)")
                        .font(FeedTokens.countFont)
                        .foregroundStyle(FeedTokens.onMedia)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(FeedTokens.mediaScrim, in: .capsule)
                        .padding(10)
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(
                pageCount > 1
                    ? "Post media, page \(pageIndex + 1) of \(pageCount)"
                    : "Post media")
    }

    // MARK: Action bar

    private var actionBar: some View {
        VStack(spacing: 6) {
            HStack(spacing: config.inlineCounts ? 4 : 14) {
                actionGlyph(
                    isLiked ? "heart.fill" : "heart",
                    tint: isLiked ? FeedTokens.heart : FeedTokens.ink,
                    label: isLiked ? "Unlike" : "Like",
                    count: counts.likes,
                    action: onLike)
                actionGlyph(
                    "bubble.right", tint: FeedTokens.ink, label: "Comments",
                    count: counts.comments, action: onComment)
                actionGlyph(
                    "arrow.2.squarepath", tint: FeedTokens.ink, label: "Repost",
                    count: counts.reposts, action: onRepost)
                actionGlyph(
                    "paperplane", tint: FeedTokens.ink, label: "Share",
                    count: counts.shares, action: onShare)
                Spacer(minLength: 0)
                if pageCount > 1 { pageDots }
                Spacer(minLength: 0)
                Button(action: { onSave?() }) {
                    Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                        .font(.system(size: 19, weight: .regular))
                        .foregroundStyle(FeedTokens.ink)
                        .frame(width: 40, height: 40)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(isSaved ? "Remove from saved" : "Save")
            }
        }
        .padding(.horizontal, 8)
        .padding(.top, 2)
    }

    private func actionGlyph(
        _ systemName: String, tint: Color, label: String, count: Int,
        action: (() -> Void)?
    ) -> some View {
        Button(action: { action?() }) {
            HStack(spacing: 4) {
                Image(systemName: systemName)
                    .font(.system(size: 19, weight: .regular))
                    .foregroundStyle(tint)
                if config.inlineCounts, count > 0 {
                    Text(FeedCount.abbreviated(count))
                        .font(FeedTokens.countFont)
                        .foregroundStyle(FeedTokens.ink)
                }
            }
            .frame(minWidth: 40, minHeight: 40)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(
            count > 0 ? "\(label), \(FeedCount.abbreviated(count))" : label)
    }

    private var pageDots: some View {
        HStack(spacing: 4) {
            ForEach(0..<min(pageCount, 5), id: \.self) { index in
                Circle()
                    .fill(index == pageIndex ? FeedTokens.verified : FeedTokens.hairline)
                    .frame(width: index == pageIndex ? 6 : 5,
                           height: index == pageIndex ? 6 : 5)
            }
        }
        .accessibilityHidden(true)
    }

    // MARK: Caption block

    private var captionBlock: some View {
        VStack(alignment: .leading, spacing: 4) {
            if !config.inlineCounts, counts.likes > 0 {
                Text("\(FeedCount.abbreviated(counts.likes)) \(config.likesSuffix)")
                    .font(FeedTokens.nameFont)
                    .foregroundStyle(FeedTokens.ink)
            }
            if let caption {
                (Text(authorName).font(FeedTokens.nameFont).foregroundStyle(FeedTokens.ink)
                    + Text(" ")
                    + Text(caption).font(FeedTokens.bodyFont).foregroundStyle(FeedTokens.ink)
                    + Text(caption.count > 90 ? " \(config.moreLabel)" : "")
                        .font(FeedTokens.bodyFont)
                        .foregroundStyle(FeedTokens.inkSecondary))
                    .lineLimit(2)
            }
            if !config.inlineCounts, counts.comments > 0, let onComment {
                Button(action: onComment) {
                    Text(String(format: config.viewCommentsFormat, counts.comments))
                        .font(FeedTokens.bodyFont)
                        .foregroundStyle(FeedTokens.inkSecondary)
                }
                .buttonStyle(.plain)
            }
            if let timeLabel {
                Text(timeLabel)
                    .font(FeedTokens.metaFont)
                    .foregroundStyle(FeedTokens.inkSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.top, 4)
        .padding(.bottom, 12)
    }
}

#Preview("Post card") {
    if #available(iOS 17.0, *) {
        ScrollView {
            FeedPostCard(
                authorName: "juno.lee",
                subtitle: "Gull Point, North Shore",
                isVerified: true,
                ring: .unread,
                counts: FeedPostCounts(likes: 2_519, comments: 19, reposts: 12, shares: 259),
                caption: "a slow morning by the water — what's your plan for the weekend?",
                timeLabel: "8 minutes ago",
                pageCount: 3,
                pageIndex: 0,
                isLiked: true,
                onLike: {}, onComment: {}, onRepost: {}, onShare: {},
                onSave: {}, onMore: {}
            ) {
                FeedMediaScene(seed: "gull-point")
            }
        }
        .background(FeedTokens.ground)
    }
}
