// Views/FuelTabView.swift
import SwiftUI
import SwiftData

/// Dedicated Fuel Tab (Nutrition, Macros, AI Camera Scanner, Fasting Engine)
struct FuelTabView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \FoodEntry.date, order: .reverse) private var allFoods: [FoodEntry]
    @Query private var macroTargets: [MacroTarget]
    @ObservedObject private var fasting = FastingManager.shared
    @ObservedObject private var subManager = SubscriptionManager.shared

    @State private var showingCameraScanner = false
    @State private var showingFoodLogger = false
    @State private var showingFastingTracker = false
    @State private var showingPaywall = false

    var todayFoods: [FoodEntry] {
        let calendar = Calendar.current
        return allFoods.filter { calendar.isDateInToday($0.date) }
    }

    var target: MacroTarget? {
        macroTargets.first
    }

    var totalCalories: Int { todayFoods.reduce(0) { $0 + $1.calories } }
    var totalProtein: Int { todayFoods.reduce(0) { $0 + $1.proteinGrams } }
    var totalCarbs: Int { todayFoods.reduce(0) { $0 + $1.carbsGrams } }
    var totalFat: Int { todayFoods.reduce(0) { $0 + $1.fatGrams } }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.lg) {
                    // Header & Fuel Title
                    headerHeroSection

                    // Macro Rings Visual Card
                    MacroRingsCard(
                        target: target,
                        todayFoods: todayFoods,
                        onFoodLogTap: { showingFoodLogger = true }
                    )

                    // AI Camera Fast Scanner CTA
                    cameraScannerBanner

                    // Intermittent Fasting Live Dial
                    fastingEngineCard

                    // Quick Log Manual Button
                    manualFoodLogCard

                    // Today's Meals Stream
                    todaysMealsStream
                }
                .padding(.horizontal, AppTheme.Spacing.screenMargin)
                .padding(.top, AppTheme.Spacing.xs)
                .padding(.bottom, AppTheme.Spacing.xxl + 40)
            }
            .background(AppTheme.ground.ignoresSafeArea())
            .sheet(isPresented: $showingCameraScanner) {
                CameraFoodScannerView()
            }
            .sheet(isPresented: $showingFoodLogger) {
                FoodLogView()
            }
            .sheet(isPresented: $showingFastingTracker) {
                FastingTrackerView()
            }
            .sheet(isPresented: $showingPaywall) {
                PaywallView()
            }
        }
    }

    // MARK: - Header
    private var headerHeroSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
            HStack {
                Text("NUTRITION & MACROS")
                    .font(AppTheme.eyebrowFont)
                    .tracking(2.0)
                    .foregroundStyle(AppTheme.textSecondary)
                Spacer()
                Text("TODAY")
                    .font(AppTheme.captionFont.weight(.heavy))
                    .foregroundStyle(AppTheme.accent)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(AppTheme.accent.opacity(0.15))
                    .clipShape(Capsule())
            }

            Text("Fuel the Work.")
                .font(AppTheme.largeTitleFont)
                .foregroundStyle(AppTheme.text)
                + Text(" Track Precision.")
                .font(AppTheme.largeTitleFont)
                .foregroundStyle(AppTheme.accent)
        }
    }

    // MARK: - AI Camera Scanner Banner
    private var cameraScannerBanner: some View {
        Button {
            if subManager.isPro {
                showingCameraScanner = true
            } else {
                showingPaywall = true
            }
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: AppTheme.Radii.tag)
                        .fill(
                            LinearGradient(
                                colors: [AppTheme.accent, AppTheme.accent.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 48, height: 48)

                    Image(systemName: "camera.viewfinder")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(Color.black)
                }

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text("AI CAMERA SCANNER")
                            .font(AppTheme.eyebrowFont)
                            .tracking(1.0)
                            .foregroundStyle(AppTheme.accent)

                        if !subManager.isPro {
                            Text("PRO")
                                .font(.system(size: 9, weight: .black))
                                .foregroundStyle(Color.black)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(AppTheme.accent)
                                .clipShape(Capsule())
                        }
                    }

                    Text("Snap meal to estimate macros")
                        .font(AppTheme.subheadlineFont.weight(.bold))
                        .foregroundStyle(AppTheme.text)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(AppTheme.textSecondary)
            }
            .padding(AppTheme.Spacing.md)
            .background(AppTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.card))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Radii.card)
                    .stroke(AppTheme.accent.opacity(0.4), lineWidth: 1)
            )
        }
    }

    // MARK: - Fasting Engine Card
    private var fastingEngineCard: some View {
        Button {
            showingFastingTracker = true
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .stroke(AppTheme.surfaceRaised, lineWidth: 4)
                        .frame(width: 46, height: 46)

                    Circle()
                        .trim(from: 0, to: fasting.isFastingActive ? fasting.progress : 0)
                        .stroke(AppTheme.carbsColor, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .frame(width: 46, height: 46)

                    Image(systemName: fasting.isEatingWindowOpen ? "fork.knife" : "timer")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(fasting.isEatingWindowOpen ? AppTheme.carbsColor : AppTheme.primary)
                }

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text("INTERMITTENT FASTING")
                            .font(AppTheme.eyebrowFont)
                            .tracking(1.0)
                            .foregroundStyle(AppTheme.carbsColor)

                        Circle()
                            .fill(fasting.isFastingActive ? AppTheme.accent : AppTheme.textSecondary)
                            .frame(width: 6, height: 6)
                    }

                    Text(fasting.isFastingActive ? "\(fasting.currentFastingState.rawValue) · \(fasting.remainingTimeFormatted)" : "Start \(fasting.selectedProtocol.rawValue)")
                        .font(AppTheme.subheadlineFont.weight(.bold))
                        .foregroundStyle(AppTheme.text)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(AppTheme.textSecondary)
            }
            .padding(AppTheme.Spacing.md)
            .background(AppTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.card))
        }
    }

    // MARK: - Manual Food Log Card
    private var manualFoodLogCard: some View {
        Button {
            showingFoodLogger = true
        } label: {
            HStack {
                HStack(spacing: 10) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(AppTheme.primary)
                    Text("Log Food / Drink Manually")
                        .font(AppTheme.headlineFont)
                        .foregroundStyle(AppTheme.text)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(AppTheme.textSecondary)
            }
            .padding(AppTheme.Spacing.md)
            .background(AppTheme.surfaceRaised)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.tag))
        }
    }

    // MARK: - Today's Meals Stream
    private var todaysMealsStream: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text("LOGGED TODAY (\(todayFoods.count))")
                .font(AppTheme.eyebrowFont)
                .tracking(1.5)
                .foregroundStyle(AppTheme.textSecondary)

            if todayFoods.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "fork.knife")
                        .font(.system(size: 28))
                        .foregroundStyle(AppTheme.textSecondary.opacity(0.4))
                    Text("No food logged today")
                        .font(AppTheme.headlineFont)
                        .foregroundStyle(AppTheme.text)
                    Text("Use the AI camera or manual entry to log your nutrition.")
                        .font(AppTheme.captionFont)
                        .foregroundStyle(AppTheme.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 28)
                .background(AppTheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.card))
            } else {
                ForEach(todayFoods) { food in
                    foodRow(food)
                }
            }
        }
    }

    private func foodRow(_ food: FoodEntry) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(food.name)
                    .font(AppTheme.headlineFont)
                    .foregroundStyle(AppTheme.text)

                HStack(spacing: 8) {
                    Text(food.mealType)
                        .font(AppTheme.captionFont.weight(.semibold))
                        .foregroundStyle(AppTheme.textSecondary)

                    Text("•")
                        .foregroundStyle(AppTheme.textSecondary.opacity(0.4))

                    Text("P: \(food.proteinGrams)g  C: \(food.carbsGrams)g  F: \(food.fatGrams)g")
                        .font(AppTheme.captionFont)
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }

            Spacer()

            Text("\(food.calories) kcal")
                .font(AppTheme.headlineFont.weight(.black))
                .foregroundStyle(AppTheme.caloriesColor)
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.card))
    }
}
