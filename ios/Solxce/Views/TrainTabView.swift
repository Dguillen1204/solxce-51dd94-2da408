// Views/TrainTabView.swift
import SwiftUI
import SwiftData

/// Dedicated Train Tab for the Apex Performance architecture
struct TrainTabView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage(AppTheme.activeAccentKey) private var selectedAccentRaw: String = AppAccentColor.volt.rawValue
    private var activeAccentColor: Color {
        AppAccentColor(rawValue: selectedAccentRaw)?.color ?? AppTheme.primary
    }

    private var activeAccentGradient: LinearGradient {
        AppAccentColor(rawValue: selectedAccentRaw)?.gradient ?? AppTheme.accentGradient
    }

    @Query(sort: \WorkoutSession.date, order: .reverse) private var workoutSessions: [WorkoutSession]
    @Query(sort: \RunEntry.date, order: .reverse) private var runEntries: [RunEntry]
    @ObservedObject private var healthKit = HealthKitService.shared

    @State private var showingWorkoutLogger = false
    @State private var showingRunLogger = false
    @State private var selectedFilter: TrainSectionFilter = .all

    enum TrainSectionFilter: String, CaseIterable {
        case all = "All Sessions"
        case strength = "Strength"
        case running = "Runs"
    }

    var totalVolumeLbs: Double {
        workoutSessions.reduce(0) { $0 + $1.totalVolumeLbs }
    }

    var totalMiles: Double {
        runEntries.reduce(0) { $0 + $1.distanceMiles }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.lg) {
                    // Header Status & Live Watch Companion Bar
                    headerHeroSection

                    // Quick Action Dual Launchers (Strength + Run)
                    actionLaunchers

                    // Live Metrics Telemetry Summary
                    telemetrySummaryStrip

                    // Filter Segmented Pill Bar
                    filterPills

                    // Logged Sessions List
                    sessionsList
                }
                .padding(.horizontal, AppTheme.Spacing.screenMargin)
                .padding(.top, AppTheme.Spacing.xs)
                .padding(.bottom, AppTheme.Spacing.xxl + 40)
            }
            .background(AppTheme.ground.ignoresSafeArea())
            .sheet(isPresented: $showingWorkoutLogger) {
                WorkoutLoggerView()
            }
            .sheet(isPresented: $showingRunLogger) {
                RunLogView()
            }
        }
    }

    // MARK: - Header Hero Section
    private var headerHeroSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
            HStack {
                Text("TRAINING & APEX LOGS")
                    .font(AppTheme.eyebrowFont)
                    .tracking(2.0)
                    .foregroundStyle(AppTheme.textSecondary)

                Spacer()
            }

            Text("Train Hard.")
                .font(AppTheme.largeTitleFont)
                .foregroundStyle(AppTheme.text)
                + Text(" Recover Apex.")
                .font(AppTheme.largeTitleFont)
                .foregroundStyle(AppTheme.accent)
        }
    }

    // MARK: - Action Launchers (Strength + Run)
    private var actionLaunchers: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            // Log Lift - Top Horizontal Tab Button
            Button {
                showingWorkoutLogger = true
            } label: {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(AppTheme.accent.opacity(0.18))
                            .frame(width: 48, height: 48)
                        Image(systemName: "dumbbell.fill")
                            .font(.system(size: 20, weight: .black))
                            .foregroundStyle(AppTheme.accent)
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text("LOG LIFT")
                            .font(AppTheme.headlineFont.weight(.black))
                            .tracking(1.2)
                            .foregroundStyle(AppTheme.accent)
                        Text("Strength, Hypertrophy & Progressive Overload")
                            .font(AppTheme.captionFont)
                            .foregroundStyle(AppTheme.textSecondary)
                            .lineLimit(1)
                    }

                    Spacer()

                    HStack(spacing: 6) {
                        Text("Start")
                            .font(AppTheme.captionFont.weight(.bold))
                            .foregroundStyle(AppTheme.accent)
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(AppTheme.accent)
                    }
                }
                .padding(.horizontal, AppTheme.Spacing.md)
                .padding(.vertical, 14)
                .frame(maxWidth: .infinity)
                .background(AppTheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.card))
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.Radii.card)
                        .stroke(AppTheme.accent.opacity(0.35), lineWidth: 1.2)
                )
            }
            .buttonStyle(ScaleBounceButtonStyle())

            // Log Run - Bottom Horizontal Tab Button
            Button {
                showingRunLogger = true
            } label: {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(AppTheme.proteinColor.opacity(0.18))
                            .frame(width: 48, height: 48)
                        Image(systemName: "figure.run")
                            .font(.system(size: 20, weight: .black))
                            .foregroundStyle(AppTheme.proteinColor)
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text("LOG RUN")
                            .font(AppTheme.headlineFont.weight(.black))
                            .tracking(1.2)
                            .foregroundStyle(AppTheme.proteinColor)
                        Text("Distance, Pace & Aerobic Intervals")
                            .font(AppTheme.captionFont)
                            .foregroundStyle(AppTheme.textSecondary)
                            .lineLimit(1)
                    }

                    Spacer()

                    HStack(spacing: 6) {
                        Text("Start")
                            .font(AppTheme.captionFont.weight(.bold))
                            .foregroundStyle(AppTheme.proteinColor)
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(AppTheme.proteinColor)
                    }
                }
                .padding(.horizontal, AppTheme.Spacing.md)
                .padding(.vertical, 14)
                .frame(maxWidth: .infinity)
                .background(AppTheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.card))
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.Radii.card)
                        .stroke(AppTheme.surfaceRaised, lineWidth: 1.2)
                )
            }
            .buttonStyle(ScaleBounceButtonStyle())
        }
    }

    // MARK: - Telemetry Summary Strip
    private var telemetrySummaryStrip: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            telemetryMetricBox(
                title: "TOTAL VOLUME",
                value: "\(Int(totalVolumeLbs))",
                unit: "lbs",
                icon: "scalemass.fill",
                accentColor: AppTheme.accent
            )

            telemetryMetricBox(
                title: "TOTAL DISTANCE",
                value: String(format: "%.1f", totalMiles),
                unit: "mi",
                icon: "figure.run",
                accentColor: AppTheme.proteinColor
            )

            telemetryMetricBox(
                title: "COMPLETED",
                value: "\(workoutSessions.count + runEntries.count)",
                unit: "sessions",
                icon: "checkmark.seal.fill",
                accentColor: activeAccentColor
            )
        }
    }

    private func telemetryMetricBox(title: String, value: String, unit: String, icon: String, accentColor: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(accentColor)
                Text(title)
                    .font(.system(size: 9, weight: .heavy))
                    .tracking(1.0)
                    .foregroundStyle(AppTheme.textSecondary)
            }

            HStack(alignment: .lastTextBaseline, spacing: 3) {
                Text(value)
                    .font(AppTheme.headlineFont.weight(.black))
                    .foregroundStyle(AppTheme.text)
                Text(unit)
                    .font(AppTheme.captionFont)
                    .foregroundStyle(AppTheme.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppTheme.Spacing.sm)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.tag))
    }

    // MARK: - Filter Pills
    private var filterPills: some View {
        HStack(spacing: AppTheme.Spacing.xs) {
            ForEach(TrainSectionFilter.allCases, id: \.self) { filter in
                Button {
                    selectedFilter = filter
                } label: {
                    Text(filter.rawValue)
                        .font(AppTheme.captionFont.weight(.semibold))
                        .foregroundStyle(selectedFilter == filter ? AppTheme.onPrimary : AppTheme.textSecondary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(selectedFilter == filter ? activeAccentColor : AppTheme.surface)
                        .clipShape(Capsule())
                }
            }
            Spacer()
        }
    }

    // MARK: - Sessions List
    private var sessionsList: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            if selectedFilter != .running {
                ForEach(workoutSessions) { session in
                    workoutSessionRow(session)
                }
            }

            if selectedFilter != .strength {
                ForEach(runEntries) { run in
                    runSessionRow(run)
                }
            }

            if (selectedFilter == .strength && workoutSessions.isEmpty) ||
               (selectedFilter == .running && runEntries.isEmpty) ||
               (selectedFilter == .all && workoutSessions.isEmpty && runEntries.isEmpty) {
                emptyState
            }
        }
    }

    private func workoutSessionRow(_ session: WorkoutSession) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "dumbbell.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(AppTheme.accent)
                    Text(session.title)
                        .font(AppTheme.headlineFont)
                        .foregroundStyle(AppTheme.text)
                }
                Spacer()
                Text(session.date.formatted(date: .abbreviated, time: .omitted))
                    .font(AppTheme.captionFont)
                    .foregroundStyle(AppTheme.textSecondary)
            }

            HStack(spacing: AppTheme.Spacing.md) {
                Label("\(session.bodyPartFocus)", systemImage: "figure.strengthtraining.traditional")
                Label("\(Int(session.totalVolumeLbs)) lbs", systemImage: "scalemass")
                Label("\(session.durationMinutes) min", systemImage: "clock")
            }
            .font(AppTheme.captionFont)
            .foregroundStyle(AppTheme.textSecondary)
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.card))
    }

    private func runSessionRow(_ run: RunEntry) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "figure.run")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(AppTheme.proteinColor)
                    Text(run.title)
                        .font(AppTheme.headlineFont)
                        .foregroundStyle(AppTheme.text)
                }
                Spacer()
                Text(run.date.formatted(date: .abbreviated, time: .omitted))
                    .font(AppTheme.captionFont)
                    .foregroundStyle(AppTheme.textSecondary)
            }

            HStack(spacing: AppTheme.Spacing.md) {
                Label(String(format: "%.2f mi", run.distanceMiles), systemImage: "point.topleft.down.to.point.bottomright.curvepath")
                Label(run.formattedPace, systemImage: "speedometer")
                Label(run.formattedDuration, systemImage: "clock")
            }
            .font(AppTheme.captionFont)
            .foregroundStyle(AppTheme.textSecondary)
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.card))
    }

    private var emptyState: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            Image(systemName: "dumbbell")
                .font(.system(size: 32))
                .foregroundStyle(AppTheme.textSecondary.opacity(0.4))
            Text("No Training Sessions Yet")
                .font(AppTheme.headlineFont)
                .foregroundStyle(AppTheme.text)
            Text("Tap Log Lift or Log Run above to record your first workout.")
                .font(AppTheme.captionFont)
                .foregroundStyle(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 36)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.card))
    }
}
