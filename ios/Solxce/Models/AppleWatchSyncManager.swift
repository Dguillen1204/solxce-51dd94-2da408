// Models/AppleWatchSyncManager.swift
import Foundation
import WatchConnectivity
import Combine
import SwiftUI

/// Companion app connection status
public enum WatchPairingStatus: String, CaseIterable {
    case pairedAndReachable = "Connected & Active"
    case pairedNotReachable = "Paired (Standby)"
    case notPaired = "Not Paired"
    case notSupported = "Watch Unavailable"
    
    public var iconName: String {
        switch self {
        case .pairedAndReachable: return "applewatch.radiowaves.left.and.right"
        case .pairedNotReachable: return "applewatch"
        case .notPaired: return "applewatch.slash"
        case .notSupported: return "exclamationmark.triangle"
        }
    }
    
    public var tintColor: Color {
        switch self {
        case .pairedAndReachable: return Color(red: 0.831, green: 1.0, blue: 0.247) // #D4FF3F
        case .pairedNotReachable: return Color(red: 0.22, green: 0.74, blue: 0.97)  // #38BDF8
        case .notPaired: return Color(red: 0.6, green: 0.6, blue: 0.6)
        case .notSupported: return Color(red: 1.0, green: 0.231, blue: 0.361)
        }
    }
}

/// Real-time live session sync model sent to/from Apple Watch
public struct WatchLiveTelemetry: Codable, Equatable {
    public var heartRateBpm: Double
    public var heartRateZone: Int
    public var activeCalories: Int
    public var sessionDurationSeconds: Int
    public var currentPaceFormatted: String
    public var isWorkoutActive: Bool
    public var workoutTypeTitle: String
    public var lastUpdated: Date
    
    public init(
        heartRateBpm: Double = 0.0,
        heartRateZone: Int = 2,
        activeCalories: Int = 0,
        sessionDurationSeconds: Int = 0,
        currentPaceFormatted: String = "--'--\"",
        isWorkoutActive: Bool = false,
        workoutTypeTitle: String = "Solxce Session",
        lastUpdated: Date = Date()
    ) {
        self.heartRateBpm = heartRateBpm
        self.heartRateZone = heartRateZone
        self.activeCalories = activeCalories
        self.sessionDurationSeconds = sessionDurationSeconds
        self.currentPaceFormatted = currentPaceFormatted
        self.isWorkoutActive = isWorkoutActive
        self.workoutTypeTitle = workoutTypeTitle
        self.lastUpdated = lastUpdated
    }
}

/// AppleWatchSyncManager coordinates bidirectional communication between iOS and Apple Watch via WCSession.
/// Supports live telemetry mirroring, simulated test streaming, and HealthKit fallback data.
@MainActor
final class AppleWatchSyncManager: NSObject, ObservableObject, WCSessionDelegate {
    static let shared = AppleWatchSyncManager()
    
    // MARK: - Published State
    @Published var isSupported: Bool = WCSession.isSupported()
    @Published var isPaired: Bool = false
    @Published var isWatchAppInstalled: Bool = false
    @Published var isReachable: Bool = false
    @Published var pairingStatus: WatchPairingStatus = .notPaired
    @Published var liveTelemetry: WatchLiveTelemetry = WatchLiveTelemetry()
    @Published var lastSyncDate: Date? = nil
    @Published var syncMessageLog: [String] = []
    
    // Auto-sync preferences
    @Published var autoSyncOnWorkoutStart: Bool = true
    @Published var hapticAlertsOnTargetPace: Bool = true
    @Published var streamHeartRateToWatch: Bool = true
    @Published var isSimulatingWatchStream: Bool = false
    
    private var simulationTimer: AnyCancellable?
    private var wcSession: WCSession?
    
    override init() {
        super.init()
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
            self.wcSession = session
            updateSessionState()
        } else {
            self.pairingStatus = .notSupported
        }
        
