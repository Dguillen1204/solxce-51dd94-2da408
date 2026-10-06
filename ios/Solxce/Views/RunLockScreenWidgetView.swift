// Views/RunLockScreenWidgetView.swift
import SwiftUI

// MARK: - Lock Screen Live Activity Banner / Interactive Card
public struct RunLockScreenBannerView: View {
    @ObservedObject var liveManager = RunLiveActivityManager.shared
    var onOpenSimulator: (() -> Void)? = nil

    public init(onOpenSimulator: (() -> Void)? = nil) {
        self.onOpenSimulator = onOpenSimulator
    }

    public var body: some View {
        VStack(spacing: 12) {
            // Header Row: App Identity + Live Pulse Tag
            HStack(spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "figure.run.circle.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(AppTheme.primary)

                    Text("SOLXCE RUN")
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .tracking(1.2)
                        .foregroundColor(.white)
                }

                Spacer()

                HStack(spacing: 5) {
                    Circle()
                        .fill(liveManager.isPaused ? Color.orange : AppTheme.primary)
                        .frame(width: 8, height: 8)

                    Text(liveManager.isPaused ? "PAUSED" : "LOCK SCREEN ACTIVE")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(liveManager.isPaused ? Color.orange : AppTheme.primary)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color.white.opacity(0.08))
                .clipShape(Capsule())

                if let onOpenSimulator = onOpenSimulator {
                    Button(action: onOpenSimulator) {
                        Image(systemName: "iphone.gen3")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white.opacity(0.8))
                            .padding(6)
                            .background(Color.white.opacity(0.12))
                            .clipShape(Circle())
                    }
                }
            }

            // Key Metrics 3-Column Display
            HStack(spacing: 0) {
                // Distance
                VStack(alignment: .leading, spacing: 2) {
                    Text(String(format: "%.2f", liveManager.totalDistanceMiles))
                        .font(.system(size: 28, weight: .heavy, design: .rounded))
                        .foregroundColor(AppTheme.primary)
                    Text("MILES")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white.opacity(0.6))
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Current Pace
                VStack(alignment: .center, spacing: 2) {
                    Text(liveManager.currentPaceFormatted)
                        .font(.system(size: 24, weight: .heavy, design: .monospaced))
                        .foregroundColor(.white)
                    Text("CURRENT PACE")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white.opacity(0.6))
                }
                .frame(maxWidth: .infinity, alignment: .center)

                // Time / Duration
                VStack(alignment: .trailing, spacing: 2) {
                    Text(liveManager.formattedElapsedTime)
                        .font(.system(size: 24, weight: .heavy, design: .monospaced))
                        .foregroundColor(.white)
                    Text("TIME")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white.opacity(0.6))
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }

            // Target Progress Bar
            VStack(spacing: 4) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.12))
                            .frame(height: 6)

                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [AppTheme.primary, Color.cyan],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: max(8, geo.size.width * CGFloat(liveManager.progressToTarget)), height: 6)
                    }
                }
                .frame(height: 6)

                HStack {
                    Text(String(format: "Goal: %.1f mi (%.0f%%)", liveManager.targetDistanceMiles, liveManager.progressToTarget * 100))
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.white.opacity(0.6))

                    Spacer()

                    HStack(spacing: 4) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 9))
                            .foregroundColor(liveManager.heartRateZoneColor)
                        Text("\(liveManager.heartRateBpm) BPM · \(liveManager.heartRateZone)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white.opacity(0.85))
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(hex: "#12141A").opacity(0.92))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(AppTheme.primary.opacity(0.35), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.5), radius: 10, x: 0, y: 4)
        )
    }
}

// MARK: - Full Lock Screen Preview Modal (Simulating Realistic iPhone Lock Screen)
public struct RunLockScreenSimulatorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var liveManager = RunLiveActivityManager.shared

    @State private var currentTime = Date()
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    public var body: some View {
        ZStack {
            // Realistic Apple Lock Screen Wallpaper Background
            LinearGradient(
                colors: [
                    Color(hex: "#090B10"),
                    Color(hex: "#1A2238"),
                    Color(hex: "#0D1117")
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Top Status Bar: Lock Icon + Dynamic Island
                HStack {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.leading, 24)

                    Spacer()

                    // Dynamic Island Simulation Pill
                    dynamicIslandPill

                    Spacer()

                    HStack(spacing: 4) {
                        Image(systemName: "wifi")
                            .font(.system(size: 12))
                        Image(systemName: "battery.100")
                            .font(.system(size: 14))
                    }
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.trailing, 24)
                }
                .padding(.top, 14)

                // Lock Screen Time & Date Display
                VStack(spacing: 4) {
                    Text(currentTime.formatted(.dateTime.weekday(.wide).month().day()))
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white.opacity(0.85))

                    Text(currentTime.formatted(.dateTime.hour().minute()))
                        .font(.system(size: 78, weight: .thin, design: .rounded))
                        .foregroundColor(.white)
                }
                .padding(.top, 28)

                Spacer()

                // Lock Screen Live Activity Widget
                VStack(spacing: 12) {
                    RunLockScreenBannerView(onOpenSimulator: nil)

                    // Lock Screen Music / Live Playback Bar Info
                    HStack(spacing: 10) {
                        Image(systemName: "waveform")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(AppTheme.primary)

                        Text("Lock Screen GPS is updating live in background")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white.opacity(0.75))

                        Spacer()

                        Image(systemName: "airpods.pro")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(0.4))
                    .clipShape(Capsule())
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 24)

                // Lock Screen Bottom Flashlight & Camera Icons
                HStack {
                    Circle()
                        .fill(Color.white.opacity(0.18))
                        .frame(width: 50, height: 50)
                        .overlay(
                            Image(systemName: "flashlight.on.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                        )

                    Spacer()

                    Button(action: { dismiss() }) {
                        Text("Exit Preview")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.black)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 8)
                            .background(AppTheme.primary)
                            .clipShape(Capsule())
                    }

                    Spacer()

                    Circle()
                        .fill(Color.white.opacity(0.18))
                        .frame(width: 50, height: 50)
                        .overlay(
                            Image(systemName: "camera.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                        )
                }
                .padding(.horizontal, 36)
                .padding(.bottom, 34)
            }
        }
        .onReceive(timer) { newTime in
            currentTime = newTime
        }
    }

    private var dynamicIslandPill: some View {
        HStack(spacing: 8) {
            Image(systemName: "figure.run")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(AppTheme.primary)

            Text(String(format: "%.2f mi", liveManager.totalDistanceMiles))
                .font(.system(size: 12, weight: .black, design: .monospaced))
                .foregroundColor(.white)

            Text("·")
                .foregroundColor(.white.opacity(0.4))

            Text(liveManager.formattedElapsedTime)
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(AppTheme.primary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.black)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .strokeBorder(Color.white.opacity(0.15), lineWidth: 1)
        )
    }
}
