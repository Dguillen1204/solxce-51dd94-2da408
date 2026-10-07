// Models/SplitPresetModels.swift
import Foundation
import SwiftUI

/// Preset workout splits that users can instantly apply to their 7-day schedule
public struct WorkoutSplitPreset: Identifiable, Hashable {
    public let id: String
    public let name: String
    public let subtitle: String
    public let category: String
    public let frequencyDays: Int
    public let iconName: String
    public let accentColor: Color
    public let schedule: [DaySplitTemplate]

    public struct DaySplitTemplate: Hashable {
        public let dayOfWeek: Int // 1 = Sunday, 2 = Monday, ... 7 = Saturday
        public let focusBodyPart: String
        public let isRestDay: Bool
        public let targetExercises: String
    }
}

public enum SplitPresetCatalog {
    public static let allPresets: [WorkoutSplitPreset] = [
        // 1. Push / Pull / Legs (PPL) - 6 Day
        WorkoutSplitPreset(
            id: "ppl_6day",
            name: "Push Pull Legs (6-Day)",
            subtitle: "High frequency hypertrophy split for max muscle volume",
            category: "Hypertrophy",
            frequencyDays: 6,
            iconName: "flame.fill",
            accentColor: Color(red: 0.83, green: 1.0, blue: 0.25), // Volt
            schedule: [
                .init(dayOfWeek: 2, focusBodyPart: "Push (Chest & Tris)", isRestDay: false, targetExercises: "Incline Barbell Bench, Overhead Dumbbell Press, Cable Flyes, Triceps Pushdown"),
                .init(dayOfWeek: 3, focusBodyPart: "Pull (Back & Bis)", isRestDay: false, targetExercises: "Barbell Rows, Weighted Pull-Ups, Lat Pulldowns, Incline Dumbbell Curls"),
                .init(dayOfWeek: 4, focusBodyPart: "Legs & Core", isRestDay: false, targetExercises: "Back Squats, Romanian Deadlifts, Leg Press, Hanging Leg Raises"),
                .init(dayOfWeek: 5, focusBodyPart: "Push Hypertrophy", isRestDay: false, targetExercises: "Flat Dumbbell Press, Lateral Raises, Pec Deck, Skullcrushers"),
                .init(dayOfWeek: 6, focusBodyPart: "Pull Hypertrophy", isRestDay: false, targetExercises: "Chest Supported T-Bar Row, Seated Cable Rows, Hammer Curls, Facepulls"),
                .init(dayOfWeek: 7, focusBodyPart: "Legs (Hamstring Focus)", isRestDay: false, targetExercises: "Front Squats, Lying Leg Curls, Bulgarian Split Squats, Standing Calf Raises"),
                .init(dayOfWeek: 1, focusBodyPart: "Rest & Recovery", isRestDay: true, targetExercises: "Full systemic recovery, hydration & macro replenishment")
            ]
        ),

        // 2. Hybrid Athlete (Lift + Endurance Run)
        WorkoutSplitPreset(
            id: "hybrid_lift_run",
            name: "Hybrid Engine (Lift + Run)",
            subtitle: "Strength compound lifts combined with Zone-2 & tempo running",
            category: "Hybrid",
            frequencyDays: 5,
            iconName: "bolt.shield.fill",
            accentColor: Color(red: 0.22, green: 0.74, blue: 0.97), // Sky Blue
            schedule: [
                .init(dayOfWeek: 2, focusBodyPart: "Heavy Upper + Tempo Run", isRestDay: false, targetExercises: "Bench Press, Barbell Rows, Overhead Press + 3 Mile Tempo Run"),
                .init(dayOfWeek: 3, focusBodyPart: "Heavy Lower (Squats & Deadlifts)", isRestDay: false, targetExercises: "Barbell Squats, Romanian Deadlifts, Walking Lunges, Core Holds"),
                .init(dayOfWeek: 4, focusBodyPart: "Zone 2 Long Aerobic Run", isRestDay: false, targetExercises: "5–8 Mile Conversational Pace Run, Mobility Stretches"),
                .init(dayOfWeek: 5, focusBodyPart: "Upper Hypertrophy & Arms", isRestDay: false, targetExercises: "Incline DB Press, Pull-Ups, Lateral Raises, Bicep Curls, Dips"),
                .init(dayOfWeek: 6, focusBodyPart: "Speed Intervals & Power Legs", isRestDay: false, targetExercises: "Front Squats, Trap Bar Jumps + 6x400m Track Repeats"),
                .init(dayOfWeek: 7, focusBodyPart: "Active Recovery & Mobility", isRestDay: true, targetExercises: "Light 20 min recovery jog / walk, foam rolling, yoga"),
                .init(dayOfWeek: 1, focusBodyPart: "Full Rest Day", isRestDay: true, targetExercises: "Rest day: meal prep and nervous system reset")
            ]
        ),

        // 3. Upper / Lower 4-Day Split
        WorkoutSplitPreset(
            id: "upper_lower_4day",
            name: "Upper / Lower (4-Day)",
            subtitle: "Optimal balance of recovery, strength, and work-life flexibility",
            category: "Strength",
            frequencyDays: 4,
            iconName: "scalemass.fill",
            accentColor: Color(red: 0.66, green: 0.33, blue: 0.97), // Purple
            schedule: [
                .init(dayOfWeek: 2, focusBodyPart: "Upper Body Strength", isRestDay: false, targetExercises: "Barbell Bench Press, Barbell Row, Overhead Press, Pull-Ups"),
                .init(dayOfWeek: 3, focusBodyPart: "Lower Body Strength", isRestDay: false, targetExercises: "Barbell Back Squat, Romanian Deadlift, Leg Press, Standing Calf Raise"),
                .init(dayOfWeek: 4, focusBodyPart: "Rest Day", isRestDay: true, targetExercises: "Rest & recovery or light mobility"),
                .init(dayOfWeek: 5, focusBodyPart: "Upper Body Hypertrophy", isRestDay: false, targetExercises: "Incline DB Press, Cable Lat Pulldown, Lateral Raise, Tricep Pushdown, EZ Bar Curl"),
                .init(dayOfWeek: 6, focusBodyPart: "Lower Body Hypertrophy", isRestDay: false, targetExercises: "Front Squat, Bulgarian Split Squat, Leg Extension, Seated Leg Curl, Core"),
                .init(dayOfWeek: 7, focusBodyPart: "Active Cardio & Core", isRestDay: true, targetExercises: "Optional 3-mile recovery jog or outdoor walk"),
                .init(dayOfWeek: 1, focusBodyPart: "Rest Day", isRestDay: true, targetExercises: "Rest & meal preparation")
            ]
        ),

        // 4. Classic 5-Day Bodybuilding / Bro Split
        WorkoutSplitPreset(
            id: "classic_bro_5day",
            name: "Classic Bodybuilding (5-Day)",
            subtitle: "Dedicated single muscle group isolation for pure aesthetics",
            category: "Bodybuilding",
            frequencyDays: 5,
            iconName: "figure.arms.open",
            accentColor: Color(red: 1.0, green: 0.23, blue: 0.36), // Crimson
            schedule: [
                .init(dayOfWeek: 2, focusBodyPart: "Chest Annihilation", isRestDay: false, targetExercises: "Barbell Bench Press, Incline DB Press, Cable Crossover, Dips, Push-ups"),
                .init(dayOfWeek: 3, focusBodyPart: "Back & Lats", isRestDay: false, targetExercises: "Deadlifts, Barbell Rows, Neutral Grip Pull-Downs, DB Shrugs"),
                .init(dayOfWeek: 4, focusBodyPart: "Shoulders & Traps", isRestDay: false, targetExercises: "Military Press, DB Lateral Raises, Rear Delt Flyes, Upright Rows"),
                .init(dayOfWeek: 5, focusBodyPart: "Legs & Calves", isRestDay: false, targetExercises: "Back Squats, Hack Squats, Lying Hamstring Curls, Walking Lunges"),
                .init(dayOfWeek: 6, focusBodyPart: "Arms & Abs", isRestDay: false, targetExercises: "Barbell Bicep Curls, Skullcrushers, Hammer Curls, Rope Pushdowns, Ab Wheel"),
                .init(dayOfWeek: 7, focusBodyPart: "Active Recovery", isRestDay: true, targetExercises: "Light walking, sauna, stretching"),
                .init(dayOfWeek: 1, focusBodyPart: "Rest Day", isRestDay: true, targetExercises: "Complete rest, nutrition reload")
            ]
        ),

        // 5. Full Body (3-Day) Power & Conditioning
        WorkoutSplitPreset(
            id: "full_body_3day",
            name: "Full Body Foundation (3-Day)",
            subtitle: "High efficiency full body workouts with maximal recovery between days",
            category: "Efficiency",
            frequencyDays: 3,
            iconName: "figure.cross-training",
            accentColor: Color(red: 0.98, green: 0.75, blue: 0.14), // Amber
            schedule: [
                .init(dayOfWeek: 2, focusBodyPart: "Full Body A (Squat & Press)", isRestDay: false, targetExercises: "Barbell Squats, Flat Bench Press, Barbell Rows, Overhead Press, Bicep Curls"),
                .init(dayOfWeek: 3, focusBodyPart: "Rest & Cardio", isRestDay: true, targetExercises: "Zone-2 walk or light recovery bike"),
                .init(dayOfWeek: 4, focusBodyPart: "Full Body B (Deadlift & Pull)", isRestDay: false, targetExercises: "Conventional Deadlifts, Incline DB Press, Pull-Ups, Lateral Raises, Tricep Dips"),
                .init(dayOfWeek: 5, focusBodyPart: "Rest & Recovery", isRestDay: true, targetExercises: "Mobility flow and stretching"),
                .init(dayOfWeek: 6, focusBodyPart: "Full Body C (Power & Hypertrophy)", isRestDay: false, targetExercises: "Front Squats, DB Shoulder Press, Cable Rows, Hamstring Curls, Hanging Knee Raises"),
                .init(dayOfWeek: 7, focusBodyPart: "Weekend Active Cardio", isRestDay: true, targetExercises: "Outdoor run, hiking, or sports"),
                .init(dayOfWeek: 1, focusBodyPart: "Rest Day", isRestDay: true, targetExercises: "Full rest and nutrition planning")
            ]
        )
    ]
}
