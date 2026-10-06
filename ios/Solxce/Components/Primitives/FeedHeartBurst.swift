// 10x primitive: instagram/reaction-heart-burst v1
import SwiftUI

/// The double-tap like moment: a large white heart pops over the media with a
/// spring, holds a beat, then fades as it drifts upward. Increment `burstID`
/// to replay. Under Reduce Motion the heart simply fades in and out in place.
@available(iOS 17.0, *)
struct FeedHeartBurst: View {
    /// Change this value to fire a burst; each distinct value plays once.
    var burstID: Int
    /// Heart size at rest. Observed bursts fill roughly a third of the media.
    var size: CGFloat = 96

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var visible = false
    @State private var scale: CGFloat = 0.4
    @State private var drift: CGFloat = 0

    var body: some View {
        Image(systemName: "heart.fill")
            .font(.system(size: size))
            .foregroundStyle(.white)
            .shadow(color: .black.opacity(0.25), radius: 12, y: 4)
            .scaleEffect(scale)
            .offset(y: drift)
            .opacity(visible ? 1 : 0)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
            .onChange(of: burstID) { _, _ in play() }
    }

    private func play() {
        if reduceMotion {
            scale = 1
            drift = 0
            withAnimation(.easeIn(duration: 0.15)) { visible = true }
            withAnimation(.easeOut(duration: 0.4).delay(0.6)) { visible = false }
            return
        }
        scale = 0.4
        drift = 0
        visible = true
        withAnimation(.spring(response: 0.32, dampingFraction: 0.55)) {
            scale = 1
        }
        withAnimation(.easeOut(duration: 0.45).delay(0.55)) {
            visible = false
            drift = -40
            scale = 0.8
        }
    }
}

/// Wires a media surface for double-tap liking: fires `onLike`, plays a
/// centered `FeedHeartBurst`, and exposes an equivalent VoiceOver "Like"
/// action so the gesture is never the only path.
@available(iOS 17.0, *)
struct FeedDoubleTapLikeModifier: ViewModifier {
    var onLike: () -> Void
    @State private var burstID = 0

    func body(content: Content) -> some View {
        content
            .overlay {
                FeedHeartBurst(burstID: burstID)
            }
            .onTapGesture(count: 2) { fire() }
            .accessibilityAction(named: "Like") { fire() }
    }

    private func fire() {
        burstID += 1
        onLike()
    }
}

@available(iOS 17.0, *)
extension View {
    /// Double-tap to like with the heart-burst moment and a VoiceOver
    /// equivalent action.
    func feedDoubleTapLike(onLike: @escaping () -> Void) -> some View {
        modifier(FeedDoubleTapLikeModifier(onLike: onLike))
    }
}

#Preview("Heart burst") {
    if #available(iOS 17.0, *) {
        struct Host: View {
            @State private var likes = 0
            var body: some View {
                VStack(spacing: 16) {
                    FeedMediaScene(seed: "gull-point")
                        .frame(height: 360)
                        .clipShape(.rect(cornerRadius: FeedTokens.radiusCard))
                        .feedDoubleTapLike(onLike: { likes += 1 })
                    Text("Double-tap the scene — liked \(likes)×")
                        .font(FeedTokens.bodyFont)
                        .foregroundStyle(FeedTokens.inkSecondary)
                }
                .padding(20)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(FeedTokens.ground)
            }
        }
        return AnyView(Host())
    }
    return AnyView(EmptyView())
}
