// Views/TodayView.swift
import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var macroTargets: [MacroTarget]
    @Query private var userProfiles: [UserProfile]
    @Query(sort: \FoodEntry.date, order: .reverse) private var allFoods: [FoodEntry]
    @Query(sort: \WorkoutSession.date, order: .reverse) private var workoutSessions: [WorkoutSession]
    @Query(sort: \RunEntry.date, order: .reverse) private var runEntries: [RunEntry]
    @Query private var plannerDays: [PlannerDay]

    @ObservedObject private var fasting = FastingManager.shared
    @ObservedObject private var subManager = SubscriptionManager.shared

    @State private var showingPlanner = false
    @State private var showingWorkoutLogger = false
    @State private var showingRunLogger = false
    @State private var showingFoodLogger = false
    @State private var showingFastingTracker = false
    @State private var showingCameraScanner = false
    @State private var showingProgressReport = false
    @State private var showingPaywall = false

    @Binding var selectedTab: Int

    var todayPlannerDay: PlannerDay? {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: Date())
        return plannerDays.first { $0.dayOfWeek == weekday }
    }

    var todayFoods: [FoodEntry] {
        let calendar = Calendar.current
        return allFoods.filter { calendar.isDateInToday($0.date) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.lg) {
                    // Header with Date & App Name & Pro status
                    headerSection

                    // Scheduled Split Hero Card
                    todaySplitCard

                    // Intermittent Fasting Live Glance Card
                    fastingGlanceCard

                    // Macro Nutrition Glance Card
                    MacroRingsCard(
                        target: macroTargets.first,
                        todayFoods: todayFoods,
                        onFoodLogTap: { showingFoodLogger = true }
                    )

                    // Quick Log Actions Cluster
                    quickActionsGrid

                    // In-Depth Analytics Banner
                    progressReportBanner

                    // Recent Activity Stream
                    recentActivitySection
                }
                .padding(.horizontal, AppTheme.Spacing.screenMargin)
                .padding(.top, AppTheme.Spacing.xs)
                .padding(.bottom, AppTheme.Spacing.xxl)
            }
            .background(AppTheme.ground.ignoresSafeArea())
            .sheet(isPresented: $showingWorkoutLogger) {
                WorkoutLoggerView()
            }
            .sheet(isPresented: $showingRunLogger) {
                RunLogView()
            }
            .sheet(isPresented: $showingFoodLogger) {
                FoodLogView()
            }
            .sheet(isPresented: $showingFastingTracker) {
                FastingTrackerView()
            }
            .sheet(isPresented: $showingCameraScanner) {
                CameraFoodScannerView()
            }
            .sheet(isPresented: $showingProgressReport) {
                ProgressReportView()
            }
            .sheet(isPresented: $showingPaywall) {
                PaywallView()
            }
            .sheet(isPresented: $showingPlanner) {
                PlannerView()
            }
        }
    }

    // MARK: - Subviews
    private var headerSection: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 2) {
                Text(Date().formatted(.dateTime.weekday(.wide).month(.abbreviated).day()))
                    .font(AppTheme.eyebrowFont)
                    .tracking(1.5)
                    .foregroundStyle(AppTheme.primary)

                HStack(spacing: 8) {
                    Text("SOLXCE")
                        .font(AppTheme.displayFont)
                        .foregroundStyle(AppTheme.text)

                    if subManager.isPro {
                        Text("PRO")
                            .font(.system(size: 11, weight: .black))
                            .foregroundStyle(AppTheme.onPrimary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(AppTheme.primary)
                            .clipShape(Capsule())
                    }
                }
            }

            Spacer()

            if !subManager.isPro {
                Button {
                    showingPaywall = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "sparkles")
                        Text("PRO")
                    }
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(AppTheme.onPrimary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(AppTheme.primary)
                    .clipShape(Capsule())
                }
                .padding(.trailing, 4)
            }

            Button(action: { selectedTab = 4 }) {
                if let profile = userProfiles.first {
                    AthleteAvatarView(
                        imageData: profile.profileImageData,
                        symbolFallback: profile.avatarSymbol.isEmpty ? profile.athleteType.iconName : profile.avatarSymbol,
                        initials: profile.fullName,
                        ringColor: profile.athleteType.badgeColor,
                        size: 38,
                        showCameraBadge: false,
                        isPublic: profile.isPublicProfile
                    )
                } else {
                    Image(systemName: "person.crop.circle")
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundStyle(AppTheme.text)
                        .frame(width: 44, height: 44)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Profile")
        }
    }

    private var todaySplitCard: some View {
        Button(action: { showingPlanner = true }) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                HStack {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(todayPlannerDay?.isRestDay == true ? AppTheme.accent : AppTheme.primary)
                            .frame(width: 8, height: 8)
                        Text(todayPlannerDay?.isRestDay == true ? "SCHEDULED REST" : "TODAY'S SPLIT")
                            .font(AppTheme.eyebrowFont)
                            .tracking(1.5)
                            .foregroundStyle(AppTheme.textSecondary)
                    }

                    Spacer()

                    HStack(spacing: 4) {
                        Text("Schedule")
                            .font(AppTheme.captionFont)
                            .foregroundStyle(AppTheme.primary)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(AppTheme.primary)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(todayPlannerDay?.focusBodyPart ?? "Chest & Triceps")
                        .font(AppTheme.largeTitleFont)
                        .foregroundStyle(AppTheme.text)
                        .lineLimit(1)

                    if let desc = todayPlannerDay?.targetExercisesDescription, !desc.isEmpty {
                        Text(desc)
                            .font(AppTheme.subheadlineFont)
                            .foregroundStyle(AppTheme.textSecondary)
                            .lineLimit(2)
                    }
                }
            }
            .padding(AppTheme.Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.card))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Radii.card)
                    .strokeBorder(AppTheme.primary.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Fasting Glance Card
    private var fastingGlanceCard: some View {
        Button {
            showingFastingTracker = true
        } label: {
            HStack(spacing: AppTheme.Spacing.md) {
                ZStack {
                    Circle()
                        .stroke(AppTheme.surfaceRaised, lineWidth: 5)
                        .frame(width: 52, height: 52)

                    Circle()
                        .trim(from: 0, to: fasting.isFastingActive ? fasting.progress : 0)
                        .stroke(AppTheme.primary, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .frame(width: 52, height: 52)

                    Image(systemName: fasting.isEatingWindowOpen ? "fork.knife" : "timer")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(fasting.isEatingWindowOpen ? AppTheme.carbsColor : AppTheme.primary)
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text("INTERMITTENT FASTING")
                            .font(AppTheme.eyebrowFont)
                            .tracking(1.5)
                            .foregroundStyle(AppTheme.textSecondary)

                        if !subManager.isPro {
                            Text("PRO")
                                .font(.system(size: 9, weight: .black))
                                .foregroundStyle(AppTheme.onPrimary)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1)
                                .background(AppTheme.primary)
                                .clipShape(Capsule())
                        }
                    }

                    Text(fasting.isFastingActive ? "\(fasting.currentFastingState.rawValue) · \(fasting.remainingTimeFormatted)" : "Start \(fasting.selectedProtocol.rawValue)")
                        .font(AppTheme.headlineFont)
                        .foregroundStyle(AppTheme.text)

                    Text(fasting.isFastingActive ? (fasting.isEatingWindowOpen ? "Eating window active" : "Target: \(fasting.fastTargetEndTime.formatted(.dateTime.hour().minute()))") : "Tap to track fast & eating notifications")
                        .font(AppTheme.captionFont)
                        .foregroundStyle(AppTheme.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppTheme.primary)
            }
            .padding(AppTheme.Spacing.md)
            .background(AppTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.card))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Radii.card)
                    .strokeBorder(AppTheme.hairline)
            )
        }
        .buttonStyle(.plain)
    }

    private var quickActionsGrid: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
            Text("QUICK LOG")
                .font(AppTheme.eyebrowFont)
                .tracking(1.5)
                .foregroundStyle(AppTheme.textSecondary)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: AppTheme.Spacing.xs) {
                actionTile(
                    title: "Workout",
                    icon: "dumbbell.fill",
                    color: AppTheme.primary,
                    action: { showingWorkoutLogger = true }
                )
                actionTile(
                    title: "Run",
                    icon: "figure.run",
                    color: AppTheme.carbsColor,
                    action: { showingRunLogger = true }
                )
                actionTile(
                    title: "Scan Meal",
                    icon: "camera.fill",
                    color: AppTheme.proteinColor,
                    action: { showingCameraScanner = true }
                )
                actionTile(
                    title: "Fasting",
                    icon: "timer",
                    color: AppTheme.fatColor,
                    action: { showingFastingTracker = true }
                )
            }
        }
    }

    private func actionTile(title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: AppTheme.Spacing.xs) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.18))
                        .frame(width: 44, height: 44)
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(color)
                }

                Text(title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(AppTheme.text)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppTheme.Spacing.sm)
            .background(AppTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.card))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Radii.card)
                    .strokeBorder(AppTheme.hairline)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Progress Report Banner
    private var progressReportBanner: some View {
        Button {
            showingProgressReport = true
        } label: {
            HStack(spacing: AppTheme.Spacing.md) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(AppTheme.primary.opacity(0.15))
                        .frame(width: 42, height: 42)
                    Image(systemName: "chart.xyaxis.line")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(AppTheme.primary)
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text("In-Depth Progress Report")
                            .font(AppTheme.headlineFont)
                            .foregroundStyle(AppTheme.text)

                        if !subManager.isPro {
                            Text("PRO")
                                .font(.system(size: 9, weight: .black))
                                .foregroundStyle(AppTheme.onPrimary)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1)
                                .background(AppTheme.primary)
                                .clipShape(Capsule())
                        }
                    }

                    Text("Strength curves, macro index & AI performance summary")
                        .font(AppTheme.captionFont)
                        .foregroundStyle(AppTheme.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppTheme.primary)
            }
            .padding(AppTheme.Spacing.md)
            .background(AppTheme.surfaceRaised)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.card))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Radii.card)
                    .strokeBorder(AppTheme.hairline)
            )
        }
        .buttonStyle(.plain)
    }

    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            HStack {
                Text("RECENT SESSIONS")
                    .font(AppTheme.eyebrowFont)
                    .tracking(1.5)
                    .foregroundStyle(AppTheme.textSecondary)
                Spacer()
            }

            if workoutSessions.isEmpty && runEntries.isEmpty {
                VStack(spacing: AppTheme.Spacing.xs) {
                    Image(systemName: "flame")
                        .font(.system(size: 32))
                        .foregroundStyle(AppTheme.textMuted)
                    Text("No sessions recorded yet")
                        .font(AppTheme.headlineFont)
                        .foregroundStyle(AppTheme.textSecondary)
                    Text("Log your first workout or run using the quick buttons above.")
                        .font(AppTheme.captionFont)
                        .foregroundStyle(AppTheme.textMuted)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(AppTheme.Spacing.xl)
                .background(AppTheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.card))
            } else {
                VStack(spacing: AppTheme.Spacing.xs) {
                    ForEach(workoutSessions.prefix(3)) { session in
                        HStack(spacing: AppTheme.Spacing.sm) {
                            ZStack {
                                RoundedRectangle(cornerRadius: AppTheme.Radii.tag)
                                    .fill(AppTheme.primary.opacity(0.15))
                                    .frame(width: 40, height: 40)
                                Image(systemName: "dumbbell.fill")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundStyle(AppTheme.primary)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text(session.title)
                                    .font(AppTheme.headlineFont)
                                    .foregroundStyle(AppTheme.text)
                                Text("\(session.exercises.count) exercises · \(session.totalSets) sets · \(Int(session.totalVolumeLbs)) lbs")
                                    .font(AppTheme.captionFont)
                                    .foregroundStyle(AppTheme.textSecondary)
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: 2) {
                                Text("\(session.durationMinutes) min")
                                    .font(AppTheme.captionFont)
                                    .bold()
                                    .foregroundStyle(AppTheme.text)
                                Text(session.date.formatted(.dateTime.month().day()))
                                    .font(AppTheme.captionFont)
                                    .foregroundStyle(AppTheme.textMuted)
                            }
                        }
                        .padding(AppTheme.Spacing.sm)
                        .background(AppTheme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.card))
                    }

                    ForEach(runEntries.prefix(2)) { run in
                        HStack(spacing: AppTheme.Spacing.sm) {
                            ZStack {
                                RoundedRectangle(cornerRadius: AppTheme.Radii.tag)
                                    .fill(AppTheme.carbsColor.opacity(0.15))
                                    .frame(width: 40, height: 40)
                                Image(systemName: "figure.run")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundStyle(AppTheme.carbsColor)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text(run.title)
                                    .font(AppTheme.headlineFont)
                                    .foregroundStyle(AppTheme.text)
                                Text("\(String(format: "%.2f", run.distanceMiles)) mi · Pace \(run.formattedPace)")
                                    .font(AppTheme.captionFont)
                                    .foregroundStyle(AppTheme.textSecondary)
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: 2) {
                                Text(run.formattedDuration)
                                    .font(AppTheme.captionFont)
                                    .bold()
                                    .foregroundStyle(AppTheme.text)
                                Text(run.date.formatted(.dateTime.month().day()))
                                    .font(AppTheme.captionFont)
                                    .foregroundStyle(AppTheme.textMuted)
                            }
                        }
                        .padding(AppTheme.Spacing.sm)
                        .background(AppTheme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.card))
                    }
                }
            }
        }
    }
}
