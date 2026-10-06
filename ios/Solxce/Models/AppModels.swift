// Models/AppModels.swift
import Foundation
import SwiftData
import CoreLocation
import SwiftUI

// MARK: - Athlete Archetype
public enum AthleteType: String, CaseIterable, Codable, Identifiable {
    case hybrid = "Hybrid Athlete"
    case runner = "Endurance Runner"
    case powerlifter = "Powerlifter"
    case bodybuilder = "Bodybuilder"
    case functional = "CrossFit & Functional"
    case calisthenics = "Calisthenics Athlete"
    case allAround = "All-Around Fitness"

    public var id: String { rawValue }

    public var iconName: String {
        switch self {
        case .hybrid: return "bolt.shield.fill"
        case .runner: return "figure.run"
        case .powerlifter: return "figure.strengthtraining.traditional"
        case .bodybuilder: return "figure.arms.open"
        case .functional: return "flame.fill"
        case .calisthenics: return "figure.gymnastics"
        case .allAround: return "figure.cross-training"
        }
    }

    public var shortTag: String {
        switch self {
        case .hybrid: return "HYBRID"
        case .runner: return "RUNNER"
        case .powerlifter: return "POWERLIFTER"
        case .bodybuilder: return "BODYBUILDER"
        case .functional: return "FUNCTIONAL"
        case .calisthenics: return "CALISTHENICS"
        case .allAround: return "ALL-AROUND"
        }
    }

    public var description: String {
        switch self {
        case .hybrid:
            return "Lifts heavy iron & logs long miles. Unmatched dual-threat engine."
        case .runner:
            return "Chasing pace PRs, marathon splits, and aerobic endurance."
        case .powerlifter:
            return "Pure raw strength: SBD (Squat, Bench, Deadlift) and heavy singles."
        case .bodybuilder:
            return "Muscle hypertrophy, progressive overload, and macro precision."
        case .functional:
            return "High-intensity metabolic conditioning, WODs, and explosive output."
        case .calisthenics:
            return "Bodyweight mastery, lever holds, muscle-ups, and relative strength."
        case .allAround:
            return "Balanced training for general health, energy, and overall longevity."
        }
    }

    public var badgeColorHex: String {
        switch self {
        case .hybrid: return "#D4FF3F"       // Athletic Volt
        case .runner: return "#38BDF8"       // Sky Blue
        case .powerlifter: return "#FF3B5C"   // Crimson
        case .bodybuilder: return "#A855F7"   // Purple
        case .functional: return "#F97316"    // Orange
        case .calisthenics: return "#10B981"  // Emerald
        case .allAround: return "#FBBF24"     // Amber
        }
    }

    public var badgeColor: Color {
        switch self {
        case .hybrid: return Color(red: 0.831, green: 1.0, blue: 0.247)       // #D4FF3F
        case .runner: return Color(red: 0.22, green: 0.74, blue: 0.97)        // #38BDF8
        case .powerlifter: return Color(red: 1.0, green: 0.231, blue: 0.361)  // #FF3B5C
        case .bodybuilder: return Color(red: 0.66, green: 0.33, blue: 0.97)   // #A855F7
        case .functional: return Color(red: 0.98, green: 0.45, blue: 0.09)    // #F97316
        case .calisthenics: return Color(red: 0.06, green: 0.73, blue: 0.51)  // #10B981
        case .allAround: return Color(red: 0.98, green: 0.75, blue: 0.14)     // #FBBF24
        }
    }
}

// MARK: - User Profile Model
@Model
final class UserProfile {
    var id: UUID
    var fullName: String
    var handle: String
    var rawAthleteType: String
    var bio: String
    var avatarSymbol: String
    var joinedDate: Date
    @Attribute(.externalStorage) var profileImageData: Data?
    var isPublicProfile: Bool

    init(
        id: UUID = UUID(),
        fullName: String = "Athlete",
        handle: String = "solxce_athlete",
        athleteType: AthleteType = .hybrid,
        bio: String = "Dedicated to the daily standard. Heavy lifting & fast miles.",
        avatarSymbol: String = "figure.cross-training",
        joinedDate: Date = Date(),
        profileImageData: Data? = nil,
        isPublicProfile: Bool = true
    ) {
        self.id = id
        self.fullName = fullName
        self.handle = handle
        self.rawAthleteType = athleteType.rawValue
        self.bio = bio
        self.avatarSymbol = avatarSymbol
        self.joinedDate = joinedDate
        self.profileImageData = profileImageData
        self.isPublicProfile = isPublicProfile
    }

    var athleteType: AthleteType {
        get {
            AthleteType(rawValue: rawAthleteType) ?? .hybrid
        }
        set {
            rawAthleteType = newValue.rawValue
        }
    }
}

// MARK: - Exercise Set
@Model
final class ExerciseSet {
    var id: UUID
    var setNumber: Int
    var reps: Int
    var weightLbs: Double
    var isCompleted: Bool

    init(id: UUID = UUID(), setNumber: Int, reps: Int, weightLbs: Double, isCompleted: Bool = true) {
        self.id = id
        self.setNumber = setNumber
        self.reps = reps
        self.weightLbs = weightLbs
        self.isCompleted = isCompleted
    }
}

// MARK: - Workout Exercise
@Model
final class WorkoutExercise {
    var id: UUID
    var name: String
    var targetMuscle: String
    @Relationship(deleteRule: .cascade) var sets: [ExerciseSet]

    init(id: UUID = UUID(), name: String, targetMuscle: String, sets: [ExerciseSet] = []) {
        self.id = id
        self.name = name
        self.targetMuscle = targetMuscle
        self.sets = sets
    }
}

