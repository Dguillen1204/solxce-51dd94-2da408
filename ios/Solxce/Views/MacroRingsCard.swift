// Views/MacroRingsCard.swift
import SwiftUI

struct MacroRingsCard: View {
    let target: MacroTarget?
    let todayFoods: [FoodEntry]
    var onFoodLogTap: () -> Void

    var consumedCalories: Int {
        todayFoods.reduce(0) { $0 + $1.calories }
    }

    var consumedProtein: Int {
        todayFoods.reduce(0) { $0 + $1.proteinGrams }
    }

    var consumedCarbs: Int {
        todayFoods.reduce(0) { $0 + $1.carbsGrams }
    }

    var consumedFat: Int {
        todayFoods.reduce(0) { $0 + $1.fatGrams }
    }

    var goalCalories: Int { target?.dailyCalories ?? 2400 }
    var goalProtein: Int { target?.dailyProteinGrams ?? 180 }
    var goalCarbs: Int { target?.dailyCarbsGrams ?? 240 }
    var goalFat: Int { target?.dailyFatGrams ?? 70 }

    var calProgress: Double {
        guard goalCalories > 0 else { return 0 }
        return min(Double(consumedCalories) / Double(goalCalories), 1.0)
    }

    var proteinProgress: Double {
        guard goalProtein > 0 else { return 0 }
        return min(Double(consumedProtein) / Double(goalProtein), 1.0)
    }

    var carbsProgress: Double {
        guard goalCarbs > 0 else { return 0 }
        return min(Double(consumedCarbs) / Double(goalCarbs), 1.0)
    }

    var fatProgress: Double {
        guard goalFat > 0 else { return 0 }
        return min(Double(consumedFat) / Double(goalFat), 1.0)
    }

    var remainingCalories: Int {
        max(goalCalories - consumedCalories, 0)
    }

    var body: some View {
        Button(action: onFoodLogTap) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("DAILY NUTRITION")
                            .font(AppTheme.eyebrowFont)
                            .tracking(1.5)
                            .foregroundStyle(AppTheme.textSecondary)
                        Text("\(remainingCalories)")
                            .font(AppTheme.heroNumeralFont)
                            .monospacedDigit()
                            .foregroundStyle(AppTheme.text)
                            + Text(" kcal left")
                            .font(AppTheme.subheadlineFont)
                            .foregroundStyle(AppTheme.textSecondary)
                    }

                    Spacer()

                    // Visual concentric ring badge
                    ZStack {
                        // Background tracks
                        Circle()
                            .stroke(AppTheme.caloriesColor.opacity(0.18), lineWidth: 7)
                            .frame(width: 68, height: 68)
                        Circle()
                            .stroke(AppTheme.proteinColor.opacity(0.18), lineWidth: 6)
                            .frame(width: 50, height: 50)
                        Circle()
                            .stroke(AppTheme.carbsColor.opacity(0.18), lineWidth: 5)
                            .frame(width: 34, height: 34)

                        // Active arcs
                        Circle()
                            .trim(from: 0, to: CGFloat(calProgress))
                            .stroke(AppTheme.caloriesColor, style: StrokeStyle(lineWidth: 7, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                            .frame(width: 68, height: 68)

                        Circle()
                            .trim(from: 0, to: CGFloat(proteinProgress))
                            .stroke(AppTheme.proteinColor, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                            .frame(width: 50, height: 50)

                        Circle()
                            .trim(from: 0, to: CGFloat(carbsProgress))
                            .stroke(AppTheme.carbsColor, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                            .frame(width: 34, height: 34)
                    }
                    .frame(width: 76, height: 76)
                }

                // Macro pill row
                HStack(spacing: AppTheme.Spacing.xs) {
                    macroBar(
                        label: "Protein",
                        current: consumedProtein,
                        goal: goalProtein,
                        color: AppTheme.proteinColor
                    )
                    macroBar(
                        label: "Carbs",
                        current: consumedCarbs,
                        goal: goalCarbs,
                        color: AppTheme.carbsColor
                    )
                    macroBar(
                        label: "Fat",
                        current: consumedFat,
                        goal: goalFat,
                        color: AppTheme.fatColor
                    )
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
        .buttonStyle(.plain)
    }

    private func macroBar(label: String, current: Int, goal: Int, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(AppTheme.captionFont)
                    .foregroundStyle(AppTheme.textSecondary)
                Spacer()
                Text("\(current)/\(goal)g")
                    .font(AppTheme.captionFont)
                    .bold()
                    .foregroundStyle(AppTheme.text)
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(color.opacity(0.18))
                        .frame(height: 6)

                    Capsule()
                        .fill(color)
                        .frame(
                            width: min(proxy.size.width * CGFloat(min(Double(current) / max(Double(goal), 1), 1.0)), proxy.size.width),
                            height: 6
                        )
                }
            }
            .frame(height: 6)
        }
        .padding(8)
        .background(AppTheme.surfaceRaised)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.tag))
    }
}
