// Views/CameraFoodScannerView.swift
import SwiftUI
import SwiftData

struct RecognizedMealPreset: Identifiable {
    let id = UUID()
    let name: String
    let category: String
    let calories: Int
    let protein: Int
    let carbs: Int
    let fat: Int
    let icon: String
}

struct CameraFoodScannerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @ObservedObject private var subManager = SubscriptionManager.shared

    @State private var isScanning: Bool = false
    @State private var scanCompleted: Bool = false
    @State private var selectedMeal: RecognizedMealPreset?
    @State private var customMealName: String = ""
    @State private var calories: Int = 450
    @State private var protein: Int = 38
    @State private var carbs: Int = 45
    @State private var fat: Int = 12
    @State private var mealType: String = "Lunch"
    @State private var showPaywall: Bool = false

    let sampleCatalog: [RecognizedMealPreset] = [
        RecognizedMealPreset(name: "Grilled Chicken, Rice & Broccoli", category: "High Protein", calories: 520, protein: 48, carbs: 55, fat: 8, icon: "fork.knife"),
        RecognizedMealPreset(name: "Steak, Sweet Potato & Asparagus", category: "Strength Fuel", calories: 680, protein: 54, carbs: 48, fat: 22, icon: "flame.fill"),
        RecognizedMealPreset(name: "Salmon Bowl with Quinoa & Avocado", category: "Healthy Fats", calories: 610, protein: 42, carbs: 40, fat: 26, icon: "leaf.fill"),
        RecognizedMealPreset(name: "Greek Yogurt Bowl with Berries & Honey", category: "Quick Breakfast", calories: 340, protein: 28, carbs: 42, fat: 5, icon: "cup.and.saucer.fill"),
        RecognizedMealPreset(name: "Whey Protein Shake & Banana", category: "Post Workout", calories: 310, protein: 32, carbs: 36, fat: 3, icon: "bolt.fill"),
        RecognizedMealPreset(name: "Eggs, Sourdough Toast & Turkey Bacon", category: "Power Breakfast", calories: 490, protein: 36, carbs: 32, fat: 18, icon: "sun.max.fill")
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.ground.ignoresSafeArea()

                if !subManager.isPro {
                    proLockedGate
                } else {
                    scannerContent
                }
            }
            .navigationTitle("AI Camera Scanner")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(AppTheme.textSecondary)
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
                Image(systemName: "camera.viewfinder")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundStyle(AppTheme.primary)
            }

            VStack(spacing: AppTheme.Spacing.xs) {
                Text("Instant AI Food Logging")
                    .font(AppTheme.displayFont)
                    .foregroundStyle(AppTheme.text)
                    .multilineTextAlignment(.center)

                Text("Point your camera at any meal to instantly estimate calories and macronutrients without manual typing.")
                    .font(AppTheme.bodyFont)
                    .foregroundStyle(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppTheme.Spacing.lg)
            }

            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                featureCheck("Instant calorie & macro estimation in < 2 seconds")
                featureCheck("Recognizes portion sizes and protein densities")
                featureCheck("One-tap auto-sync to your daily macro rings")
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

    // MARK: - Active Camera Scanner
    private var scannerContent: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            // Viewfinder Surface
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(AppTheme.surfaceRaised)
                    .frame(height: 280)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .strokeBorder(isScanning ? AppTheme.primary : AppTheme.hairline, lineWidth: 2)
                    )

                if isScanning {
                    // Scanning animation line
                    VStack {
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.clear, AppTheme.primary, Color.clear],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(height: 3)
                            .shadow(color: AppTheme.primary, radius: 8)
                    }
                    .frame(maxHeight: .infinity)

                    VStack(spacing: 8) {
                        ProgressView()
                            .tint(AppTheme.primary)
                            .scaleEffect(1.3)
                        Text("Analyzing meal & calculating macros...")
                            .font(AppTheme.headlineFont)
                            .foregroundStyle(AppTheme.text)
                    }
                } else if let meal = selectedMeal {
                    VStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 38))
                            .foregroundStyle(AppTheme.primary)
                        Text(meal.name)
                            .font(AppTheme.titleFont)
                            .foregroundStyle(AppTheme.text)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        Text("\(meal.calories) kcal · \(meal.protein)g Protein")
                            .font(AppTheme.subheadlineFont)
                            .foregroundStyle(AppTheme.primary)
                    }
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "camera.viewfinder")
                            .font(.system(size: 48))
                            .foregroundStyle(AppTheme.primary)
                        Text("Align meal in viewfinder")
                            .font(AppTheme.headlineFont)
                            .foregroundStyle(AppTheme.text)
                        Text("Tap 'Capture & Scan' or choose a quick meal preset below.")
                            .font(AppTheme.captionFont)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                }

                // Four corner viewfinder guides
                viewfinderCorners
            }
            .padding(.horizontal, AppTheme.Spacing.screenMargin)

            // Capture CTA
            Button {
                simulateCameraScan()
            } label: {
                HStack {
                    Image(systemName: "camera.fill")
                    Text(isScanning ? "Scanning..." : "Capture & Scan Meal")
                        .bold()
                }
                .font(AppTheme.headlineFont)
                .foregroundStyle(AppTheme.onPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(AppTheme.primary)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.button))
            }
            .disabled(isScanning)
            .padding(.horizontal, AppTheme.Spacing.screenMargin)

            // Quick Recognition Presets
            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                    Text("QUICK MEAL SUGGESTIONS")
                        .font(AppTheme.eyebrowFont)
                        .tracking(1.5)
                        .foregroundStyle(AppTheme.textSecondary)
                        .padding(.horizontal, AppTheme.Spacing.screenMargin)

                    ForEach(sampleCatalog) { meal in
                        Button {
                            applyMeal(meal)
                        } label: {
                            HStack {
                                ZStack {
                                    Circle()
                                        .fill(AppTheme.primary.opacity(0.15))
                                        .frame(width: 40, height: 40)
                                    Image(systemName: meal.icon)
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundStyle(AppTheme.primary)
                                }

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(meal.name)
                                        .font(AppTheme.headlineFont)
                                        .foregroundStyle(AppTheme.text)
                                    Text("\(meal.category) • \(meal.protein)P • \(meal.carbs)C • \(meal.fat)F")
                                        .font(AppTheme.captionFont)
                                        .foregroundStyle(AppTheme.textSecondary)
                                }

                                Spacer()

                                Text("\(meal.calories) kcal")
                                    .font(AppTheme.subheadlineFont)
                                    .bold()
                                    .foregroundStyle(AppTheme.caloriesColor)
                            }
                            .padding(AppTheme.Spacing.sm)
                            .background(AppTheme.surface)
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.card))
                            .overlay(
                                RoundedRectangle(cornerRadius: AppTheme.Radii.card)
                                    .strokeBorder(selectedMeal?.name == meal.name ? AppTheme.primary : AppTheme.hairline, lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, AppTheme.Spacing.screenMargin)
                    }

                    if scanCompleted {
                        // Confirm and Log Section
                        VStack(spacing: AppTheme.Spacing.sm) {
                            Text("CONFIRM SCANNED NUTRITION")
                                .font(AppTheme.eyebrowFont)
                                .tracking(1.5)
                                .foregroundStyle(AppTheme.textSecondary)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            HStack(spacing: AppTheme.Spacing.xs) {
                                macroBadge("Calories", val: "\(calories) kcal", color: AppTheme.caloriesColor)
                                macroBadge("Protein", val: "\(protein)g", color: AppTheme.proteinColor)
                                macroBadge("Carbs", val: "\(carbs)g", color: AppTheme.carbsColor)
                                macroBadge("Fat", val: "\(fat)g", color: AppTheme.fatColor)
                            }

                            Button {
                                commitScannedMeal()
                            } label: {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                    Text("Add to Today's Food Log")
                                        .bold()
                                }
                                .font(AppTheme.headlineFont)
                                .foregroundStyle(AppTheme.onPrimary)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(AppTheme.primary)
                                .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.button))
                            }
                        }
                        .padding(AppTheme.Spacing.md)
                        .background(AppTheme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.card))
                        .padding(.horizontal, AppTheme.Spacing.screenMargin)
                        .padding(.top, AppTheme.Spacing.sm)
                    }
                }
                .padding(.bottom, AppTheme.Spacing.xxl)
            }
        }
    }

    private var viewfinderCorners: some View {
        GeometryReader { geo in
            let length: CGFloat = 24
            let stroke: CGFloat = 3
            ZStack {
                // Top Left
                Path { path in
                    path.move(to: CGPoint(x: 12, y: 12 + length))
                    path.addLine(to: CGPoint(x: 12, y: 12))
                    path.addLine(to: CGPoint(x: 12 + length, y: 12))
                }.stroke(AppTheme.primary, lineWidth: stroke)

                // Top Right
                Path { path in
                    path.move(to: CGPoint(x: geo.size.width - 12 - length, y: 12))
                    path.addLine(to: CGPoint(x: geo.size.width - 12, y: 12))
                    path.addLine(to: CGPoint(x: geo.size.width - 12, y: 12 + length))
                }.stroke(AppTheme.primary, lineWidth: stroke)

                // Bottom Left
                Path { path in
                    path.move(to: CGPoint(x: 12, y: geo.size.height - 12 - length))
                    path.addLine(to: CGPoint(x: 12, y: geo.size.height - 12))
                    path.addLine(to: CGPoint(x: 12 + length, y: geo.size.height - 12))
                }.stroke(AppTheme.primary, lineWidth: stroke)

                // Bottom Right
                Path { path in
                    path.move(to: CGPoint(x: geo.size.width - 12 - length, y: geo.size.height - 12))
                    path.addLine(to: CGPoint(x: geo.size.width - 12, y: geo.size.height - 12))
                    path.addLine(to: CGPoint(x: geo.size.width - 12, y: geo.size.height - 12 - length))
                }.stroke(AppTheme.primary, lineWidth: stroke)
            }
        }
    }

    private func macroBadge(_ label: String, val: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(AppTheme.eyebrowFont)
                .foregroundStyle(AppTheme.textSecondary)
            Text(val)
                .font(AppTheme.captionFont)
                .bold()
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity)
        .padding(6)
        .background(AppTheme.surfaceRaised)
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    private func simulateCameraScan() {
        isScanning = true
        let randomPreset = sampleCatalog.randomElement() ?? sampleCatalog[0]
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            isScanning = false
            applyMeal(randomPreset)
        }
    }

    private func applyMeal(_ meal: RecognizedMealPreset) {
        selectedMeal = meal
        customMealName = meal.name
        calories = meal.calories
        protein = meal.protein
        carbs = meal.carbs
        fat = meal.fat
        scanCompleted = true
    }

    private func commitScannedMeal() {
        let entry = FoodEntry(
            name: customMealName.isEmpty ? (selectedMeal?.name ?? "Scanned Meal") : customMealName,
            mealType: mealType,
            calories: calories,
            proteinGrams: protein,
            carbsGrams: carbs,
            fatGrams: fat,
            date: Date()
        )
        modelContext.insert(entry)
        try? modelContext.save()
        dismiss()
    }
}
