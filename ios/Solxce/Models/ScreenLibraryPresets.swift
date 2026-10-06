// Models/ScreenLibraryPresets.swift
import Foundation
import SwiftUI

/// Preset categories of in-app screenshot captures and cards
public enum ScreenLibraryCategory: String, CaseIterable, Identifiable {
    case all = "All Screens"
    case workouts = "Workouts & PRs"
    case running = "Run & GPS"
    case nutrition = "Fuel & Macros"
    case fasting = "Fasting"
    case aiCoach = "AI Coach & Analytics"

    public var id: String { rawValue }

    public var iconName: String {
        switch self {
        case .all: return "square.grid.2x2.fill"
        case .workouts: return "dumbbell.fill"
        case .running: return "figure.run"
        case .nutrition: return "flame.fill"
        case .fasting: return "timer"
        case .aiCoach: return "sparkles"
        }
    }
}

/// A modeled app screenshot item with full graphic mockup details
public struct ScreenLibraryItem: Identifiable, Hashable {
    public let id: String
    public let category: ScreenLibraryCategory
    public let title: String
    public let screenName: String
    public let subtitle: String
    public let statValue: String
    public let statLabel: String
    public let iconName: String
    public let primaryColorHex: String
    public let secondaryColorHex: String
    public let badgeText: String
    public let metricHighlights: [String]
    public let isVideoReelPreset: Bool

    public init(
        id: String,
        category: ScreenLibraryCategory,
        title: String,
        screenName: String,
        subtitle: String,
        statValue: String,
        statLabel: String,
        iconName: String,
        primaryColorHex: String,
        secondaryColorHex: String,
        badgeText: String,
        metricHighlights: [String],
        isVideoReelPreset: Bool = false
    ) {
        self.id = id
        self.category = category
        self.title = title
        self.screenName = screenName
        self.subtitle = subtitle
        self.statValue = statValue
        self.statLabel = statLabel
        self.iconName = iconName
        self.primaryColorHex = primaryColorHex
        self.secondaryColorHex = secondaryColorHex
        self.badgeText = badgeText
        self.metricHighlights = metricHighlights
        self.isVideoReelPreset = isVideoReelPreset
    }

    public var gradientColors: [Color] {
        [Color(hex: primaryColorHex), Color(hex: secondaryColorHex)]
    }

    /// Converts this screen library preset into a `PostMediaItem` for post carousels or video reels
    public func toPostMediaItem() -> PostMediaItem {
        PostMediaItem(
            id: UUID().uuidString,
            title: title,
            iconName: iconName,
            gradientHexes: [primaryColorHex, secondaryColorHex],
            subtitle: "\(statValue) · \(statLabel)",
            isVideo: isVideoReelPreset
        )
    }

