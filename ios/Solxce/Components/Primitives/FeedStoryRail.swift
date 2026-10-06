// 10x primitive: instagram/story-rail v1
import SwiftUI

/// One tile in the story rail.
@available(iOS 17.0, *)
struct FeedStoryItem: Identifiable {
    var id = UUID()
    var name: String
    var ring: FeedStoryRingState = .unread
    var glyph: String? = nil
}

/// Layout knobs for `FeedStoryRail`.
@available(iOS 17.0, *)
struct FeedStoryRailConfig {
    /// Avatar disc diameter (the ring draws outside it). Observed ~72 pt.
    var avatarSize: CGFloat = 72
    var yourStoryLabel = "Your story"
    /// Show the leading your-story add tile.
    var showsYourStory = true
}

/// The horizontally scrolling rail of story circles at the top of a feed:
/// gradient-ringed unread avatars, quiet gray seen rings, a your-story tile
/// with a blue plus badge, and a caption under every circle.
@available(iOS 17.0, *)
struct FeedStoryRail: View {
    var yourName: String = "You"
    var items: [FeedStoryItem]
    var onAddStory: (() -> Void)? = nil
    var onOpen: ((FeedStoryItem) -> Void)? = nil
    var config = FeedStoryRailConfig()

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: 14) {
                if config.showsYourStory {
                    yourStoryTile
                }
                ForEach(items) { item in
                    Button(action: { onOpen?(item) }) {
                        tile(
                            name: item.name,
                            avatar: FeedAvatar(
                                name: item.name, glyph: item.glyph,
                                size: config.avatarSize, ring: item.ring))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(accessibilityLabel(for: item))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .background(FeedTokens.ground)
    }

    private func accessibilityLabel(for item: FeedStoryItem) -> String {
        switch item.ring {
        case .unread: "\(item.name), new story"
        case .seen: "\(item.name), story seen"
        case .none: item.name
        }
    }

    private var yourStoryTile: some View {
        Button(action: { onAddStory?() }) {
            tile(
                name: config.yourStoryLabel,
                avatar: FeedAvatar(name: yourName, size: config.avatarSize)
                    .overlay(alignment: .bottomTrailing) {
                        ZStack {
                            Circle()
                                .fill(FeedTokens.ground)
                                .frame(width: 24, height: 24)
                            Circle()
                                .fill(FeedTokens.verified)
                                .frame(width: 20, height: 20)
                            Image(systemName: "plus")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(FeedTokens.inkOnAccent)
                        }
                    })
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Add to your story")
    }

    private func tile(name: String, avatar: some View) -> some View {
        VStack(spacing: 5) {
            avatar
            Text(name)
                .font(FeedTokens.metaFont)
                .foregroundStyle(FeedTokens.ink)
                .lineLimit(1)
                .frame(maxWidth: config.avatarSize + 14)
        }
    }
}

#Preview("Story rail") {
    if #available(iOS 17.0, *) {
        FeedStoryRail(
            yourName: "Sam Field",
            items: [
                FeedStoryItem(name: "riverclub", ring: .unread, glyph: "water.waves"),
                FeedStoryItem(name: "ada.park", ring: .unread),
                FeedStoryItem(name: "june.oh", ring: .seen),
                FeedStoryItem(name: "trailmix", ring: .unread, glyph: "leaf"),
                FeedStoryItem(name: "kbotanics", ring: .seen),
            ],
            onAddStory: {}, onOpen: { _ in }
        )
        .background(FeedTokens.ground)
    }
}
