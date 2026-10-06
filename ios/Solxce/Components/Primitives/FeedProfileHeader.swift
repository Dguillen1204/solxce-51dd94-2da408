// 10x primitive: instagram/profile-header v1
import SwiftUI

/// One number in the stat trio.
@available(iOS 17.0, *)
struct FeedProfileStat: Identifiable {
    var id = UUID()
    var value: Int
    var label: String
}

/// Whose profile this is — decides the action-button row.
@available(iOS 17.0, *)
enum FeedProfilePosture {
    /// Your own profile: Edit profile / Share profile in the quiet fill.
    case own
    /// Someone else's: a committing follow button plus Message.
    case other(FeedFollowState)
}

/// Labels for `FeedProfileHeader`.
@available(iOS 17.0, *)
struct FeedProfileHeaderConfig {
    var editLabel = "Edit profile"
    var shareLabel = "Share profile"
    var messageLabel = "Message"
}

/// The profile top block: a large avatar (optionally story-ringed) beside the
/// posts/followers/following stat trio, then display name, bio, an accent
/// link line, and the action-button row — Edit/Share on your own profile,
/// Follow/Message plus a discover-people square on someone else's.
@available(iOS 17.0, *)
struct FeedProfileHeader: View {
    var name: String
    var displayName: String? = nil
    var pronouns: String? = nil
    var isVerified = false
    var ring: FeedStoryRingState = .none
    var stats: [FeedProfileStat]
    var bio: String? = nil
    var link: String? = nil
    var posture: FeedProfilePosture = .own
    var onPrimary: (() -> Void)? = nil
    var onSecondary: (() -> Void)? = nil
    var onDiscoverPeople: (() -> Void)? = nil
    var onStat: ((FeedProfileStat) -> Void)? = nil
    var config = FeedProfileHeaderConfig()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 20) {
                FeedAvatar(name: displayName ?? name, size: 86, ring: ring)
                statTrio
            }
            identity
            buttons
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(FeedTokens.ground)
    }

    // MARK: Stats

    private var statTrio: some View {
        HStack(spacing: 0) {
            ForEach(stats) { stat in
                Button(action: { onStat?(stat) }) {
                    VStack(spacing: 1) {
                        Text(FeedCount.abbreviated(stat.value))
                            .font(FeedTokens.statFont)
                            .foregroundStyle(FeedTokens.ink)
                        Text(stat.label)
                            .font(FeedTokens.bodyFont)
                            .foregroundStyle(FeedTokens.ink)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(FeedCount.abbreviated(stat.value)) \(stat.label)")
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: Identity

    @ViewBuilder private var identity: some View {
        VStack(alignment: .leading, spacing: 3) {
            if displayName != nil || pronouns != nil || isVerified {
                HStack(spacing: 5) {
                    Text(displayName ?? name)
                        .font(FeedTokens.nameFont)
                        .foregroundStyle(FeedTokens.ink)
                    if isVerified { FeedVerifiedBadge() }
                    if let pronouns {
                        Text(pronouns)
                            .font(FeedTokens.bodyFont)
                            .foregroundStyle(FeedTokens.inkSecondary)
                    }
                }
                .accessibilityElement(children: .combine)
            }
            if let bio {
                Text(bio)
                    .font(FeedTokens.bodyFont)
                    .foregroundStyle(FeedTokens.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if let link {
                HStack(spacing: 4) {
                    Image(systemName: "link")
                        .font(.system(size: 11, weight: .semibold))
                    Text(link)
                        .font(FeedTokens.nameFont)
                }
                .foregroundStyle(FeedTokens.verified)
                .accessibilityLabel("Link, \(link)")
            }
        }
    }

    // MARK: Buttons

    private var buttons: some View {
        HStack(spacing: 8) {
            switch posture {
            case .own:
                quietButton(config.editLabel, action: onPrimary)
                quietButton(config.shareLabel, action: onSecondary)
            case .other(let state):
                FeedFollowButton(state: state, onTap: { onPrimary?() })
                    .frame(maxWidth: .infinity)
                quietButton(config.messageLabel, action: onSecondary)
            }
            if let onDiscoverPeople {
                Button(action: onDiscoverPeople) {
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(FeedTokens.ink)
                        .frame(width: 34, height: 32)
                        .background(FeedTokens.field,
                                    in: .rect(cornerRadius: FeedTokens.radiusButton))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Discover people")
            }
        }
    }

    private func quietButton(_ label: String, action: (() -> Void)?) -> some View {
        Button(action: { action?() }) {
            Text(label)
                .font(FeedTokens.buttonFont)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .foregroundStyle(FeedTokens.ink)
                .frame(maxWidth: .infinity, minHeight: 32)
                .background(FeedTokens.field,
                            in: .rect(cornerRadius: FeedTokens.radiusButton))
        }
        .buttonStyle(.plain)
    }
}

#Preview("Profile header") {
    if #available(iOS 17.0, *) {
        VStack(spacing: 24) {
            FeedProfileHeader(
                name: "sam.field",
                displayName: "Sam Field",
                pronouns: "he/him",
                ring: .unread,
                stats: [
                    FeedProfileStat(value: 12, label: "posts"),
                    FeedProfileStat(value: 1_240, label: "followers"),
                    FeedProfileStat(value: 315, label: "following"),
                ],
                bio: "Sharing the quiet corners of the coast.",
                link: "fieldnotes.example",
                posture: .own,
                onPrimary: {}, onSecondary: {}, onDiscoverPeople: {}
            )
            FeedProfileHeader(
                name: "juno.lee",
                displayName: "JUNO LEE",
                isVerified: true,
                stats: [
                    FeedProfileStat(value: 3_232, label: "posts"),
                    FeedProfileStat(value: 31_900_000, label: "followers"),
                    FeedProfileStat(value: 3_630, label: "following"),
                ],
                bio: "Artist. Touring this fall.",
                link: "junolee.example",
                posture: .other(.follow),
                onPrimary: {}, onSecondary: {}
            )
        }
        .background(FeedTokens.ground)
    }
}
