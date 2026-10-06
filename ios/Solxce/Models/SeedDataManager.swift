// Models/SeedDataManager.swift
import Foundation
import SwiftData

@MainActor
enum SeedDataManager {
    static func seedIfNeeded(context: ModelContext) {
        let descriptor = FetchDescriptor<MacroTarget>()
        let count = (try? context.fetchCount(descriptor)) ?? 0
        guard count == 0 else { return }

        // 0. Seed User Profile if absent
        let profileDescriptor = FetchDescriptor<UserProfile>()
        let profileCount = (try? context.fetchCount(profileDescriptor)) ?? 0
        if profileCount == 0 {
            let profile = UserProfile(
                fullName: "Alex Rivera",
                handle: "alex_solxce",
                athleteType: .hybrid,
                bio: "Hybrid athlete chasing 500lb deadlifts and sub-20min 5Ks.",
                avatarSymbol: "bolt.shield.fill"
            )
            context.insert(profile)
        }

        // 1. Seed Macro Target
        let target = MacroTarget(
            dailyCalories: 2450,
            dailyProteinGrams: 185,
            dailyCarbsGrams: 230,
            dailyFatGrams: 65
        )
        context.insert(target)

        // 2. Seed Weekly Planner Split
        let splitSchedule: [(Int, String, String, Bool, String)] = [
            (2, "Monday", "Chest & Triceps", false, "Bench Press, Incline Dumbbell, Dips, Cable Pushdowns"),
            (3, "Tuesday", "Back & Biceps", false, "Barbell Deadlift, Pull-Ups, Lat Pulldown, Barbell Curls"),
            (4, "Wednesday", "Legs & Core", false, "Barbell Squats, Romanian Deadlifts, Leg Press, Hanging Knee Raises"),
            (5, "Thursday", "Shoulders & Arms", false, "Overhead Press, Lateral Raises, Skullcrushers, Hammer Curls"),
            (6, "Friday", "Full Body Power & Run", false, "Power Cleans, Front Squats, Incline Press + 3 Mile Tempo Run"),
            (7, "Saturday", "Active Recovery & Mobility", false, "Light 2 Mile Jog, Foam Rolling, Mobility Flow"),
            (1, "Sunday", "Rest Day", true, "Full muscle recovery, meal prep, and nutrition replenishment")
        ]

        for item in splitSchedule {
            let day = PlannerDay(
                dayOfWeek: item.0,
                dayName: item.1,
                focusBodyPart: item.2,
                isRestDay: item.3,
                targetExercisesDescription: item.4
            )
            context.insert(day)
        }

        // 3. Seed Sample Food Entries for Today
        let calendar = Calendar.current
        let today = Date()

        let sampleFoods = [
            FoodEntry(name: "Eggs & Avocado Toast", mealType: "Breakfast", calories: 520, proteinGrams: 32, carbsGrams: 42, fatGrams: 22, date: today),
            FoodEntry(name: "Whey Protein Shake & Banana", mealType: "Snack", calories: 280, proteinGrams: 30, carbsGrams: 35, fatGrams: 3, date: today),
            FoodEntry(name: "Grilled Chicken & Jasmine Rice", mealType: "Lunch", calories: 680, proteinGrams: 58, carbsGrams: 75, fatGrams: 12, date: today)
        ]

        for food in sampleFoods {
            context.insert(food)
        }

        // 4. Seed Workout Session (Recent history)
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today) ?? today
        let benchSets = [
            ExerciseSet(setNumber: 1, reps: 10, weightLbs: 185),
            ExerciseSet(setNumber: 2, reps: 8, weightLbs: 205),
            ExerciseSet(setNumber: 3, reps: 6, weightLbs: 225)
        ]
        let inclineSets = [
            ExerciseSet(setNumber: 1, reps: 10, weightLbs: 70),
            ExerciseSet(setNumber: 2, reps: 10, weightLbs: 75),
            ExerciseSet(setNumber: 3, reps: 8, weightLbs: 80)
        ]
        let cableSets = [
            ExerciseSet(setNumber: 1, reps: 12, weightLbs: 65),
            ExerciseSet(setNumber: 2, reps: 12, weightLbs: 70),
            ExerciseSet(setNumber: 3, reps: 10, weightLbs: 75)
        ]

        let benchExercise = WorkoutExercise(name: "Barbell Bench Press", targetMuscle: "Chest", sets: benchSets)
        let inclineExercise = WorkoutExercise(name: "Incline DB Press", targetMuscle: "Chest", sets: inclineSets)
        let cableExercise = WorkoutExercise(name: "Tricep Rope Pushdown", targetMuscle: "Triceps", sets: cableSets)

        let session = WorkoutSession(
            title: "Chest & Tricep Hypertrophy",
            bodyPartFocus: "Chest & Triceps",
            date: yesterday,
            durationMinutes: 52,
            exercises: [benchExercise, inclineExercise, cableExercise]
        )
        context.insert(session)

        // 5. Seed Run Entry
        let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: today) ?? today
        let sampleRun = RunEntry(
            title: "Morning Interval Run",
            distanceMiles: 3.5,
            durationSeconds: 1540, // ~25m40s (7'20" pace)
            date: twoDaysAgo,
            caloriesBurned: 385,
            notes: "Felt strong during the 3rd mile. Weather 58°F."
        )
        context.insert(sampleRun)

        try? context.save()
    }
}
