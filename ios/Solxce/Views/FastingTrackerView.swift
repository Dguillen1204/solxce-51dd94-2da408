// Views/FastingTrackerView.swift
import SwiftUI

struct FastingTrackerView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var fasting = FastingManager.shared
    @ObservedObject private var subManager = SubscriptionManager.shared
    @State private var showPaywall = false
    @State private var showingCustomFastPicker = false
    @State private var customHours: Int = 16

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.ground.ignoresSafeArea()

                if !subManager.isPro {
                    proLockedGate
                } else {
                    mainFastingContent
                }
            }
            .navigationTitle("Intermittent Fasting")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .font(AppTheme.headlineFont)
                        .foregroundStyle(AppTheme.primary)
                }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
        }
    }

    // MARK: - Pro Locked Gate
    private var proLockedGate: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            ZStack {
                Circle()
                    .fill(AppTheme.primary.opacity(0.15))
                    .frame(width: 90, height: 90)
                Image(systemName: "timer")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundStyle(AppTheme.primary)
            }

            VStack(spacing: AppTheme.Spacing.xs) {
                Text("Intermittent Fasting Pro")
                    .font(AppTheme.displayFont)
                    .foregroundStyle(AppTheme.text)
                    .multilineTextAlignment(.center)

                Text("Optimize cellular autophagy, metabolic flexibility, and fat loss with intelligent fasting timers and automated notifications.")
                    .font(AppTheme.bodyFont)
                    .foregroundStyle(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppTheme.Spacing.lg)
            }

            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                featureCheck("16:8, 18:6, 20:4 & Custom fasting schedules")
                featureCheck("Automated alerts when your eating window opens and closes")
                featureCheck("Live home widget and progress ring visualization")
            }
            .padding(.horizontal, AppTheme.Spacing.md)

            Spacer()

            Button {
                showPaywall = true
            } label: {
                HStack {
                    Image(systemName: "sparkles")
                    Text("Unlock with Solxce Pro ($4.99/mo or $49.99/yr)")
                        .bold()
                }
                .font(AppTheme.headlineFont)
                .foregroundStyle(AppTheme.onPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(AppTheme.primary)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.button))
            }
            .padding(.horizontal, AppTheme.Spacing.screenMargin)
            .padding(.bottom, AppTheme.Spacing.lg)
        }
        .padding(.top, AppTheme.Spacing.xl)
    }

    private func featureCheck(_ text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(AppTheme.primary)
            Text(text)
                .font(AppTheme.subheadlineFont)
                .foregroundStyle(AppTheme.text)
        }
    }

    // MARK: - Main Fasting Content
    private var mainFastingContent: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.lg) {
                // Large Circular Fasting Progress Ring
                fastingHeroRing

                // Live Timing Breakdown Card
                timingDetailsCard

                // Protocol Selector
                protocolSelectionCard

                // Notification Alerts Configuration
                notificationCard

                // Fasting Benefits & Stages Info
                metabolicStagesCard
            }
            .padding(.horizontal, AppTheme.Spacing.screenMargin)
            .padding(.top, AppTheme.Spacing.sm)
            .padding(.bottom, AppTheme.Spacing.xxl)
        }
    }

    // MARK: - Fasting Progress Ring
    private var fastingHeroRing: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            ZStack {
                // Background Track
                Circle()
                    .stroke(AppTheme.surfaceRaised, lineWidth: 18)
                    .frame(width: 230, height: 230)

                // Progress Arc
                Circle()
                    .trim(from: 0, to: fasting.isFastingActive ? fasting.progress : 0)
                    .stroke(
                        AngularGradient(
                            colors: [AppTheme.primary, AppTheme.accent],
                            center: .center,
                            startAngle: .degrees(-90),
                            endAngle: .degrees(270)
                        ),
                        style: StrokeStyle(lineWidth: 18, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .frame(width: 230, height: 230)
                    .animation(.easeInOut(duration: 0.5), value: fasting.progress)

                // Center Content
                VStack(spacing: 4) {
                    Text(fasting.currentFastingState.rawValue.uppercased())
                        .font(AppTheme.eyebrowFont)
                        .tracking(1.5)
                        .foregroundStyle(fasting.isEatingWindowOpen ? AppTheme.carbsColor : AppTheme.primary)

                    Text(fasting.isFastingActive ? fasting.remainingTimeFormatted : "\(fasting.targetFastHours)h Fast")
                        .font(AppTheme.heroNumeralFont)
                        .monospacedDigit()
                        .foregroundStyle(AppTheme.text)

                    Text(fasting.isFastingActive ? "\(Int(fasting.progress * 100))% completed" : "Tap Start Fast below")
                        .font(AppTheme.captionFont)
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }
            .padding(.top, AppTheme.Spacing.sm)

            // Primary Start / End Button
            Button {
                if fasting.isFastingActive {
                    fasting.endFast()
                } else {
                    fasting.startFast()
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: fasting.isFastingActive ? "stop.fill" : "play.fill")
                    Text(fasting.isFastingActive ? "End Fast" : "Start Fast Now")
                        .bold()
                }
                .font(AppTheme.headlineFont)
                .foregroundStyle(fasting.isFastingActive ? AppTheme.text : AppTheme.onPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(fasting.isFastingActive ? AppTheme.accent : AppTheme.primary)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.button))
            }
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.card))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radii.card)
                .strokeBorder(AppTheme.hairline)
        )
    }

    // MARK: - Timing Details Card
    private var timingDetailsCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text("WINDOW SCHEDULE")
                .font(AppTheme.eyebrowFont)
                .tracking(1.5)
                .foregroundStyle(AppTheme.textSecondary)

            HStack(spacing: AppTheme.Spacing.xs) {
                schedulePill(
                    title: "FAST STARTED",
                    time: fasting.isFastingActive ? fasting.fastStartTime.formatted(.dateTime.hour().minute()) : "--:--",
                    icon: "moon.fill",
                    color: AppTheme.primary
                )

                schedulePill(
                    title: "EAT WINDOW OPENS",
                    time: fasting.isFastingActive ? fasting.fastTargetEndTime.formatted(.dateTime.hour().minute()) : "--:--",
                    icon: "fork.knife",
                    color: AppTheme.carbsColor
                )

                schedulePill(
                    title: "FAST RESUMES",
                    time: fasting.isFastingActive ? fasting.eatingWindowEndTime.formatted(.dateTime.hour().minute()) : "--:--",
                    icon: "lock.fill",
                    color: AppTheme.accent
                )
            }
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.card))
    }

    private func schedulePill(title: String, time: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(color)
                Text(title)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(AppTheme.textSecondary)
            }
            Text(time)
                .font(AppTheme.headlineFont)
                .bold()
                .foregroundStyle(AppTheme.text)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppTheme.Spacing.sm)
        .background(AppTheme.surfaceRaised)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.tag))
    }

    // MARK: - Protocol Selector
    private var protocolSelectionCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text("FASTING PROTOCOL")
                .font(AppTheme.eyebrowFont)
                .tracking(1.5)
                .foregroundStyle(AppTheme.textSecondary)

            ForEach(FastingProtocol.allCases) { proto in
                let isSelected = fasting.selectedProtocol == proto

                Button {
                    fasting.selectedProtocol = proto
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(proto.rawValue)
                                .font(AppTheme.headlineFont)
                                .foregroundStyle(AppTheme.text)
                            Text(proto.description)
                                .font(AppTheme.captionFont)
                                .foregroundStyle(AppTheme.textSecondary)
                        }

                        Spacer()

                        if isSelected {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(AppTheme.primary)
                        }
                    }
                    .padding(AppTheme.Spacing.sm)
                    .background(AppTheme.surfaceRaised)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.tag))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.Radii.tag)
                            .strokeBorder(isSelected ? AppTheme.primary : Color.clear, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.card))
    }

    // MARK: - Notification Configuration Card
    private var notificationCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            HStack {
                Text("EATING WINDOW NOTIFICATIONS")
                    .font(AppTheme.eyebrowFont)
                    .tracking(1.5)
                    .foregroundStyle(AppTheme.textSecondary)

                Spacer()

                Image(systemName: "bell.badge.fill")
                    .foregroundStyle(AppTheme.primary)
            }

            Text("Receive push notifications the exact minute your eating window begins and 30 minutes before it closes.")
                .font(AppTheme.captionFont)
                .foregroundStyle(AppTheme.textSecondary)

            HStack {
                Text(fasting.notificationStatusMessage.isEmpty ? "Notification Alerts" : fasting.notificationStatusMessage)
                    .font(AppTheme.headlineFont)
                    .foregroundStyle(AppTheme.text)

                Spacer()

                Button {
                    fasting.requestNotificationPermission()
                } label: {
                    Text(fasting.notificationsEnabled ? "Active" : "Enable Alerts")
                        .font(AppTheme.captionFont)
                        .bold()
                        .foregroundStyle(AppTheme.onPrimary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(fasting.notificationsEnabled ? AppTheme.carbsColor : AppTheme.primary)
                        .clipShape(Capsule())
                }
            }
            .padding(.top, 4)
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.card))
    }

    // MARK: - Metabolic Stages
    private var metabolicStagesCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text("METABOLIC MILESTONES")
                .font(AppTheme.eyebrowFont)
                .tracking(1.5)
                .foregroundStyle(AppTheme.textSecondary)

            stageRow(hours: "0-4h", title: "Blood Sugar Stabilization", subtitle: "Insulin levels normalize after your last meal.", icon: "drop.fill", color: AppTheme.primary)
            stageRow(hours: "4-12h", title: "Fat Burning Transition", subtitle: "Glycogen depletion triggers ketone production.", icon: "flame.fill", color: AppTheme.fatColor)
            stageRow(hours: "12-16h", title: "Ketosis & Autophagy", subtitle: "Cellular renewal and increased growth hormone.", icon: "bolt.fill", color: AppTheme.carbsColor)
            stageRow(hours: "16-24h", title: "Deep Cellular Repair", subtitle: "Maximum autophagy and insulin sensitivity.", icon: "sparkles", color: AppTheme.proteinColor)
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.card))
    }

    private func stageRow(hours: String, title: String, subtitle: String, icon: String, color: Color) -> some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(color.opacity(0.18))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(color)
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(title)
                        .font(AppTheme.subheadlineFont)
                        .bold()
                        .foregroundStyle(AppTheme.text)
                    Spacer()
                    Text(hours)
                        .font(AppTheme.captionFont)
                        .foregroundStyle(color)
                }
                Text(subtitle)
                    .font(AppTheme.captionFont)
                    .foregroundStyle(AppTheme.textSecondary)
            }
        }
    }
}
