// Models/RunLiveActivityManager.swift
import Foundation
import SwiftUI
import Combine
import MediaPlayer

/// Manages live status broadcasts to iOS Lock Screen Live Activity,
/// Dynamic Island, and Now Playing Lock Screen widget.
@MainActor
public final class RunLiveActivityManager: ObservableObject {
    public static let shared = RunLiveActivityManager()

    @Published public var isLiveActivityEnabled: Bool = true
    @Published public var isDynamicIslandExpanded: Bool = false
    @Published public var showLockScreenSimulatorModal: Bool = false
    
    // Live Snapshot Data for Lock Screen Rendering
    @Published public var runTitle: String = "Outdoor Run"
    @Published public var totalDistanceMiles: Double = 0.0
    @Published public var elapsedSeconds: Int = 0
    @Published public var currentPaceFormatted: String = "--'--\""
    @Published public var averagePaceFormatted: String = "--'--\""
    @Published public var heartRateBpm: Int = 148
    @Published public var caloriesBurned: Int = 0
    @Published public var isTracking: Bool = false
    @Published public var isPaused: Bool = false
    @Published public var targetDistanceMiles: Double = 3.10 // Default 5K
    @Published public var currentLapNumber: Int = 1
    @Published public var lastLapTime: String = "00:00"

    private init() {}

    public var progressToTarget: Double {
        guard targetDistanceMiles > 0 else { return 0.0 }
        return min(1.0, max(0.0, totalDistanceMiles / targetDistanceMiles))
    }

    public var formattedElapsedTime: String {
        let hrs = elapsedSeconds / 3600
        let mins = (elapsedSeconds % 3600) / 60
        let secs = elapsedSeconds % 60
        if hrs > 0 {
            return String(format: "%02d:%02d:%02d", hrs, mins, secs)
        } else {
            return String(format: "%02d:%02d", mins, secs)
        }
    }

    public var heartRateZone: String {
        switch heartRateBpm {
        case ..<120: return "Zone 1 (Warm Up)"
        case 120..<140: return "Zone 2 (Fat Burn)"
        case 140..<160: return "Zone 3 (Aerobic)"
        case 160..<175: return "Zone 4 (Threshold)"
        default: return "Zone 5 (Peak)"
        }
    }

    public var heartRateZoneColor: Color {
        switch heartRateBpm {
        case ..<120: return Color.blue
        case 120..<140: return Color.teal
        case 140..<160: return Color(hex: "#CCFF00")
        case 160..<175: return Color.orange
        default: return Color.red
        }
    }

    /// Synchronizes live tracker metrics with the Lock Screen Manager and updates MPNowPlayingInfoCenter
    public func updateMetrics(
        title: String,
        distanceMiles: Double,
        elapsedSeconds: Int,
        currentPace: String,
        avgPace: String,
        heartRate: Int,
        calories: Int,
        isTracking: Bool,
        isPaused: Bool,
        lapNumber: Int = 1
    ) {
        self.runTitle = title
        self.totalDistanceMiles = distanceMiles
        self.elapsedSeconds = elapsedSeconds
        self.currentPaceFormatted = currentPace
        self.averagePaceFormatted = avgPace
        self.heartRateBpm = heartRate > 0 ? heartRate : 148
        self.caloriesBurned = calories
        self.isTracking = isTracking
        self.isPaused = isPaused
        self.currentLapNumber = lapNumber

        if isLiveActivityEnabled && isTracking {
            updateLockScreenNowPlaying()
        }
    }

    private func updateLockScreenNowPlaying() {
        let center = MPNowPlayingInfoCenter.default()
        var info: [String: Any] = [:]
        
        let titleString = String(format: "%.2f mi · %@ · %@", totalDistanceMiles, formattedElapsedTime, currentPaceFormatted)
        let artistString = isPaused ? "🏃‍♂️ Run Paused · Solxce Lock Screen" : "⚡ Solxce Live GPS · \(heartRateBpm) BPM (\(heartRateZone))"
        let albumString = String(format: "Avg Pace: %@ · %d kcal burned", averagePaceFormatted, caloriesBurned)

        info[MPMediaItemPropertyTitle] = titleString
        info[MPMediaItemPropertyArtist] = artistString
        info[MPMediaItemPropertyAlbumTitle] = albumString
        info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = Double(elapsedSeconds)
        info[MPNowPlayingInfoPropertyPlaybackRate] = (isTracking && !isPaused) ? 1.0 : 0.0

        center.nowPlayingInfo = info
    }

    public func clearLockScreenActivity() {
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
        isTracking = false
        isPaused = false
    }
}
