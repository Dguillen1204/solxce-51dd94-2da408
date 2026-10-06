// 10x primitive: instagram/design-tokens v1
import SwiftUI
import UIKit

/// Central design tokens for the social-feed language. The whole theme lives
/// here: retheme by editing these values, add new tokens here, and never
/// hardcode a color, font, or radius in a view.
///
/// Values are observed estimates of the social-feed benchmark: paper-white
/// grounds that flip to true black in dark mode, a near-black/white ink ramp,
/// one committing blue-violet accent doing all follow/send work, the sky-blue
/// verified seal, the like-heart red, the signature story-ring gradient
/// (yellow → magenta → violet), and permanently dark capture/immersive
/// chrome. Media is never photography in this set — `FeedMediaScene` renders
/// neutral gradient scenes with soft glow discs, and `FeedAvatar` renders
/// monogram discs.
///
/// ADAPTIVE: feed surfaces follow the system scheme (white ↔ true black).
/// Capture and immersive-media chrome uses the `camera*` tokens, which are
/// locked dark in both schemes.
@available(iOS 17.0, *)
enum FeedTokens {
    // MARK: Grounds & surfaces

    private static func adaptive(_ light: UIColor, _ dark: UIColor) -> Color {
        Color(UIColor { trait in
            trait.userInterfaceStyle == .dark ? dark : light
        })
    }

