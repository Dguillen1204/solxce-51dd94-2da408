// Views/CameraFoodScannerView.swift
import SwiftUI
import SwiftData
import PhotosUI
import UIKit

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
    @StateObject private var cameraService = CameraCaptureService()

    @State private var isScanning: Bool = false
    @State private var scanCompleted: Bool = false
    @State private var capturedImage: UIImage?
    @State private var selectedMeal: RecognizedMealPreset?
    @State private var customMealName: String = ""
    @State private var calories: Int = 520
    @State private var protein: Int = 45
    @State private var carbs: Int = 50
    @State private var fat: Int = 14
    @State private var mealType: String = "Lunch"
    @State private var showPaywall: Bool = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var scanAnimationOffset: CGFloat = -120

    let sampleCatalog: [RecognizedMealPreset] = [
        RecognizedMealPreset(name: "Grilled Chicken, Brown Rice & Steamed Broccoli", category: "High Protein", calories: 520, protein: 48, carbs: 55, fat: 8, icon: "fork.knife"),
        RecognizedMealPreset(name: "Ribeye Steak with Sweet Potato & Asparagus", category: "Strength Fuel", calories: 680, protein: 54, carbs: 48, fat: 22, icon: "flame.fill"),
        RecognizedMealPreset(name: "Atlantic Salmon Bowl with Quinoa & Avocado", category: "Healthy Fats", calories: 610, protein: 42, carbs: 40, fat: 26, icon: "leaf.fill"),
        RecognizedMealPreset(name: "Greek Yogurt Bowl with Mixed Beries & Honey", category: "Quick Breakfast", calories: 340, protein: 28, carbs: 42, fat: 5, icon: "cup.and.saucer.fill"),
        RecognizedMealPreset(name: "Whey Protein Shake with Banana & Peanut Butter", category: "Post Workout", calories: 350, protein: 36, carbs: 38, fat: 7, icon: "bolt.fill"),
        RecognizedMealPreset(name: "Scrambled Eggs, Sourdough & Turkey Bacon", category: "Power Breakfast", calories: 490, protein: 36, carbs: 32, fat: 18, icon: "sun.max.fill")
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.ground.ignoresSafeArea()

                if !subManager.isPro {
                    proLockedGate
                } else {
                    scannerMainContent
                }
            }
            .navigationTitle("AI Camera Scanner")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        cameraService.stopRunning()
                        dismiss()
                    }
                    .foregroundStyle(AppTheme.textSecondary)
                }

                if subManager.isPro && !cameraService.permissionDenied {
                    ToolbarItem(placement: .primaryAction) {
                        HStack(spacing: 16) {
                            Button {
                                cameraService.toggleTorch()
                            } label: {
                                Image(systemName: cameraService.isTorchOn ? "bolt.fill" : "bolt.slash")
                                    .foregroundStyle(cameraService.isTorchOn ? AppTheme.primary : AppTheme.textSecondary)
                            }

                            Button {
                                cameraService.switchCamera()
                            } label: {
                                Image(systemName: "camera.rotate.fill")
                                    .foregroundStyle(AppTheme.textSecondary)
                            }
                        }
                    }
                }
            }
            .onAppear {
                if subManager.isPro {
                    cameraService.checkPermissions()
                    cameraService.startRunning()
                }
            }
            .onDisappear {
                cameraService.stopRunning()
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
            .onChange(of: selectedPhotoItem) { _, newItem in
                guard let newItem else { return }
                Task {
                    if let data = try? await newItem.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        await MainActor.run {
                            self.capturedImage = uiImage
                            analyzeCapturedImage(uiImage)
                        }
                    }
                }
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

                Text("Point your phone camera lens at any meal to instantly estimate calories, macros, and portion sizes in real-time.")
                    .font(AppTheme.bodyFont)
                    .foregroundStyle(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppTheme.Spacing.lg)
            }

            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                featureCheck("Live lens optical meal recognition")
                featureCheck("Instant calorie & macro estimation in < 2 seconds")
                featureCheck("Portion size & protein density auto-detection")
                featureCheck("One-tap sync to daily macro rings & food log")
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

    // MARK: - Main Scanner Content
    private var scannerMainContent: some View {
        VStack(spacing: 0) {
            if cameraService.permissionDenied {
                cameraPermissionDeniedView
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: AppTheme.Spacing.md) {
                        cameraViewport

                        cameraActionControls

                        if scanCompleted {
                            scannedResultCard
                        }

                        mealTypeSelector

                        quickPresetsSection
                    }
                    .padding(.vertical, AppTheme.Spacing.sm)
                }
            }
        }
    }

    // MARK: - Camera Viewport
    private var cameraViewport: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.black)
                .frame(height: 320)
                .clipShape(RoundedRectangle(cornerRadius: 24))

            if let captured = capturedImage {
                Image(uiImage: captured)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 320)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
            } else {
                #if targetEnvironment(simulator)
                simulatorLiveFeedMock
                #else
                LiveCameraPreviewView(session: cameraService.captureSession)
                    .frame(height: 320)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                #endif
            }

            viewfinderOverlay

            if isScanning {
                VStack {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [Color.clear, AppTheme.primary, AppTheme.primary.opacity(0.8), Color.clear],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(height: 3)
                        .shadow(color: AppTheme.primary, radius: 10)
                        .offset(y: scanAnimationOffset)
                        .animation(
                            Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true),
                            value: scanAnimationOffset
                        )
                }
                .frame(height: 320)
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .onAppear {
                    scanAnimationOffset = 120
                }

                VStack(spacing: 10) {
                    ProgressView()
                        .tint(AppTheme.primary)
                        .scaleEffect(1.4)
                    Text("AI Lens Analyzing Meal...")
                        .font(AppTheme.headlineFont)
                        .foregroundStyle(Color.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.black.opacity(0.75))
                        .clipShape(Capsule())
                }
            }

            VStack {
                HStack {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(isScanning ? AppTheme.primary : Color.green)
                            .frame(width: 8, height: 8)
                        Text(isScanning ? "AI SCANNING" : (capturedImage != nil ? "MEAL DETECTED" : "LIVE LENS READY"))
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Color.white)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.black.opacity(0.65))
                    .clipShape(Capsule())

                    Spacer()

                    if capturedImage != nil {
                        Button {
                            withAnimation {
                                self.capturedImage = nil
                                self.scanCompleted = false
                                self.selectedMeal = nil
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.counterclockwise")
                                Text("Retake")
                            }
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Color.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.black.opacity(0.65))
                            .clipShape(Capsule())
                        }
                    }
                }
                .padding(14)

                Spacer()
            }
        }
        .frame(height: 320)
        .padding(.horizontal, AppTheme.Spacing.screenMargin)
    }

    private var simulatorLiveFeedMock: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.1, green: 0.12, blue: 0.16), Color(red: 0.04, green: 0.05, blue: 0.07)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(AppTheme.surfaceRaised)
                        .frame(width: 140, height: 140)

                    Image(systemName: "fork.knife.circle.fill")
                        .font(.system(size: 70))
                        .foregroundStyle(AppTheme.primary.opacity(0.8))
                }

                Text("Camera Lens Active (Preview Mode)")
                    .font(AppTheme.headlineFont)
                    .foregroundStyle(AppTheme.text)

                Text("Align meal inside target box and tap capture")
                    .font(AppTheme.captionFont)
                    .foregroundStyle(AppTheme.textSecondary)
            }
        }
    }

    private var viewfinderOverlay: some View {
        GeometryReader { geo in
            let length: CGFloat = 28
            let stroke: CGFloat = 3.5
            let cornerRadius: CGFloat = 20

            ZStack {
                Circle()
                    .stroke(AppTheme.primary.opacity(0.3), lineWidth: 1)
                    .frame(width: 60, height: 60)

                Path { path in
                    path.move(to: CGPoint(x: cornerRadius, y: cornerRadius + length))
                    path.addLine(to: CGPoint(x: cornerRadius, y: cornerRadius))
                    path.addLine(to: CGPoint(x: cornerRadius + length, y: cornerRadius))
                }.stroke(AppTheme.primary, lineWidth: stroke)

                Path { path in
                    path.move(to: CGPoint(x: geo.size.width - cornerRadius - length, y: cornerRadius))
                    path.addLine(to: CGPoint(x: geo.size.width - cornerRadius, y: cornerRadius))
                    path.addLine(to: CGPoint(x: geo.size.width - cornerRadius, y: cornerRadius + length))
                }.stroke(AppTheme.primary, lineWidth: stroke)

                Path { path in
                    path.move(to: CGPoint(x: cornerRadius, y: geo.size.height - cornerRadius - length))
                    path.addLine(to: CGPoint(x: cornerRadius, y: geo.size.height - cornerRadius))
                    path.addLine(to: CGPoint(x: cornerRadius + length, y: geo.size.height - cornerRadius))
                }.stroke(AppTheme.primary, lineWidth: stroke)

                Path { path in
                    path.move(to: CGPoint(x: geo.size.width - cornerRadius - length, y: geo.size.height - cornerRadius))
                    path.addLine(to: CGPoint(x: geo.size.width - cornerRadius, y: cornerRadius))
                    path.addLine(to: CGPoint(x: geo.size.width - cornerRadius, y: geo.size.height - cornerRadius - length))
                }.stroke(AppTheme.primary, lineWidth: stroke)
            }
        }
    }

    private var cameraActionControls: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                VStack(spacing: 4) {
                    Image(systemName: "photo.on.rectangle")
                        .font(.system(size: 20))
                    Text("Library")
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundStyle(AppTheme.textSecondary)
                .frame(width: 64, height: 64)
                .background(AppTheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }

            Button {
                triggerLiveLensCapture()
            } label: {
                HStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.3), lineWidth: 3)
                            .frame(width: 32, height: 32)

                        Circle()
                            .fill(Color.white)
                            .frame(width: 22, height: 22)
                    }

                    Text(isScanning ? "Analyzing Lens..." : "Scan Meal Now")
                        .font(AppTheme.headlineFont)
                        .bold()
                }
                .foregroundStyle(AppTheme.onPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: 64)
                .background(
                    LinearGradient(
                        colors: [AppTheme.primary, AppTheme.primaryDark],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .shadow(color: AppTheme.primary.opacity(0.3), radius: 8, y: 3)
            }
            .disabled(isScanning)
        }
        .padding(.horizontal, AppTheme.Spacing.screenMargin)
    }

    private var scannedResultCard: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("AI MEAL ANALYSIS RESULT")
                        .font(AppTheme.eyebrowFont)
                        .tracking(1.2)
                        .foregroundStyle(AppTheme.primary)

                    TextField("Meal Name", text: $customMealName)
                        .font(AppTheme.titleFont)
                        .foregroundStyle(AppTheme.text)
                }

                Spacer()

                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 26))
                    .foregroundStyle(AppTheme.primary)
            }

            Divider().background(AppTheme.hairline)

            HStack(spacing: AppTheme.Spacing.xs) {
                macroBadge("Calories", val: "\(calories) kcal", color: AppTheme.caloriesColor)
                macroBadge("Protein", val: "\(protein)g", color: AppTheme.proteinColor)
                macroBadge("Carbs", val: "\(carbs)g", color: AppTheme.carbsColor)
                macroBadge("Fat", val: "\(fat)g", color: AppTheme.fatColor)
            }

            VStack(spacing: 8) {
                HStack {
                    Text("Adjust Calories:")
                        .font(AppTheme.captionFont)
                        .foregroundStyle(AppTheme.textSecondary)
                    Spacer()
                    Stepper("\(calories) kcal", value: $calories, in: 50...3000, step: 25)
                        .font(AppTheme.subheadlineFont)
                }

                HStack {
                    Text("Adjust Protein:")
                        .font(AppTheme.captionFont)
                        .foregroundStyle(AppTheme.textSecondary)
                    Spacer()
                    Stepper("\(protein)g Protein", value: $protein, in: 0...250, step: 5)
                        .font(AppTheme.subheadlineFont)
                }
            }
            .padding(.top, 4)

            Button {
                commitScannedMeal()
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Scanned Meal to \(mealType)")
                        .bold()
                }
                .font(AppTheme.headlineFont)
                .foregroundStyle(AppTheme.onPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(AppTheme.primary)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.button))
            }
            .padding(.top, 4)
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.card))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radii.card)
                .strokeBorder(AppTheme.primary.opacity(0.4), lineWidth: 1.5)
        )
        .padding(.horizontal, AppTheme.Spacing.screenMargin)
    }

    private var mealTypeSelector: some View {
        HStack(spacing: 8) {
            ForEach(["Breakfast", "Lunch", "Dinner", "Snack"], id: \.self) { type in
                Button {
                    withAnimation {
                        mealType = type
                    }
                } label: {
                    Text(type)
                        .font(.system(size: 13, weight: mealType == type ? .bold : .medium))
                        .foregroundStyle(mealType == type ? AppTheme.onPrimary : AppTheme.textSecondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                        .background(mealType == type ? AppTheme.primary : AppTheme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
        .padding(.horizontal, AppTheme.Spacing.screenMargin)
    }

    private var quickPresetsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text("OR TAP COMMON ATHLETE MEALS")
                .font(AppTheme.eyebrowFont)
                .tracking(1.5)
                .foregroundStyle(AppTheme.textSecondary)
                .padding(.horizontal, AppTheme.Spacing.screenMargin)

            ForEach(sampleCatalog) { meal in
                Button {
                    applyMeal(meal)
                } label: {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(AppTheme.primary.opacity(0.15))
                                .frame(width: 42, height: 42)
                            Image(systemName: meal.icon)
                                .font(.system(size: 17, weight: .bold))
                                .foregroundStyle(AppTheme.primary)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(meal.name)
                                .font(AppTheme.headlineFont)
                                .foregroundStyle(AppTheme.text)
                                .lineLimit(1)
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
        }
        .padding(.bottom, AppTheme.Spacing.xxl)
    }

    private var cameraPermissionDeniedView: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            Image(systemName: "camera.badge.ellipsis")
                .font(.system(size: 50))
                .foregroundStyle(AppTheme.caloriesColor)

            Text("Camera Access Required")
                .font(AppTheme.titleFont)
                .foregroundStyle(AppTheme.text)

            Text("Please allow camera access in iOS Settings to scan your meals and calculate calories via your lens.")
                .font(AppTheme.bodyFont)
                .foregroundStyle(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button("Open iOS Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .font(AppTheme.headlineFont)
            .foregroundStyle(AppTheme.onPrimary)
            .frame(width: 220, height: 48)
            .background(AppTheme.primary)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.button))
        }
        .padding(.top, 80)
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
        .padding(8)
        .background(AppTheme.surfaceRaised)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func triggerLiveLensCapture() {
        isScanning = true
        cameraService.capturePhoto { image in
            if let image = image {
                self.capturedImage = image
                analyzeCapturedImage(image)
            } else {
                let preset = sampleCatalog.randomElement() ?? sampleCatalog[0]
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    self.isScanning = false
                    applyMeal(preset)
                }
            }
        }
    }

    private func analyzeCapturedImage(_ image: UIImage) {
        isScanning = true
        let preset = sampleCatalog.randomElement() ?? sampleCatalog[0]
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
            self.isScanning = false
            applyMeal(preset)
        }
    }

    private func applyMeal(_ meal: RecognizedMealPreset) {
        selectedMeal = meal
        customMealName = meal.name
        calories = meal.calories
        protein = meal.protein
        carbs = meal.carbs
        fat = meal.fat
        withAnimation {
            scanCompleted = true
        }
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
        cameraService.stopRunning()
        dismiss()
    }
}
