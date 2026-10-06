// 10x primitive: instagram/comments-sheet v1
import SwiftUI

/// One comment in the sheet. Replies are the same shape rendered indented.
@available(iOS 17.0, *)
struct FeedComment: Identifiable {
    var id = UUID()
    var name: String
    var time: String
    var body: String
    var likeCount: Int = 0
    var isLiked = false
    var isAuthor = false
    /// Non-zero renders a "View N more replies" affordance below the row.
    var hiddenReplyCount: Int = 0
    var replies: [FeedComment] = []
}

/// Labels and layout knobs for `FeedCommentsSheet`.
@available(iOS 17.0, *)
struct FeedCommentsSheetConfig {
    var title = "Comments"
    var composerPlaceholder = "Add a comment…"
    var replyLabel = "Reply"
    var authorLabel = "Author"
    var moreRepliesFormat = "View %d more replies"
    /// Quick reactions above the composer; empty hides the row.
    var quickEmoji = ["❤️", "🙌", "🔥", "👏", "😢", "😍", "😮", "😂"]
    /// Indent applied to reply rows.
    var replyIndent: CGFloat = 44
}

/// The comments bottom sheet: grabber and centered title over a hairline,
/// comment rows (avatar, name + time, body, reply link, trailing heart with
/// a count beneath), indented reply threads with view-more affordances, a
/// quick-emoji row, and an avatar + capsule-field composer at the foot.
@available(iOS 17.0, *)
struct FeedCommentsSheet: View {
    var comments: [FeedComment]
    var composerName: String = "You"
    @Binding var draft: String
    var onSend: (() -> Void)? = nil
    var onLike: ((FeedComment) -> Void)? = nil
    var onReply: ((FeedComment) -> Void)? = nil
    var onMoreReplies: ((FeedComment) -> Void)? = nil
    var onQuickEmoji: ((String) -> Void)? = nil
    var config = FeedCommentsSheetConfig()

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 18) {
                    ForEach(comments) { comment in
                        commentThread(comment)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 16)
            }
            footer
        }
        .background(FeedTokens.surface)
        .clipShape(.rect(topLeadingRadius: FeedTokens.radiusSheet,
                         topTrailingRadius: FeedTokens.radiusSheet))
    }

    // MARK: Header

    private var header: some View {
        VStack(spacing: 10) {
            Capsule()
                .fill(FeedTokens.hairline)
                .frame(width: 36, height: 4)
                .padding(.top, 8)
            Text(config.title)
                .font(FeedTokens.titleFont)
                .foregroundStyle(FeedTokens.ink)
                .accessibilityAddTraits(.isHeader)
            Rectangle()
                .fill(FeedTokens.hairline)
                .frame(height: 0.5)
        }
    }

    // MARK: Rows

    private func commentThread(_ comment: FeedComment) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            commentRow(comment, isReply: false)
            ForEach(comment.replies) { reply in
                commentRow(reply, isReply: true)
            }
            if comment.hiddenReplyCount > 0 {
                Button(action: { onMoreReplies?(comment) }) {
                    HStack(spacing: 8) {
                        Rectangle()
                            .fill(FeedTokens.hairline)
                            .frame(width: 24, height: 0.5)
                        Text(String(format: config.moreRepliesFormat, comment.hiddenReplyCount))
                            .font(FeedTokens.metaFont)
                            .foregroundStyle(FeedTokens.inkSecondary)
                    }
                }
                .buttonStyle(.plain)
                .padding(.leading, config.replyIndent)
            }
        }
    }

    private func commentRow(_ comment: FeedComment, isReply: Bool) -> some View {
        HStack(alignment: .top, spacing: 10) {
            FeedAvatar(name: comment.name, size: isReply ? 28 : 34)
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 4) {
                    Text(comment.name)
                        .font(FeedTokens.nameFont)
                        .foregroundStyle(FeedTokens.ink)
                    Text(comment.time)
                        .font(FeedTokens.metaFont)
                        .foregroundStyle(FeedTokens.inkSecondary)
                    if comment.isAuthor {
                        Text(config.authorLabel)
                            .font(FeedTokens.metaFont)
                            .foregroundStyle(FeedTokens.inkSecondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 1)
                            .background(FeedTokens.field, in: .capsule)
                    }
                }
                Text(comment.body)
                    .font(FeedTokens.bodyFont)
                    .foregroundStyle(FeedTokens.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Button(action: { onReply?(comment) }) {
                    Text(config.replyLabel)
                        .font(FeedTokens.countFont)
                        .foregroundStyle(FeedTokens.inkSecondary)
                }
                .buttonStyle(.plain)
            }
            Spacer(minLength: 8)
            Button(action: { onLike?(comment) }) {
                VStack(spacing: 2) {
                    Image(systemName: comment.isLiked ? "heart.fill" : "heart")
                        .font(.system(size: 13))
                        .foregroundStyle(
                            comment.isLiked ? FeedTokens.heart : FeedTokens.inkSecondary)
                    if comment.likeCount > 0 {
                        Text(FeedCount.abbreviated(comment.likeCount))
                            .font(FeedTokens.metaFont)
                            .foregroundStyle(FeedTokens.inkSecondary)
                    }
                }
                .frame(minWidth: 32, minHeight: 32)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(likeAccessibilityLabel(comment))
        }
        .padding(.leading, isReply ? config.replyIndent : 0)
    }

    private func likeAccessibilityLabel(_ comment: FeedComment) -> String {
        let state = comment.isLiked ? "Unlike" : "Like"
        return comment.likeCount > 0
            ? "\(state) comment by \(comment.name), \(comment.likeCount) likes"
            : "\(state) comment by \(comment.name)"
    }

    // MARK: Footer

    private var footer: some View {
        VStack(spacing: 10) {
            Rectangle()
                .fill(FeedTokens.hairline)
                .frame(height: 0.5)
            if !config.quickEmoji.isEmpty {
                HStack(spacing: 0) {
                    ForEach(config.quickEmoji, id: \.self) { emoji in
                        Button(action: { onQuickEmoji?(emoji) }) {
                            Text(emoji)
                                .font(.system(size: 24))
                                .frame(maxWidth: .infinity, minHeight: 34)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("React \(emoji)")
                    }
                }
                .padding(.horizontal, 8)
            }
            HStack(spacing: 10) {
                FeedAvatar(name: composerName, size: 36)
                TextField(config.composerPlaceholder, text: $draft, axis: .vertical)
                    .font(FeedTokens.bodyFont)
                    .foregroundStyle(FeedTokens.ink)
                    .lineLimit(1...4)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 9)
                    .background(FeedTokens.field, in: .rect(cornerRadius: 20))
                    .onSubmit { submit() }
                if !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Button(action: submit) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 30))
                            .foregroundStyle(FeedTokens.accent)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Post comment")
                }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
        }
    }

    private func submit() {
        guard !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        onSend?()
    }
}

#Preview("Comments sheet") {
    if #available(iOS 17.0, *) {
        struct Host: View {
            @State private var draft = ""
            var body: some View {
                FeedCommentsSheet(
                    comments: [
                        FeedComment(
                            name: "ada.park", time: "1d",
                            body: "This is such a calm spot — adding it to the list.",
                            likeCount: 160,
                            hiddenReplyCount: 4,
                            replies: [
                                FeedComment(
                                    name: "juno.lee", time: "1d",
                                    body: "It really is. Go at sunrise.",
                                    likeCount: 96, isAuthor: true),
                            ]),
                        FeedComment(
                            name: "trailmix", time: "19h",
                            body: "Perfect light.", likeCount: 38, isLiked: true),
                    ],
                    composerName: "Sam Field",
                    draft: $draft,
                    onSend: { draft = "" },
                    onLike: { _ in }, onReply: { _ in },
                    onMoreReplies: { _ in }, onQuickEmoji: { _ in }
                )
            }
        }
        return AnyView(
            Host()
                .frame(maxHeight: .infinity, alignment: .bottom)
                .background(FeedTokens.mediaScrim))
    }
    return AnyView(EmptyView())
}