    /// The feed, profile, and sheet ground
    static let ground = adaptive(
        UIColor(red: 0.965, green: 0.965, blue: 0.975, alpha: 1.0),
        UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
    )
    /// Sheet and menu surface raised above the ground.
    static let surface = adaptive(
        UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0),
        UIColor(red: 0.07, green: 0.07, blue: 0.07, alpha: 1.0)
    )
    /// Quiet fills: search capsules, secondary buttons, composer fields
    static let field = adaptive(
        UIColor(red: 0.90, green: 0.90, blue: 0.93, alpha: 1.0),
        UIColor(red: 0.14, green: 0.14, blue: 0.14, alpha: 1.0)
    )
    /// Pale-blue wash behind unseen activity rows
    static let unseenWash = adaptive(
        UIColor(red: 0.90, green: 0.94, blue: 1.0, alpha: 1.0),
        UIColor(red: 0.12, green: 0.15, blue: 0.18, alpha: 1.0)
    )

    // MARK: Ink

    /// Usernames, copy, titles
    static let ink = adaptive(
        UIColor(red: 0.07, green: 0.07, blue: 0.08, alpha: 1.0),
        UIColor(red: 0.96, green: 0.96, blue: 0.96, alpha: 1.0)
    )
    /// Timestamps, captions' meta, locations, secondary lines
    static let inkSecondary = adaptive(
        UIColor(red: 0.42, green: 0.42, blue: 0.48, alpha: 1.0),
        UIColor(red: 0.65, green: 0.65, blue: 0.65, alpha: 1.0)
    )
    /// Content sitting on the solid accent
    static let inkOnAccent = Color.black
    /// Hairline separators — ink at 12%.
    static let hairline = adaptive(
        UIColor(white: 0.0, alpha: 0.08),
        UIColor(white: 1.0, alpha: 0.12)
    )

    // MARK: Accent & semantics

    /// The committing volt accent
    static let accent = Color(red: 0.831, green: 1.0, blue: 0.247)
    /// The verified seal
    static let verified = Color(red: 0.831, green: 1.0, blue: 0.247)
    /// The like-heart red #FF3B5C
    static let heart = Color(red: 1.0, green: 0.231, blue: 0.361)
    /// Destructive glyphs
    static let destructive = Color(red: 1.0, green: 0.231, blue: 0.361)

    // MARK: Story ring

    /// The story-ring gradient stops — warm yellow through magenta to violet
    /// (observed estimates ~`#F9CE34`, `#EE2A7B`, `#6228D7`). The ring is the
    /// set's one loud ornament; everything else stays monochrome.
    static let storyRingColors: [Color] = [
        Color(red: 0.976, green: 0.808, blue: 0.204),
        Color(red: 0.933, green: 0.165, blue: 0.482),
        Color(red: 0.384, green: 0.157, blue: 0.843),
    ]
    /// The unread story ring, drawn as an angular sweep.
    static let storyRingGradient = AngularGradient(
        colors: storyRingColors + [storyRingColors[0]],
        center: .center,
        angle: .degrees(-90))
    /// The seen-story ring — a quiet hairline gray.
    static let storyRingSeen = adaptive(
        UIColor(red: 0.78, green: 0.78, blue: 0.78, alpha: 1),
        UIColor(red: 0.33, green: 0.33, blue: 0.33, alpha: 1))

    // MARK: Capture / immersive chrome (locked dark)

    /// Capture and immersive-media ground — true black in both schemes.
    static let cameraGround = Color.black
    /// Chrome glyphs and copy over media — white.
    static let onMedia = Color.white
    /// Dimmed chrome copy over media — white at 60%.
    static let onMediaSecondary = Color.white.opacity(0.6)
    /// Translucent pills over media (mode strips, count badges).
    static let mediaScrim = Color.black.opacity(0.35)

    // MARK: Radii

    /// Buttons — Follow, Edit profile, Message (rounded rects, not capsules).
    static let radiusButton: CGFloat = 10
    /// Cards and larger tiles.
    static let radiusCard: CGFloat = 12
    /// Sheets and floating panels.
    static let radiusSheet: CGFloat = 18
    /// Small media thumbnails in rows.
    static let radiusThumb: CGFloat = 6
    // Search fields, composer fields, and count badges are capsules.

    // MARK: Type

    /// Usernames and row names — subheadline semibold.
    static let nameFont: Font = .system(.subheadline, design: .default, weight: .semibold)
    /// Captions, comments, bios — subheadline regular.
    static let bodyFont: Font = .system(.subheadline, design: .default)
    /// Timestamps, locations, counts' captions — footnote regular.
    static let metaFont: Font = .system(.caption, design: .default)
    /// Sheet titles and screen titles — headline semibold.
    static let titleFont: Font = .system(.headline, design: .default, weight: .semibold)
    /// Stat numbers — headline bold, tabular so counts never jitter.
    static let statFont: Font = .system(.headline, design: .default, weight: .bold).monospacedDigit()
    /// Inline engagement counts — footnote semibold, tabular.
    static let countFont: Font = .system(.footnote, design: .default, weight: .semibold).monospacedDigit()
    /// Button labels — subheadline semibold.
    static let buttonFont: Font = .system(.subheadline, design: .default, weight: .semibold)

    // MARK: Monogram palette

    /// Deterministic pastel fill for a monogram avatar — the set's universal
    /// stand-in for profile photography, which it never renders.
    static func monogramColor(for name: String) -> Color {
        let palette: [Color] = [
            Color(red: 0.72, green: 0.84, blue: 0.95),
            Color(red: 0.93, green: 0.78, blue: 0.86),
            Color(red: 0.80, green: 0.77, blue: 0.94),
            Color(red: 0.95, green: 0.85, blue: 0.70),
            Color(red: 0.76, green: 0.89, blue: 0.80),
            Color(red: 0.94, green: 0.80, blue: 0.75),
        ]
        let index = abs(name.unicodeScalars.reduce(0) { $0 &* 31 &+ Int($1.value) })
        return palette[index % palette.count]
    }

    /// Two deterministic scene hues for `FeedMediaScene` — muted, adjacent
    /// pairs so placeholder media reads calm, never brand-loud.
    static func sceneColors(for seed: String) -> (Color, Color) {
        let pairs: [(Color, Color)] = [
            (Color(red: 0.55, green: 0.65, blue: 0.78), Color(red: 0.76, green: 0.83, blue: 0.90)),
            (Color(red: 0.72, green: 0.60, blue: 0.72), Color(red: 0.88, green: 0.78, blue: 0.82)),
            (Color(red: 0.58, green: 0.70, blue: 0.64), Color(red: 0.80, green: 0.88, blue: 0.79)),
            (Color(red: 0.78, green: 0.68, blue: 0.55), Color(red: 0.92, green: 0.85, blue: 0.72)),
            (Color(red: 0.52, green: 0.58, blue: 0.72), Color(red: 0.70, green: 0.72, blue: 0.86)),
            (Color(red: 0.70, green: 0.56, blue: 0.52), Color(red: 0.88, green: 0.76, blue: 0.68)),
        ]
        let index = abs(seed.unicodeScalars.reduce(0) { $0 &* 31 &+ Int($1.value) })
        return pairs[index % pairs.count]
    }
}

