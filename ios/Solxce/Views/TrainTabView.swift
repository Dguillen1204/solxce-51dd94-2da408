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
    @Query(sort: \PlannerDay.dayOfWeek) private var plannerDays: [PlannerDay]
    @ObservedObject private var healthKit = HealthKitService.shared

    @State private var showingWorkoutLogger = false
    @State private var showingRunLogger = false
    @State private var showingSplitPresets = false
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

    var todaysScheduledFocus: PlannerDay? {
        let weekday = Calendar.current.component(.weekday, from: Date())
        return plannerDays.first(where: { $0.dayOfWeek == weekday })
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.lg) {
                    // Header Status & Section Hero
                    headerHeroSection

                    // Today's Scheduled Split Card with Quick Customization
                    todaySplitScheduleCard

                    // Quick Action Dual Launchers (Strength + Run)
                    actionLaunchers

                    // Live Metrics Telemetry Summary
                    telemetrySummaryStrip

                    // Filter Segmented Pill Bar
                    filterPills

                    // Logged Sessions List
                    loggedSessionsList
                }
                .padding(.horizontal, AppTheme.Spacing.screenMargin)
                .padding(.top, AppTheme.Spacing.sm)
                .padding(.bottom, AppTheme.Spacing.xxl + 40)
            }
            .background(AppTheme.ground.ignoresSafeArea())
            .sheet(isPresented: $showingWorkoutLogger) {
                WorkoutLoggerView()
            }
            .sheet(isPresented: $showingRunLogger) {
                RunLogView()
            }
            .sheet(isPresented: $showingSplitPresets) {
                SplitPresetsSelectionSheet(days: plannerDays)
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

                Button {
                    showingSplitPresets = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 11, weight: .bold))
                        Text("Change Split")
                            .font(.system(size: 11, weight: .bold))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(AppTheme.surfaceRaised)
                    .foregroundStyle(activeAccentColor)
                    .clipShape(Capsule())
                    .overlay(Capsule().strokeBorder(activeAccentColor.opacity(0.3), lineWidth: 1))
                }
            }

            Text("Train Hard.")
                .font(AppTheme.largeTitleFont)
                .foregroundStyle(AppTheme.text)
                + Text(" Recover Apex.")
                .font(AppTheme.largeTitleFont)
                .foregroundStyle(AppTheme.accent)
        }
    }

    // MARK: - Today's Scheduled Split Card
    private var todaySplitScheduleCard: some View {
        let currentDay = todaysScheduledFocus

        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                HStack(spacing: 6) {
                    Circle()
                        .fill(currentDay?.isRestDay == true ? Color.orange : activeAccentColor)
                        .frame(width: 8, height: 8)
                    Text("TODAY'S SCHEDULED SPLIT")
                        .font(AppTheme.eyebrowFont)
                        .foregroundStyle(currentDay?.isRestDay == true ? Color.orange : activeAccentColor)
                }

                Spacer()

                Button {
                    showingSplitPresets = true
                } label: {
                    Text("Edit Split")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(AppTheme.textMuted)
                }
            }

            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(currentDay?.focusBodyPart ?? "Push / Chest & Arms")
                        .font(.system(size: 17, weight: .heavy))
                        .foregroundStyle(AppTheme.text)

                    if let targetNotes = currentDay?.targetExercisesDescription, !targetNotes.isEmpty {
                        Text(targetNotes)
                            .font(AppTheme.captionFont)
                            .foregroundStyle(AppTheme.textSecondary)
                            .lineLimit(1)
                    } else if currentDay?.isRestDay == true {
                        Text("Active recovery, mobility, or total rest")
                            .font(AppTheme.captionFont)
                            .foregroundStyle(AppTheme.textMuted)
                    } else {
                        Text("Tap to review routine exercises")
                            .font(AppTheme.captionFont)
                            .foregroundStyle(AppTheme.textMuted)
                    }
                }

                Spacer()

                if currentDay?.isRestDay == false {
                    Button {
                        showingWorkoutLogger = true
                    } label: {
                        Text("Start Today's Split")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.black)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(activeAccentColor)
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.card))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radii.card)
                .strokeBorder(AppTheme.hairline, lineWidth: 1)
        )
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
                        Text("GPS Outdoor, Treadmill & Track Intervals")
                            .font(AppTheme.captionFont)
                            .foregroundStyle(AppTheme.textSecondary)
                            .lineLimit(1)
                    }

                    Spacer()

                    HStack(spacing: 6) {
                        Text("Track")
                            .font(AppTheme.captionFont.weight(.bold))
                            .foregroundStyle(AppTheme.proteinColor)
                        Image(systemName: "play.circle.fill")
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
                        .stroke(AppTheme.proteinColor.opacity(0.35), lineWidth: 1.2)
                )
            }
            .buttonStyle(ScaleBounceButtonStyle())
        }
    }

    // MARK: - Live Metrics Telemetry Summary Strip
    private var telemetrySummaryStrip: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            // Heart Rate
            telemetryCard(
                icon: "heart.fill",
                iconColor: Color.red,
                label: "HEART RATE",
                value: healthKit.currentHeartRateBpm > 0 ? "\(Int(healthKit.currentHeartRateBpm))" : "--",
                unit: "BPM"
            )

            // Active Calories
            telemetryCard(
                icon: "flame.fill",
                iconColor: Color.orange,
                label: "CALORIES",
                value: "\(Int(healthKit.todayActiveCalories))",
                unit: "KCAL"
            )

            // Lifetime Volume
            telemetryCard(
                icon: "scalemass.fill",
                iconColor: AppTheme.accent,
                label: "TOTAL VOLUME",
                value: formatVolume(totalVolumeLbs),
                unit: "LBS"
            )
        }
    }

    private func telemetryCard(icon: String, iconColor: Color, label: String, value: String, unit: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(iconColor)
                Text(label)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(AppTheme.textSecondary)
            }

            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 16, weight: .heavy, design: .monospaced))
                    .foregroundStyle(AppTheme.text)
                Text(unit)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(AppTheme.textMuted)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.card))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radii.card)
                .stroke(AppTheme.hairline, lineWidth: 1)
        )
    }

    // MARK: - Filter Segmented Pills
    private var filterPills: some View {
        HStack(spacing: AppTheme.Spacing.xs) {
            ForEach(TrainSectionFilter.allCases, id: \.self) { filter in
                let isSelected = selectedFilter == filter
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedFilter = filter
                    }
                } label: {
                    Text(filter.rawValue)
                        .font(AppTheme.captionFont.weight(isSelected ? .bold : .medium))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(isSelected ? AppTheme.accent : AppTheme.surface)
                        .foregroundStyle(isSelected ? AppTheme.onPrimary : AppTheme.textSecondary)
                        .clipShape(Capsule())
                }
            }
            Spacer()
        }
    }

    // MARK: - Logged Sessions List
    private var loggedSessionsList: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            if selectedFilter == .all || selectedFilter == .strength {
                ForEach(workoutSessions.prefix(5)) { session in
                    workoutSessionRow(session)
                }
            }

            if selectedFilter == .all || selectedFilter == .running {
                ForEach(runEntries.prefix(5)) { run in
                    runEntryRow(run)
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
        HStack(spacing: AppTheme.Spacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(AppTheme.accent.opacity(0.12))
                    .frame(width: 44, height: 44)
                Image(systemName: "dumbbell.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(AppTheme.accent)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(session.title)
                    .font(AppTheme.headlineFont)
                    .foregroundStyle(AppTheme.text)

                Text("\(session.date.formatted(.dateTime.weekday().month().day())) • \(session.exercises.count) exercises")
                    .font(AppTheme.captionFont)
                    .foregroundStyle(AppTheme.textSecondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(Int(session.totalVolumeLbs).formatted()) lbs")
                    .font(AppTheme.headlineFont.weight(.bold))
                    .foregroundStyle(AppTheme.accent)

                Text("\(Int(session.durationMinutes)) min")
                    .font(AppTheme.captionFont)
                    .foregroundStyle(AppTheme.textMuted)
            }
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.card))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radii.card)
                .stroke(AppTheme.hairline, lineWidth: 1)
        )
    }

    private func runEntryRow(_ run: RunEntry) -> some View {
        HStack(spacing: AppTheme.Spacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(AppTheme.proteinColor.opacity(0.12))
                    .frame(width: 44, height: 44)
                Image(systemName: "figure.run")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(AppTheme.proteinColor)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(run.title)
                    .font(AppTheme.headlineFont)
                    .foregroundStyle(AppTheme.text)

                Text("\(run.date.formatted(.dateTime.weekday().month().day())) • \(Int(run.durationSeconds / 60)) mins")
                    .font(AppTheme.captionFont)
                    .foregroundStyle(AppTheme.textSecondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(String(format: "%.2f mi", run.distanceMiles))
                    .font(AppTheme.headlineFont.weight(.bold))
                    .foregroundStyle(AppTheme.proteinColor)

                Text(run.formattedPace)
                    .font(AppTheme.captionFont)
                    .foregroundStyle(AppTheme.textMuted)
            }
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.card))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radii.card)
                .stroke(AppTheme.hairline, lineWidth: 1)
        )
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "figure.cross-training")
                .font(.system(size: 36))
                .foregroundStyle(AppTheme.textMuted)
            Text("No logged sessions yet")
                .font(AppTheme.headlineFont)
                .foregroundStyle(AppTheme.textSecondary)
            Text("Tap Log Lift or Log Run above to track your first apex session.")
                .font(AppTheme.captionFont)
                .foregroundStyle(AppTheme.textMuted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }

    private func formatVolume(_ volume: Double) -> String {
        if volume >= 1000 {
            return String(format: "%.1fk", volume / 1000)
        }
        return "\(Int(volume))"
    }
}