    // MARK: - Curated Built-in Library Presets
    public static let library: [ScreenLibraryItem] = [
        // 1. Workouts & PRs
        ScreenLibraryItem(
            id: "screen_bench_pr",
            category: .workouts,
            title: "Heavy Bench Press PR",
            screenName: "Workout Logger · Chest Hypertrophy",
            subtitle: "Set 5 of 5 · Clean Lockout Rep",
            statValue: "315 lbs",
            statLabel: "New 1RM Record",
            iconName: "dumbbell.fill",
            primaryColorHex: "#381010",
            secondaryColorHex: "#150707",
            badgeText: "STRENGTH PR",
            metricHighlights: ["RPE 9.5", "Bar Speed: 0.42 m/s", "12,450 lbs Volume"]
        ),
        ScreenLibraryItem(
            id: "screen_squat_quad",
            category: .workouts,
            title: "High-Bar Squat Progression",
            screenName: "Strength Arc · Legs & Glutes",
            subtitle: "4 Sets · Depth Confirmed",
            statValue: "405 lbs",
            statLabel: "3 Reps Max",
            iconName: "figure.strengthtraining.traditional",
            primaryColorHex: "#3B1808",
            secondaryColorHex: "#170802",
            badgeText: "LEG POWER",
            metricHighlights: ["Full Depth", "Knee Tracking 100%", "4 Sets @ 85%"]
        ),
        ScreenLibraryItem(
            id: "screen_deadlift_lock",
            category: .workouts,
            title: "Conventional Deadlift Max",
            screenName: "Pull Day · Posterior Chain",
            subtitle: "Belted · Hook Grip Lockout",
            statValue: "495 lbs",
            statLabel: "1 Rep Max PR",
            iconName: "bolt.shield.fill",
            primaryColorHex: "#2E1504",
            secondaryColorHex: "#120800",
            badgeText: "LIFT PR",
            metricHighlights: ["Zero Hip Dip", "0.38 m/s Lockout", "New Club 500"]
        ),

        // 2. Run & GPS
        ScreenLibraryItem(
            id: "screen_run_5k",
            category: .running,
            title: "Morning 5K Speed Run",
            screenName: "GPS Live Tracker · Waterfront Route",
            subtitle: "Zone 4 Cardio · Negative Splits",
            statValue: "19:42",
            statLabel: "5.02 km (6:20/mi)",
            iconName: "figure.run",
            primaryColorHex: "#0D2C3A",
            secondaryColorHex: "#06131A",
            badgeText: "SUB-20 5K",
            metricHighlights: ["168 Avg BPM", "Cadence 178 spm", "Elev. 142 ft"]
        ),
        ScreenLibraryItem(
            id: "screen_run_halfmarathon",
            category: .running,
            title: "Sunday Half Marathon",
            screenName: "Endurance Log · Coastal Trail",
            subtitle: "Steady Aerobic Threshold",
            statValue: "13.11 mi",
            statLabel: "1:34:12 (7:11/mi)",
            iconName: "map.fill",
            primaryColorHex: "#0B2D24",
            secondaryColorHex: "#041410",
            badgeText: "HALF MARATHON",
            metricHighlights: ["1,420 kCal Burned", "Zone 3: 78%", "Pacing Index 98%"]
        ),
        ScreenLibraryItem(
            id: "screen_run_sprint",
            category: .running,
            title: "HIIT Sprint Intervals",
            screenName: "Track & Field · 8x400m",
            subtitle: "Peak Power & Max Heart Rate",
            statValue: "58.4s",
            statLabel: "Fastest 400m Lap",
            iconName: "flag.checkered",
            primaryColorHex: "#19283E",
            secondaryColorHex: "#0A101A",
            badgeText: "SPRINT PEAK",
            metricHighlights: ["189 Max BPM", "22.4 mph Peak", "Work/Rest 1:2"]
        ),

        // 3. Fuel & Macros
        ScreenLibraryItem(
            id: "screen_macros_perfect",
            category: .nutrition,
            title: "Daily Macro Targets Hit",
            screenName: "Fuel Dashboard · 100% Macro Precision",
            subtitle: "High Protein Muscle Anabolism",
            statValue: "215g / 210g",
            statLabel: "Protein (2,840 kCal)",
            iconName: "fork.knife",
            primaryColorHex: "#2C2007",
            secondaryColorHex: "#140F03",
            badgeText: "100% ADHERENCE",
            metricHighlights: ["P: 215g (102%)", "C: 310g (99%)", "F: 72g (97%)"]
        ),
        ScreenLibraryItem(
            id: "screen_food_scanner",
            category: .nutrition,
            title: "AI Vision Food Scan",
            screenName: "Camera Scanner · Grilled Salmon Bowl",
            subtitle: "Instant Macro Breakdown via Camera",
            statValue: "680 kCal",
            statLabel: "54g P · 48g C · 22g F",
            iconName: "camera.viewfinder",
            primaryColorHex: "#2D1808",
            secondaryColorHex: "#140A03",
            badgeText: "AI FOOD LOG",
            metricHighlights: ["Omega-3 Rich", "Micros: 94%", "Glycemic Index Low"]
        ),

        // 4. Fasting
        ScreenLibraryItem(
            id: "screen_fasting_168",
            category: .fasting,
            title: "Intermittent Fasting 16:8",
            screenName: "Autophagy & Metabolic Timer",
            subtitle: "Metabolic Switch Activated",
            statValue: "16h 45m",
            statLabel: "Completed Fast Window",
            iconName: "timer",
            primaryColorHex: "#1B0D2E",
            secondaryColorHex: "#0B0514",
            badgeText: "AUTOPHAGY ACTIVE",
            metricHighlights: ["Ketosis Level 1.8", "Insulin Sensitivity Up", "Hydration 2.8L"]
        ),
        ScreenLibraryItem(
            id: "screen_fasting_204",
            category: .fasting,
            title: "Warrior Fast 20:4",
            screenName: "Deep Metabolic Reset",
            subtitle: "Extended Cellular Renewal",
            statValue: "20h 00m",
            statLabel: "100% Target Met",
            iconName: "clock.badge.checkmark",
            primaryColorHex: "#2A0E2A",
            secondaryColorHex: "#120512",
            badgeText: "WARRIOR FAST",
            metricHighlights: ["Peak Fat Oxidation", "GH Levels Primed", "Electrolytes Logged"]
        ),

        // 5. AI Coach & Analytics
        ScreenLibraryItem(
            id: "screen_aicoach_readiness",
            category: .aiCoach,
            title: "AI Coach Daily Readiness",
            screenName: "Biometrics & Recovery Engine",
            subtitle: "HRV & Sleep Optimal for Push Day",
            statValue: "96 / 100",
            statLabel: "Peak Performance Readiness",
            iconName: "sparkles",
            primaryColorHex: "#1F0F33",
            secondaryColorHex: "#0D0616",
            badgeText: "OPTIMAL STATE",
            metricHighlights: ["HRV: 82ms (+14%)", "Sleep: 8h 22m", "Recovery Index High"]
        ),
        ScreenLibraryItem(
            id: "screen_volume_progression",
            category: .aiCoach,
            title: "Weekly Volume Trend",
            screenName: "In-Depth Analytics · 4-Week Curve",
            subtitle: "Progressive Overload Verified",
            statValue: "+18.4%",
            statLabel: "Strength & Tonnage Delta",
            iconName: "chart.line.uptrend.xyaxis",
            primaryColorHex: "#0E242B",
            secondaryColorHex: "#051014",
            badgeText: "PROGRESSION",
            metricHighlights: ["Chest +22%", "Back +16%", "Legs +19%"]
        )
    ]
}
