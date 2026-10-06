// 10x primitive: instagram/profile-grid v1
import SwiftUI

/// Media-type marker in a grid tile's top-trailing corner.
@available(iOS 17.0, *)
enum FeedGridBadge {
    case none
    /// Multi-page post — the stacked-squares glyph.
    case carousel
    /// Video/reel — the play glyph.
    case reel
    /// Pinned to the top of the grid.
    case pinned

    var systemName: String? {
        switch self {
        case .none: nil
        case .carousel: "square.on.square.fill"
        case .reel: "play.fill"
        case .pinned: "pin.fill"
        }
    }

    var accessibilityLabel: String? {
        switch self {
        case .none: nil
        case .carousel: "Multiple photos"
        case .reel: "Video"
        case .pinned: "Pinned"
        }
    }
}

/// One tile in the grid.
@available(iOS 17.0, *)
struct FeedGridItem: Identifiable {
    var id: UUID = UUID()
    /// Post ID for navigation / selection mapping
    var postID: UUID? = nil
    /// Seed for the neutral gradient scene standing in for media.
    var seed: String
    var badge: FeedGridBadge = .none
    /// Shown bottom-leading with an eye glyph (reels tab treatment).
    var viewCount: Int? = nil
    var accessibilityLabel: String? = nil
    /// Dynamic styling colors / icon if available
    var iconName: String? = nil
    var gradientColors: [Color]? = nil
    var textOverlay: String? = nil
}

/// Layout knobs for `FeedProfileGrid`.
@available(iOS 17.0, *)
struct FeedProfileGridConfig {
    /// Tile aspect (width / height): 1 for the posts grid, 3/4-ish for reels.
    var tileAspect: CGFloat = 1
    /// Gutter between tiles — observed near-hairline.
    var spacing: CGFloat = 1.5
    var columns: Int = 3
}

/// The profile's three-column media grid: near-hairline gutters, square
/// gradient-scene tiles, white type badges (carousel stack, reel play, pin)
/// in the top-trailing corner, and an optional eye + view-count overlay on
/// reel tiles.
@available(iOS 17.0, *)
struct FeedProfileGrid: View {
    var items: [FeedGridItem]
    var onSelect: ((FeedGridItem) -> Void)? = nil
    var config = FeedProfileGridConfig()

    var body: some View {
        LazyVGrid(
            columns: Array(
                repeating: GridItem(.flexible(), spacing: config.spacing),
                count: max(1, config.columns)),
            spacing: config.spacing
        ) {
            ForEach(items) { item in
                Button(action: { onSelect?(item) }) {
                    tile(item)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(label(for: item))
            }
        }
        .background(FeedTokens.ground)
    }

    private func label(for item: FeedGridItem) -> String {
        var parts = [item.accessibilityLabel ?? "Post"]
        if let badge = item.badge.accessibilityLabel { parts.append(badge) }
        if let views = item.viewCount {
            parts.append("\(FeedCount.abbreviated(views)) views")
        }
        return parts.joined(separator: ", ")
    }

    private func tile(_ item: FeedGridItem) -> some View {
        ZStack {
            if let colors = item.gradientColors, colors.count >= 2 {
                LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
            } else {
                FeedMediaScene(seed: item.seed)
            }

            if let icon = item.iconName {
                Image(systemName: icon)
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.85))
                    .shadow(color: .black.opacity(0.4), radius: 3)
            }

            if let text = item.textOverlay, !text.isEmpty {
                VStack {
                    Spacer()
                    Text(text)
                        .font(.system(size: 9, weight: .black))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(Color.black.opacity(0.65))
                        .clipShape(RoundedRectangle(cornerRadius: 3))
                        .lineLimit(1)
                        .padding(.bottom, item.viewCount != nil ? 22 : 6)
                        .padding(.horizontal, 4)
                }
            }
        }
        .aspectRatio(config.tileAspect, contentMode: .fit)
        .overlay(alignment: .topTrailing) {
            if let glyph = item.badge.systemName {
                Image(systemName: glyph)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.35), radius: 2, y: 1)
                    .padding(6)
            }
        }
        .overlay(alignment: .bottomLeading) {
            if let views = item.viewCount {
                HStack(spacing: 3) {
                    Image(systemName: "eye.fill")
                        .font(.system(size: 10, weight: .semibold))
                    Text(FeedCount.abbreviated(views))
                        .font(FeedTokens.metaFont.weight(.semibold))
                }
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.35), radius: 2, y: 1)
                .padding(6)
            }
        }
        .contentShape(.rect)
    }
}

#Preview("Profile grid") {
    if #available(iOS 17.0, *) {
        ScrollView {
            FeedProfileGrid(
                items: [
                    FeedGridItem(seed: "surf", badge: .pinned),
                    FeedGridItem(seed: "dune", badge: .carousel),
                    FeedGridItem(seed: "pines", badge: .reel, viewCount: 11_800),
                    FeedGridItem(seed: "harbor"),
                    FeedGridItem(seed: "ridge", badge: .carousel),
                    FeedGridItem(seed: "tidepool", badge: .reel, viewCount: 940),
                ],
                onSelect: { _ in }
            )
        }
        .background(FeedTokens.ground)
    }
}