// MARK: - Workout Session
@Model
final class WorkoutSession {
    var id: UUID
    var title: String
    var bodyPartFocus: String
    var date: Date
    var durationMinutes: Int
    @Relationship(deleteRule: .cascade) var exercises: [WorkoutExercise]

    init(
        id: UUID = UUID(),
        title: String,
        bodyPartFocus: String,
        date: Date = Date(),
        durationMinutes: Int = 45,
        exercises: [WorkoutExercise] = []
    ) {
        self.id = id
        self.title = title
        self.bodyPartFocus = bodyPartFocus
        self.date = date
        self.durationMinutes = durationMinutes
        self.exercises = exercises
    }

    var totalVolumeLbs: Double {
        exercises.reduce(0) { sum, exercise in
            sum + exercise.sets.reduce(0) { setSum, set in
                setSum + (Double(set.reps) * set.weightLbs)
            }
        }
    }

    var totalSets: Int {
        exercises.reduce(0) { $0 + $1.sets.count }
    }
}

// MARK: - Run Entry
@Model
final class RunEntry {
    var id: UUID
    var title: String
    var distanceMiles: Double
    var durationSeconds: Int
    var date: Date
    var caloriesBurned: Int
    var notes: String
    var routeDataJson: String // Serialized array of [[Double]] (lat, lon) for GPS route map replay

    init(
        id: UUID = UUID(),
        title: String = "Outdoor Run",
        distanceMiles: Double,
        durationSeconds: Int,
        date: Date = Date(),
        caloriesBurned: Int = 0,
        notes: String = "",
        routeCoordinates: [CLLocationCoordinate2D] = []
    ) {
        self.id = id
        self.title = title
        self.distanceMiles = distanceMiles
        self.durationSeconds = durationSeconds
        self.date = date
        self.caloriesBurned = caloriesBurned > 0 ? caloriesBurned : Int(distanceMiles * 110)
        self.notes = notes
        
        let pairs = routeCoordinates.map { [$0.latitude, $0.longitude] }
        if let data = try? JSONEncoder().encode(pairs), let json = String(data: data, encoding: .utf8) {
            self.routeDataJson = json
        } else {
            self.routeDataJson = "[]"
        }
    }

    var paceMinutesPerMile: Double {
        guard distanceMiles > 0 else { return 0 }
        return (Double(durationSeconds) / 60.0) / distanceMiles
    }

    var formattedPace: String {
        let pace = paceMinutesPerMile
        let mins = Int(pace)
        let secs = Int((pace - Double(mins)) * 60)
        return String(format: "%d'%02d\" /mi", mins, max(0, min(59, secs)))
    }

    var formattedDuration: String {
        let mins = durationSeconds / 60
        let secs = durationSeconds % 60
        if mins >= 60 {
            let hrs = mins / 60
            let remMins = mins % 60
            return String(format: "%d:%02d:%02d", hrs, remMins, secs)
        }
        return String(format: "%d:%02d", mins, secs)
    }
    
    var decodedRouteCoordinates: [CLLocationCoordinate2D] {
        guard let data = routeDataJson.data(using: .utf8),
              let pairs = try? JSONDecoder().decode([[Double]].self, from: data) else {
            return []
        }
        return pairs.compactMap { pair in
            guard pair.count == 2 else { return nil }
            return CLLocationCoordinate2D(latitude: pair[0], longitude: pair[1])
        }
    }
}

// MARK: - Food Entry
@Model
final class FoodEntry {
    var id: UUID
    var name: String
    var mealType: String // Breakfast, Lunch, Dinner, Snack
    var calories: Int
    var proteinGrams: Int
    var carbsGrams: Int
    var fatGrams: Int
    var date: Date

    init(
        id: UUID = UUID(),
        name: String,
        mealType: String = "Snack",
        calories: Int,
        proteinGrams: Int,
        carbsGrams: Int,
        fatGrams: Int,
        date: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.mealType = mealType
        self.calories = calories
        self.proteinGrams = proteinGrams
        self.carbsGrams = carbsGrams
        self.fatGrams = fatGrams
        self.date = date
    }
}

// MARK: - Macro Target
@Model
final class MacroTarget {
    var id: UUID
    var dailyCalories: Int
    var dailyProteinGrams: Int
    var dailyCarbsGrams: Int
    var dailyFatGrams: Int

    init(
        id: UUID = UUID(),
        dailyCalories: Int = 2400,
        dailyProteinGrams: Int = 180,
        dailyCarbsGrams: Int = 240,
        dailyFatGrams: Int = 70
    ) {
        self.id = id
        self.dailyCalories = dailyCalories
        self.dailyProteinGrams = dailyProteinGrams
        self.dailyCarbsGrams = dailyCarbsGrams
        self.dailyFatGrams = dailyFatGrams
    }
}

// MARK: - Planner Day
@Model
final class PlannerDay {
    var id: UUID
    var dayOfWeek: Int // 1 = Sunday, 2 = Monday, ... 7 = Saturday
    var dayName: String
    var focusBodyPart: String
    var isRestDay: Bool
    var targetExercisesDescription: String

    init(
        id: UUID = UUID(),
        dayOfWeek: Int,
        dayName: String,
        focusBodyPart: String,
        isRestDay: Bool = false,
        targetExercisesDescription: String = ""
    ) {
        self.id = id
        self.dayOfWeek = dayOfWeek
        self.dayName = dayName
        self.focusBodyPart = focusBodyPart
        self.isRestDay = isRestDay
        self.targetExercisesDescription = targetExercisesDescription
    }
}
