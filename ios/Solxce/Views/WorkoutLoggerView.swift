// Views/WorkoutLoggerView.swift
import SwiftUI
import SwiftData

struct WorkoutLoggerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @ObservedObject private var healthKit = HealthKitService.shared

    @State private var sessionTitle: String = "Chest & Back Power"
    @State private var selectedBodyPart: String = "Chest & Back"
    @State private var durationMinutes: Int = 45
    @State private var exercises: [DraftExercise] = []
    @State private var showingAddExerciseSheet = false

    let bodyPartOptions = ["Chest & Triceps", "Back & Biceps", "Legs & Core", "Shoulders & Arms", "Full Body Power", "Chest & Back", "Cardio & Core"]

    var totalSets: Int {
        exercises.reduce(0) { $0 + $1.sets.count }
    }

    var totalVolume: Double {
        exercises.reduce(0) { sum, ex in
            sum + ex.sets.reduce(0) { setSum, s in
                setSum + (Double(s.reps) * s.weightLbs)
            }
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.lg) {
                    // Title and metadata header
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                        TextField("Session Title", text: $sessionTitle)
                            .font(AppTheme.titleFont)
                            .foregroundStyle(AppTheme.text)
                            .padding(AppTheme.Spacing.sm)
                            .background(AppTheme.field)
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.tag))

                        HStack(spacing: AppTheme.Spacing.sm) {
                            Menu {
                                ForEach(bodyPartOptions, id: \.self) { part in
                                    Button(part) { selectedBodyPart = part }
                                }
                            } label: {
                                HStack {
                                    Image(systemName: "figure.strengthtraining.traditional")
                                    Text(selectedBodyPart)
                                    Image(systemName: "chevron.down")
                                }
                                .font(AppTheme.subheadlineFont)
                                .foregroundStyle(AppTheme.primary)
                                .padding(.horizontal, AppTheme.Spacing.sm)
                                .padding(.vertical, 8)
                                .background(AppTheme.surfaceRaised)
                                .clipShape(Capsule())
                            }

                            Spacer()

                            HStack(spacing: 4) {
                                Image(systemName: "clock")
                                    .font(.system(size: 13))
                                Picker("Duration", selection: $durationMinutes) {
                                    ForEach([30, 45, 60, 75, 90, 120], id: \.self) { mins in
                                        Text("\(mins)m").tag(mins)
                                    }
                                }
                                .pickerStyle(.menu)
                                .tint(AppTheme.text)
                            }
                            .font(AppTheme.captionFont)
                            .foregroundStyle(AppTheme.textSecondary)
                        }

                        // Summary chips
                        HStack(spacing: AppTheme.Spacing.md) {
                            summaryChip(label: "TOTAL VOLUME", value: "\(Int(totalVolume)) lbs")
                            summaryChip(label: "TOTAL SETS", value: "\(totalSets)")
                            summaryChip(label: "EXERCISES", value: "\(exercises.count)")
                        }
                        
                        // Apple Watch Live Companion Status Bar
                        Button {
                            showingWatchHub = true
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: watchManager.pairingStatus.iconName)
                                    .foregroundStyle(watchManager.pairingStatus.tintColor)
                                    .font(.system(size: 13, weight: .bold))
                                
                                Text(watchManager.pairingStatus == .pairedAndReachable ? "Apple Watch Connected" : "Apple Watch: \(watchManager.pairingStatus.rawValue)")
                                    .font(AppTheme.captionFont.weight(.semibold))
                                    .foregroundStyle(AppTheme.text)
                                
                                Spacer()
                                
                                let hr = watchManager.liveTelemetry.heartRateBpm > 0 ? Int(watchManager.liveTelemetry.heartRateBpm) : (healthKit.currentHeartRateBpm > 0 ? Int(healthKit.currentHeartRateBpm) : 138)
                                HStack(spacing: 3) {
                                    Image(systemName: "heart.fill")
                                        .font(.system(size: 10))
                                        .foregroundStyle(Color(red: 1.0, green: 0.231, blue: 0.361))
                                    Text("\(hr) BPM")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundStyle(AppTheme.text)
                                }
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(AppTheme.surfaceRaised)
                                .clipShape(Capsule())
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 10))
                                    .foregroundStyle(AppTheme.textSecondary)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .background(AppTheme.field)
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.tag))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(AppTheme.Spacing.md)
                    .background(AppTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.card))

                    // Exercise List
                    if exercises.isEmpty {
                        VStack(spacing: AppTheme.Spacing.sm) {
                            Image(systemName: "dumbbell")
                                .font(.system(size: 36))
                                .foregroundStyle(AppTheme.primary)
                            Text("No exercises added yet")
                                .font(AppTheme.headlineFont)
                                .foregroundStyle(AppTheme.text)
                            Text("Add your first exercise to start recording sets, weight, and reps.")
                                .font(AppTheme.captionFont)
                                .foregroundStyle(AppTheme.textSecondary)
                                .multilineTextAlignment(.center)

                            Button(action: { showingAddExerciseSheet = true }) {
                                HStack {
                                    Image(systemName: "plus")
                                    Text("Add Exercise")
                                }
                                .font(AppTheme.headlineFont)
                                .foregroundStyle(AppTheme.onPrimary)
                                .padding(.horizontal, AppTheme.Spacing.lg)
                                .padding(.vertical, AppTheme.Spacing.sm)
                                .background(AppTheme.primary)
                                .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.button))
                            }
                            .padding(.top, AppTheme.Spacing.xs)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(AppTheme.Spacing.xl)
                        .background(AppTheme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.card))
                    } else {
                        ForEach(Array(exercises.enumerated()), id: \.element.id) { index, exercise in
                            exerciseCard(index: index, exercise: exercise)
                        }

                        Button(action: { showingAddExerciseSheet = true }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Add Next Exercise")
                            }
                            .font(AppTheme.headlineFont)
                            .foregroundStyle(AppTheme.primary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, AppTheme.Spacing.md)
                            .background(AppTheme.surface)
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.card))
                            .overlay(
                                RoundedRectangle(cornerRadius: AppTheme.Radii.card)
                                    .strokeBorder(AppTheme.primary.opacity(0.4), style: StrokeStyle(lineWidth: 1, dash: [6]))
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, AppTheme.Spacing.screenMargin)
                .padding(.top, AppTheme.Spacing.sm)
                .padding(.bottom, AppTheme.Spacing.xxl)
            }
            .background(AppTheme.ground.ignoresSafeArea())
            .navigationTitle("Log Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(AppTheme.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveWorkout()
                        dismiss()
                    }
                    .font(AppTheme.headlineFont)
                    .foregroundStyle(AppTheme.primary)
                    .disabled(exercises.isEmpty)
                }
            }
            .sheet(isPresented: $showingAddExerciseSheet) {
                AddExerciseSheet { newName, muscle in
                    let draft = DraftExercise(
                        name: newName,
                        targetMuscle: muscle,
                        sets: [
                            DraftSet(setNumber: 1, reps: 10, weightLbs: 135),
                            DraftSet(setNumber: 2, reps: 10, weightLbs: 135),
                            DraftSet(setNumber: 3, reps: 8, weightLbs: 145)
                        ]
                    )
                    exercises.append(draft)
                }
            }
            .onAppear {
                if exercises.isEmpty {
                    // Seed initial draft exercise
                    exercises = [
                        DraftExercise(
                            name: "Barbell Bench Press",
                            targetMuscle: "Chest",
                            sets: [
                                DraftSet(setNumber: 1, reps: 10, weightLbs: 185),
                                DraftSet(setNumber: 2, reps: 8, weightLbs: 205),
                                DraftSet(setNumber: 3, reps: 6, weightLbs: 225)
                            ]
                        )
                    ]
                }
            }
        }
    }

    private func summaryChip(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(AppTheme.eyebrowFont)
                .foregroundStyle(AppTheme.textMuted)
            Text(value)
                .font(AppTheme.headlineFont)
                .bold()
                .foregroundStyle(AppTheme.primary)
        }
    }

    private func exerciseCard(index: Int, exercise: DraftExercise) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(exercise.name)
                        .font(AppTheme.headlineFont)
                        .foregroundStyle(AppTheme.text)
                    Text(exercise.targetMuscle.uppercased())
                        .font(AppTheme.eyebrowFont)
                        .foregroundStyle(AppTheme.primary)
                }

                Spacer()

                Button(action: {
                    exercises.remove(at: index)
                }) {
                    Image(systemName: "trash")
                        .font(.system(size: 14))
                        .foregroundStyle(AppTheme.accent)
                }
            }

            Divider().background(AppTheme.hairline)

            // Header for sets
            HStack {
                Text("SET").frame(width: 36, alignment: .leading)
                Text("WEIGHT (LBS)").frame(maxWidth: .infinity, alignment: .leading)
                Text("REPS").frame(width: 60, alignment: .leading)
                Text("").frame(width: 30)
            }
            .font(AppTheme.eyebrowFont)
            .foregroundStyle(AppTheme.textSecondary)

            // Sets rows
            ForEach(Array(exercise.sets.enumerated()), id: \.element.id) { setIdx, setItem in
                HStack(spacing: AppTheme.Spacing.xs) {
                    Text("\(setIdx + 1)")
                        .font(AppTheme.subheadlineFont)
                        .bold()
                        .foregroundStyle(AppTheme.textSecondary)
                        .frame(width: 36, alignment: .leading)

                    TextField("Weight", value: Binding(
                        get: { exercises[index].sets[setIdx].weightLbs },
                        set: { exercises[index].sets[setIdx].weightLbs = $0 }
                    ), format: .number)
                    .keyboardType(.decimalPad)
                    .padding(6)
                    .background(AppTheme.field)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .foregroundStyle(AppTheme.text)

                    TextField("Reps", value: Binding(
                        get: { exercises[index].sets[setIdx].reps },
                        set: { exercises[index].sets[setIdx].reps = $0 }
                    ), format: .number)
                    .keyboardType(.numberPad)
                    .padding(6)
                    .frame(width: 60)
                    .background(AppTheme.field)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .foregroundStyle(AppTheme.text)

                    Button(action: {
                        if exercises[index].sets.count > 1 {
                            exercises[index].sets.remove(at: setIdx)
                        }
                    }) {
                        Image(systemName: "minus.circle")
                            .foregroundStyle(AppTheme.textMuted)
                    }
                    .frame(width: 30)
                }
            }

            // Add set button
            Button(action: {
                let lastWeight = exercise.sets.last?.weightLbs ?? 135
                let lastReps = exercise.sets.last?.reps ?? 10
                let newSet = DraftSet(setNumber: exercise.sets.count + 1, reps: lastReps, weightLbs: lastWeight)
                exercises[index].sets.append(newSet)
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "plus")
                    Text("Add Set")
                }
                .font(AppTheme.captionFont)
                .bold()
                .foregroundStyle(AppTheme.primary)
                .padding(.vertical, 6)
            }
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.card))
    }

    private func saveWorkout() {
        let savedExercises = exercises.map { ex in
            let savedSets = ex.sets.map { s in
                ExerciseSet(setNumber: s.setNumber, reps: s.reps, weightLbs: s.weightLbs)
            }
            return WorkoutExercise(name: ex.name, targetMuscle: ex.targetMuscle, sets: savedSets)
        }

        let session = WorkoutSession(
            title: sessionTitle.isEmpty ? "Workout Session" : sessionTitle,
            bodyPartFocus: selectedBodyPart,
            date: Date(),
            durationMinutes: durationMinutes,
            exercises: savedExercises
        )
        modelContext.insert(session)
        try? modelContext.save()

        // Sync workout event to backend API
        Task {
            _ = try? await BackendSyncService.shared.recordWorkoutEvent(
                title: session.title,
                durationMinutes: session.durationMinutes,
                calories: Int(Double(session.durationMinutes) * 7.5)
            )
            _ = await healthKit.saveCompletedWorkout(
                title: session.title,
                durationSeconds: session.durationMinutes * 60,
                caloriesBurned: Double(session.durationMinutes) * 7.5
            )
        }
    }
}

