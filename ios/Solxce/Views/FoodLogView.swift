// Views/FoodLogView.swift
import SwiftUI
import SwiftData

struct FoodLogView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \FoodEntry.date, order: .reverse) private var allFoods: [FoodEntry]
    @Query private var macroTargets: [MacroTarget]
    @ObservedObject private var subManager = SubscriptionManager.shared

    @State private var foodName: String = ""
    @State private var mealType: String = "Breakfast"
    @State private var calories: Int = 350
    @State private var protein: Int = 25
    @State private var carbs: Int = 30
    @State private var fat: Int = 10
    @State private var showCameraScanner: Bool = false
    @State private var showPaywall: Bool = false

    let mealOptions = ["Breakfast", "Lunch", "Dinner", "Snack"]

    var todayFoods: [FoodEntry] {
        let calendar = Calendar.current
        return allFoods.filter { calendar.isDateInToday($0.date) }
    }

    var totalCalories: Int { todayFoods.reduce(0) { $0 + $1.calories } }
    var totalProtein: Int { todayFoods.reduce(0) { $0 + $1.proteinGrams } }
    var totalCarbs: Int { todayFoods.reduce(0) { $0 + $1.carbsGrams } }
    var totalFat: Int { todayFoods.reduce(0) { $0 + $1.fatGrams } }

    var target: MacroTarget? { macroTargets.first }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.lg) {
                    // Macro Summary Progress Bar
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                        Text("TODAY'S TOTALS")
                            .font(AppTheme.eyebrowFont)
                            .tracking(1.5)
                            .foregroundStyle(AppTheme.textSecondary)

                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("\(totalCalories)")
                                    .font(AppTheme.heroNumeralFont)
                                    .foregroundStyle(AppTheme.caloriesColor)
                                    + Text(" / \(target?.dailyCalories ?? 2400) kcal")
                                    .font(AppTheme.subheadlineFont)
                                    .foregroundStyle(AppTheme.textSecondary)
                            }
                            Spacer()
                        }

                        HStack(spacing: AppTheme.Spacing.xs) {
                            macroPill(label: "Protein", val: totalProtein, goal: target?.dailyProteinGrams ?? 180, color: AppTheme.proteinColor)
                            macroPill(label: "Carbs", val: totalCarbs, goal: target?.dailyCarbsGrams ?? 240, color: AppTheme.carbsColor)
                            macroPill(label: "Fat", val: totalFat, goal: target?.dailyFatGrams ?? 70, color: AppTheme.fatColor)
                        }
                    }
                    .padding(AppTheme.Spacing.md)
                    .background(AppTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.card))

                    // AI Camera Fast Log CTA Banner
                    cameraFastLogBanner

                    // Quick Add Food Form
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                        Text("MANUAL FOOD ENTRY")
                            .font(AppTheme.eyebrowFont)
                            .tracking(1.5)
                            .foregroundStyle(AppTheme.textSecondary)

                        VStack(spacing: AppTheme.Spacing.xs) {
                            TextField("Food name (e.g. Oatmeal & Berries)", text: $foodName)
                                .font(AppTheme.bodyFont)
                                .padding(AppTheme.Spacing.sm)
                                .background(AppTheme.field)
                                .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.tag))
                                .foregroundStyle(AppTheme.text)

                            Picker("Meal", selection: $mealType) {
                                ForEach(mealOptions, id: \.self) {
                                    Text($0).tag($0)
                                }
                            }
                            .pickerStyle(.segmented)
                            .padding(.vertical, 4)

                            HStack(spacing: AppTheme.Spacing.xs) {
                                macroInput(label: "Calories", value: $calories, unit: "kcal", color: AppTheme.caloriesColor)
                                macroInput(label: "Protein", value: $protein, unit: "g", color: AppTheme.proteinColor)
                            }

                            HStack(spacing: AppTheme.Spacing.xs) {
                                macroInput(label: "Carbs", value: $carbs, unit: "g", color: AppTheme.carbsColor)
                                macroInput(label: "Fat", value: $fat, unit: "g", color: AppTheme.fatColor)
                            }

                            Button(action: addFoodItem) {
                                HStack {
                                    Image(systemName: "plus")
                                    Text("Log Food Item")
                                }
                                .font(AppTheme.headlineFont)
                                .foregroundStyle(AppTheme.onPrimary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, AppTheme.Spacing.sm)
                                .background(AppTheme.primary)
                                .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.button))
                            }
                            .disabled(foodName.isEmpty)
                            .padding(.top, 4)
                        }
                    }
                    .padding(AppTheme.Spacing.md)
                    .background(AppTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.card))

                    // Today's Logged Items
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                        Text("LOGGED TODAY (\(todayFoods.count))")
                            .font(AppTheme.eyebrowFont)
                            .tracking(1.5)
                            .foregroundStyle(AppTheme.textSecondary)

                        if todayFoods.isEmpty {
                            Text("No food items logged for today.")
                                .font(AppTheme.captionFont)
                                .foregroundStyle(AppTheme.textMuted)
                        } else {
                            ForEach(todayFoods) { food in
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(food.name)
                                            .font(AppTheme.headlineFont)
                                            .foregroundStyle(AppTheme.text)
                                        Text("\(food.mealType) · \(food.proteinGrams)P · \(food.carbsGrams)C · \(food.fatGrams)F")
                                            .font(AppTheme.captionFont)
                                            .foregroundStyle(AppTheme.textSecondary)
                                    }

                                    Spacer()

                                    Text("\(food.calories) kcal")
                                        .font(AppTheme.subheadlineFont)
                                        .bold()
                                        .foregroundStyle(AppTheme.primary)

                                    Button(action: {
                                        modelContext.delete(food)
                                        try? modelContext.save()
                                    }) {
                                        Image(systemName: "trash")
                                            .font(.system(size: 13))
                                            .foregroundStyle(AppTheme.accent)
                                            .padding(.leading, 8)
                                    }
                                }
                                .padding(AppTheme.Spacing.sm)
                                .background(AppTheme.surface)
                                .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.tag))
                            }
                        }
                    }
                }
                .padding(.horizontal, AppTheme.Spacing.screenMargin)
                .padding(.top, AppTheme.Spacing.sm)
                .padding(.bottom, AppTheme.Spacing.xxl)
            }
            .background(AppTheme.ground.ignoresSafeArea())
            .navigationTitle("Macro Food Log")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showCameraScanner = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "camera.fill")
                            Text("Scan")
                        }
                        .font(AppTheme.subheadlineFont)
                        .foregroundStyle(AppTheme.primary)
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .font(AppTheme.headlineFont)
                        .foregroundStyle(AppTheme.primary)
                }
            }
            .sheet(isPresented: $showCameraScanner) {
                CameraFoodScannerView()
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
        }
    }

    private var cameraFastLogBanner: some View {
        Button {
            showCameraScanner = true
        } label: {
            HStack(spacing: AppTheme.Spacing.md) {
                ZStack {
                    Circle()
                        .fill(AppTheme.primary.opacity(0.18))
                        .frame(width: 44, height: 44)
                    Image(systemName: "camera.viewfinder")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(AppTheme.primary)
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text("Log Faster with AI Camera")
                            .font(AppTheme.headlineFont)
                            .foregroundStyle(AppTheme.text)
                        if !subManager.isPro {
                            Text("PRO")
                                .font(.system(size: 10, weight: .black))
                                .foregroundStyle(AppTheme.onPrimary)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(AppTheme.primary)
                                .clipShape(Capsule())
                        }
                    }

                    Text("Snap a photo to calculate macros instantly")
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
                    .strokeBorder(AppTheme.primary.opacity(0.4), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func macroPill(label: String, val: Int, goal: Int, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(AppTheme.eyebrowFont)
                .foregroundStyle(AppTheme.textSecondary)
            Text("\(val)/\(goal)g")
                .font(AppTheme.captionFont)
                .bold()
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity)
        .padding(6)
        .background(AppTheme.surfaceRaised)
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    private func macroInput(label: String, value: Binding<Int>, unit: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(AppTheme.captionFont)
                .foregroundStyle(color)
            HStack {
                TextField(label, value: value, format: .number)
                    .keyboardType(.numberPad)
                    .foregroundStyle(AppTheme.text)
                Text(unit)
                    .font(AppTheme.captionFont)
                    .foregroundStyle(AppTheme.textMuted)
            }
            .padding(6)
            .background(AppTheme.field)
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
    }

    private func addFoodItem() {
        let entry = FoodEntry(
            name: foodName,
            mealType: mealType,
            calories: calories,
            proteinGrams: protein,
            carbsGrams: carbs,
            fatGrams: fat,
            date: Date()
        )
        modelContext.insert(entry)
        try? modelContext.save()
        foodName = ""
    }
}