/// Abbreviated engagement-count formatting shared across the set: full
/// grouped digits under 10 000 ("2,519"), tenths-K to under a million
/// ("15.9K"), tenths-M beyond ("31.9M") — matching the observed action-bar
/// and stat-trio treatment.
@available(iOS 17.0, *)
enum FeedCount {
    static func abbreviated(_ value: Int) -> String {
        let number = abs(value)
        let sign = value < 0 ? "-" : ""
        switch number {
        case ..<10_000:
            return sign + number.formatted(.number.grouping(.automatic))
        case ..<1_000_000:
            return sign + trimmed(Double(number) / 1_000) + "K"
        default:
            return sign + trimmed(Double(number) / 1_000_000) + "M"
        }
    }

    private static func trimmed(_ value: Double) -> String {
        let tenths = (value * 10).rounded() / 10
        return tenths == tenths.rounded()
            ? String(Int(tenths))
            : String(format: "%.1f", tenths)
    }
}

/// Ring treatment around an avatar — the set's presence vocabulary.
@available(iOS 17.0, *)
enum FeedStoryRingState {
    /// No ring — plain avatar.
    case none
    /// The gradient ring: this account has an unseen story.
    case unread
    /// The quiet gray ring: story seen.
    case seen
}

/// Neutral monogram avatar — the set's universal stand-in for profile
/// photography: a pastel disc carrying initials or a quiet glyph, with an
/// optional story ring drawn outside the disc.
@available(iOS 17.0, *)
struct FeedAvatar: View {
    var name: String
    var glyph: String? = nil
    var size: CGFloat = 44
    var ring: FeedStoryRingState = .none

    var body: some View {
        ZStack {
            disc
            switch ring {
            case .none:
                EmptyView()
            case .unread:
                Circle()
                    .strokeBorder(FeedTokens.storyRingGradient, lineWidth: ringWidth)
                    .frame(width: ringDiameter, height: ringDiameter)
            case .seen:
                Circle()
                    .strokeBorder(FeedTokens.storyRingSeen, lineWidth: 1)
                    .frame(width: ringDiameter, height: ringDiameter)
            }
        }
        .frame(width: ringDiameter, height: ringDiameter)
        .accessibilityHidden(true)
    }

    private var ringWidth: CGFloat { max(2, size * 0.045) }
    private var ringDiameter: CGFloat { ring == .none ? size : size + ringWidth * 2 + 4 }

    private var disc: some View {
        ZStack {
            Circle().fill(FeedTokens.monogramColor(for: name))
            if let glyph {
                Image(systemName: glyph)
                    .font(.system(size: size * 0.4, weight: .medium))
                    .foregroundStyle(FeedTokens.ink.opacity(0.55))
            } else {
                Text(initials)
                    .font(.system(size: size * 0.36, weight: .semibold, design: .rounded))
                    .foregroundStyle(FeedTokens.ink.opacity(0.6))
            }
        }
        .frame(width: size, height: size)
    }

    private var initials: String {
        let parts = name.split(separator: " ").prefix(2)
        return parts.map { String($0.prefix(1)) }.joined().uppercased()
    }
}

/// Neutral gradient media scene — the set's stand-in for post, story, and
/// grid photography: a deterministic two-hue gradient with soft glow discs.
/// Hosts replace it with real media; the set itself never ships imagery.
@available(iOS 17.0, *)
struct FeedMediaScene: View {
    var seed: String
    var glyph: String? = nil

    var body: some View {
        GeometryReader { proxy in
            let colors = FeedTokens.sceneColors(for: seed)
            let side = min(proxy.size.width, proxy.size.height)
            ZStack {
                LinearGradient(
                    colors: [colors.0, colors.1],
                    startPoint: .topLeading, endPoint: .bottomTrailing)
                Circle()
                    .fill(Color.white.opacity(0.35))
                    .frame(width: side * 0.55)
                    .blur(radius: side * 0.12)
                    .offset(x: -side * 0.2, y: -side * 0.18)
                Circle()
                    .fill(colors.0.opacity(0.5))
                    .frame(width: side * 0.4)
                    .blur(radius: side * 0.1)
                    .offset(x: side * 0.25, y: side * 0.22)
                if let glyph {
                    Image(systemName: glyph)
                        .font(.system(size: side * 0.16, weight: .light))
                        .foregroundStyle(Color.white.opacity(0.7))
                }
            }
        }
        .clipped()
        .accessibilityHidden(true)
    }
}