// MARK: - Draft Helper Types
struct DraftExercise: Identifiable {
    let id = UUID()
    var name: String
    var targetMuscle: String
    var sets: [DraftSet]
}

struct DraftSet: Identifiable {
    let id = UUID()
    var setNumber: Int
    var reps: Int
    var weightLbs: Double
}

// MARK: - Add Exercise Sheet
struct AddExerciseSheet: View {
    @Environment(\.dismiss) private var dismiss
    var onAdd: (String, String) -> Void

    @State private var exerciseName: String = ""
    @State private var targetMuscle: String = "Chest"

    let standardCatalog: [(String, String)] = [
        ("Barbell Bench Press", "Chest"),
        ("Incline Dumbbell Press", "Chest"),
        ("Dumbbell Flyes", "Chest"),
        ("Pull-Ups", "Back"),
        ("Barbell Deadlift", "Back"),
        ("Lat Pulldown", "Back"),
        ("Barbell Squat", "Legs"),
        ("Romanian Deadlift", "Legs"),
        ("Leg Press", "Legs"),
        ("Overhead Shoulder Press", "Shoulders"),
        ("Lateral Raises", "Shoulders"),
        ("Barbell Bicep Curl", "Biceps"),
        ("Tricep Rope Pushdown", "Triceps"),
        ("Hanging Leg Raise", "Core")
    ]

    var body: some View {
        NavigationStack {
            List {
                Section("Custom Exercise") {
                    TextField("Exercise Name", text: $exerciseName)
                        .foregroundStyle(AppTheme.text)
                    Picker("Muscle Group", selection: $targetMuscle) {
                        ForEach(["Chest", "Back", "Legs", "Shoulders", "Biceps", "Triceps", "Core"], id: \.self) {
                            Text($0).tag($0)
                        }
                    }
                    Button("Add Custom") {
                        if !exerciseName.isEmpty {
                            onAdd(exerciseName, targetMuscle)
                            dismiss()
                        }
                    }
                    .disabled(exerciseName.isEmpty)
                    .foregroundStyle(AppTheme.primary)
                }

                Section("Standard Catalog") {
                    ForEach(standardCatalog, id: \.0) { item in
                        Button(action: {
                            onAdd(item.0, item.1)
                            dismiss()
                        }) {
                            HStack {
                                Text(item.0)
                                    .foregroundStyle(AppTheme.text)
                                Spacer()
                                Text(item.1)
                                    .font(AppTheme.captionFont)
                                    .foregroundStyle(AppTheme.primary)
                            }
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppTheme.ground.ignoresSafeArea())
            .navigationTitle("Select Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }
        }
    }
}