        loadPreferences()
    }
    
    private func loadPreferences() {
        let defaults = UserDefaults.standard
        if defaults.object(forKey: "solxce_watch_auto_sync") != nil {
            self.autoSyncOnWorkoutStart = defaults.bool(forKey: "solxce_watch_auto_sync")
            self.hapticAlertsOnTargetPace = defaults.bool(forKey: "solxce_watch_haptics")
            self.streamHeartRateToWatch = defaults.bool(forKey: "solxce_watch_stream_hr")
        }
    }
    
    func savePreferences() {
        let defaults = UserDefaults.standard
        defaults.set(autoSyncOnWorkoutStart, forKey: "solxce_watch_auto_sync")
        defaults.set(hapticAlertsOnTargetPace, forKey: "solxce_watch_haptics")
        defaults.set(streamHeartRateToWatch, forKey: "solxce_watch_stream_hr")
    }
    
    private func updateSessionState() {
        guard let session = wcSession else {
            pairingStatus = .notSupported
            return
        }
        
        self.isPaired = session.isPaired
        self.isWatchAppInstalled = session.isWatchAppInstalled
        self.isReachable = session.isReachable
        
        if !session.isPaired {
            pairingStatus = .notPaired
        } else if session.isReachable {
            pairingStatus = .pairedAndReachable
        } else {
            pairingStatus = .pairedNotReachable
        }
    }
    
    // MARK: - Outgoing Sync & Commands
    func sendWorkoutStateToWatch(
        isActive: Bool,
        title: String,
        elapsedSeconds: Int,
        heartRate: Double,
        calories: Int,
        pace: String = "--'--\""
    ) {
        let telemetry = WatchLiveTelemetry(
            heartRateBpm: heartRate,
            heartRateZone: calculateHeartRateZone(bpm: heartRate),
            activeCalories: calories,
            sessionDurationSeconds: elapsedSeconds,
            currentPaceFormatted: pace,
            isWorkoutActive: isActive,
            workoutTypeTitle: title,
            lastUpdated: Date()
        )
        self.liveTelemetry = telemetry
        self.lastSyncDate = Date()
        
        let payload: [String: Any] = [
            "command": isActive ? "START_WORKOUT" : "STOP_WORKOUT",
            "title": title,
            "elapsedSeconds": elapsedSeconds,
            "heartRate": heartRate,
            "calories": calories,
            "pace": pace,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        if let session = wcSession, session.isReachable {
            session.sendMessage(payload, replyHandler: { reply in
                DispatchQueue.main.async {
                    self.appendLog("Sent workout update to Watch: \(title)")
                }
            }, errorHandler: { error in
                DispatchQueue.main.async {
                    self.appendLog("Watch send error: \(error.localizedDescription)")
                }
            })
        } else if let session = wcSession {
            // Update application context for non-reachable background sync
            do {
                try session.updateApplicationContext(payload)
                self.appendLog("Updated Watch application context")
            } catch {
                self.appendLog("Failed to update Watch context: \(error.localizedDescription)")
            }
        }
    }
    
    func pingWatch() {
        guard let session = wcSession, session.isReachable else {
            appendLog("Apple Watch is not reachable at this moment.")
            return
        }
        
        session.sendMessage(["command": "PING"], replyHandler: { reply in
            DispatchQueue.main.async {
                self.appendLog("Apple Watch responded: PONG (Latency: OK)")
                self.pairingStatus = .pairedAndReachable
            }
        }, errorHandler: { error in
            DispatchQueue.main.async {
                self.appendLog("Watch Ping failed: \(error.localizedDescription)")
            }
        })
    }
    
    // MARK: - Simulation Mode (Ideal for previewing Watch heart-rate & telemetry live)
    func toggleSimulation(enabled: Bool) {
        self.isSimulatingWatchStream = enabled
        if enabled {
            self.pairingStatus = .pairedAndReachable
            self.isPaired = true
            self.isReachable = true
            startSimulationStream()
            appendLog("Started Apple Watch Live Telemetry Simulation.")
        } else {
            simulationTimer?.cancel()
            simulationTimer = nil
            updateSessionState()
            appendLog("Stopped Apple Watch Live Telemetry Simulation.")
        }
    }
    
    private func startSimulationStream() {
        simulationTimer?.cancel()
        var currentBpm = 142.0
        var seconds = 0
        var cals = 0
        
        simulationTimer = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                seconds += 1
                // Dynamic HR fluctuation between 135 and 168
                let delta = Double.random(in: -2.0...2.5)
                currentBpm = max(115.0, min(178.0, currentBpm + delta))
                cals = Int(Double(seconds) * 0.18) + 120
                
                let mins = seconds / 60
                let paceSecs = (seconds % 60)
                let simulatedPace = String(format: "7'%02d\" /mi", paceSecs)
                
                self.liveTelemetry = WatchLiveTelemetry(
                    heartRateBpm: currentBpm,
                    heartRateZone: self.calculateHeartRateZone(bpm: currentBpm),
                    activeCalories: cals,
                    sessionDurationSeconds: seconds,
                    currentPaceFormatted: simulatedPace,
                    isWorkoutActive: true,
                    workoutTypeTitle: "Apple Watch Sync Live",
                    lastUpdated: Date()
                )
                self.lastSyncDate = Date()
            }
    }
    
    private func calculateHeartRateZone(bpm: Double) -> Int {
        if bpm < 114 { return 1 }
        if bpm < 133 { return 2 }
        if bpm < 152 { return 3 }
        if bpm < 171 { return 4 }
        return 5
    }
    
    private func appendLog(_ message: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        let timestamp = formatter.string(from: Date())
        syncMessageLog.insert("[\(timestamp)] \(message)", at: 0)
        if syncMessageLog.count > 30 {
            syncMessageLog.removeLast()
        }
    }
    
    // MARK: - WCSessionDelegate
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        Task { @MainActor in
            self.updateSessionState()
            if let error = error {
                self.appendLog("WCSession activation error: \(error.localizedDescription)")
            } else {
                self.appendLog("Apple Watch connectivity session active (State: \(activationState.rawValue)).")
            }
        }
    }
    
    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {
        Task { @MainActor in
            self.appendLog("WCSession became inactive.")
        }
    }
    
    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        Task { @MainActor in
            self.appendLog("WCSession deactivated. Reactivating...")
            WCSession.default.activate()
        }
    }
    
    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in
            self.updateSessionState()
            self.appendLog("Watch Reachability changed: \(session.isReachable ? "Reachable" : "Unreachable")")
        }
    }
    
    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        Task { @MainActor in
            if let hr = message["heartRate"] as? Double {
                self.liveTelemetry.heartRateBpm = hr
                self.liveTelemetry.heartRateZone = self.calculateHeartRateZone(bpm: hr)
                self.liveTelemetry.lastUpdated = Date()
                self.appendLog("Received live Heart Rate from Apple Watch: \(Int(hr)) BPM")
            }
            if let calories = message["activeCalories"] as? Int {
                self.liveTelemetry.activeCalories = calories
            }
            replyHandler(["status": "ACK"])
        }
    }
    
    nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        Task { @MainActor in
            if let hr = applicationContext["heartRate"] as? Double {
                self.liveTelemetry.heartRateBpm = hr
                self.liveTelemetry.heartRateZone = self.calculateHeartRateZone(bpm: hr)
                self.liveTelemetry.lastUpdated = Date()
            }
            self.appendLog("Received updated Watch Application Context")
        }
    }
}