/// The blue verified seal beside a username. Decorative by default; rows
/// carry "Verified" in their own accessibility labels.
@available(iOS 17.0, *)
struct FeedVerifiedBadge: View {
    var size: CGFloat = 12

    var body: some View {
        Image(systemName: "checkmark.seal.fill")
            .font(.system(size: size, weight: .semibold))
            .foregroundStyle(FeedTokens.verified)
            .accessibilityHidden(true)
    }
}

/// Follow-relationship states shared across rows, headers, and activity —
/// the set's core social vocabulary. State is encoded by fill *and* label,
/// never color alone.
@available(iOS 17.0, *)
enum FeedFollowState {
    case follow
    case followBack
    case following

    var label: String {
        switch self {
        case .follow: "Follow"
        case .followBack: "Follow back"
        case .following: "Following"
        }
    }

    var isCommitted: Bool { self == .following }
}

/// The follow button in its observed states: solid accent while an invitation
/// (Follow / Follow back), quiet field fill once committed (Following).
@available(iOS 17.0, *)
struct FeedFollowButton: View {
    var state: FeedFollowState
    var onTap: () -> Void
    /// Fixed width keeps ragged rows aligned in lists; nil hugs the label.
    var width: CGFloat? = nil

    var body: some View {
        Button(action: onTap) {
            Text(state.label)
                .font(FeedTokens.buttonFont)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .foregroundStyle(state.isCommitted ? FeedTokens.ink : FeedTokens.inkOnAccent)
                .frame(width: width)
                .padding(.horizontal, width == nil ? 16 : 0)
                .frame(minHeight: 32)
                .background(
                    state.isCommitted ? FeedTokens.field : FeedTokens.accent,
                    in: .rect(cornerRadius: FeedTokens.radiusButton))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(state.label)
        .accessibilityAddTraits(state.isCommitted ? [.isSelected] : [])
    }
}

#Preview("Token swatches") {
    if #available(iOS 17.0, *) {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text("instagram tokens")
                    .font(FeedTokens.titleFont)
                    .foregroundStyle(FeedTokens.ink)
                ForEach(
                    [
                        ("ground", FeedTokens.ground),
                        ("surface", FeedTokens.surface),
                        ("field", FeedTokens.field),
                        ("unseenWash", FeedTokens.unseenWash),
                        ("ink", FeedTokens.ink),
                        ("inkSecondary", FeedTokens.inkSecondary),
                        ("accent", FeedTokens.accent),
                        ("verified", FeedTokens.verified),
                        ("heart", FeedTokens.heart),
                        ("destructive", FeedTokens.destructive),
                        ("storyRingSeen", FeedTokens.storyRingSeen),
                        ("cameraGround", FeedTokens.cameraGround),
                    ],
                    id: \.0
                ) { name, color in
                    HStack(spacing: 12) {
                        RoundedRectangle(cornerRadius: FeedTokens.radiusCard)
                            .fill(color)
                            .frame(width: 44, height: 32)
                            .overlay {
                                RoundedRectangle(cornerRadius: FeedTokens.radiusCard)
                                    .strokeBorder(FeedTokens.hairline)
                            }
                        Text(name)
                            .font(FeedTokens.bodyFont)
                            .foregroundStyle(FeedTokens.ink)
                    }
                }
                HStack(spacing: 14) {
                    FeedAvatar(name: "Ada Park", ring: .unread)
                    FeedAvatar(name: "Juno Lee", ring: .seen)
                    FeedAvatar(name: "Trail Club", glyph: "person.2.fill")
                }
                HStack(spacing: 10) {
                    FeedFollowButton(state: .follow, onTap: {}, width: 96)
                    FeedFollowButton(state: .following, onTap: {}, width: 96)
                }
                Text(
                    [1_476, 15_900, 2_519, 31_900_000]
                        .map(FeedCount.abbreviated).joined(separator: "  ·  "))
                    .font(FeedTokens.countFont)
                    .foregroundStyle(FeedTokens.inkSecondary)
                FeedMediaScene(seed: "beach-day", glyph: "camera")
                    .frame(height: 120)
                    .clipShape(.rect(cornerRadius: FeedTokens.radiusCard))
            }
            .padding(20)
        }
        .background(FeedTokens.ground)
    }
}
