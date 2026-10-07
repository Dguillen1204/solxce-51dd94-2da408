// Models/LocationRunTracker.swift
import Foundation
import SwiftUI
import Combine

/// Coordinate data structure that does not import CoreLocation
public struct RunCoordinate: Codable, Hashable {
    public var latitude: Double
    public var longitude: Double

    public init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }
}

/// Standalone, pure Swift / SwiftUI in-memory running and telemetry tracker.
/// Zero CoreLocation / GPS hardware access or sensitive location API imports.
@MainActor
final class LocationRunTracker: NSObject, ObservableObject {
    // MARK: - Published Properties
    @Published var isTracking: Bool = false
    @Published var isPaused: Bool = false
    @Published var currentCoordinate: RunCoordinate?
    @Published var routeCoordinates: [RunCoordinate] = []
    
    // Live Running Metrics
    @Published var elapsedSeconds: Int = 0
    @Published var totalDistanceMeters: Double = 0.0
    @Published var currentSpeedMps: Double = 0.0 // meters per second
    @Published var splits: [RunSplit] = [] // Mile splits
    @Published var laps: [RunLapData] = [] // Live laps recorded
    @Published var currentLapElapsedSeconds: Int = 0
    @Published var currentLapDistanceMeters: Double = 0.0
    
    // Heart Rate Integration (Simulated / Connected)
    @Published var liveHeartRateBpm: Int = 0
    @Published var heartRateSamples: [Int] = []
    
    @Published var voiceAudioCuesEnabled: Bool = false
    @Published var isBackgroundTrackingActive: Bool = false
    @Published var lastVoiceCueMessage: String?
    
    private var timerSubscription: AnyCancellable?
    private var simulatedTimerSubscription: AnyCancellable?
    @Published var isSimulatedMovement: Bool = true
    private var simulationHeading: Double = 45.0
    
    override init() {
        super.init()
    }
    
    func requestPermission() {
        // No-op: sensitive location permissions completely deleted
    }
    
    public func recordLap(avgHeartRate: Int = 0, isManual: Bool = true) {
        guard isTracking else { return }
        let lapNum = laps.count + 1
        let lapDuration = max(1, currentLapElapsedSeconds)
        let lapDist = currentLapDistanceMeters * 0.000621371
        
        let paceMinutes = lapDist > 0.01 ? (Double(lapDuration) / 60.0) / lapDist : averagePaceMinutesPerMile
        let mins = Int(paceMinutes)
        let secs = Int((paceMinutes - Double(mins)) * 60)
        let paceStr = String(format: "%d:%02d /mi", mins, secs)
        
        let hr = avgHeartRate > 0 ? avgHeartRate : (liveHeartRateBpm > 0 ? liveHeartRateBpm : 152)
        
        let lap = RunLapData(
            lapNumber: lapNum,
            durationSeconds: lapDuration,
            distanceMiles: lapDist,
            formattedPace: paceStr,
            avgHeartRate: hr,
            isManualLap: isManual
        )
        
        laps.append(lap)
        currentLapElapsedSeconds = 0
        currentLapDistanceMeters = 0.0
    }
    
    // MARK: - Computed Properties
    var totalDistanceMiles: Double {
        totalDistanceMeters * 0.000621371
    }
    
    var currentPaceFormatted: String {
        guard currentSpeedMps > 0.3 else { return "--:--" }
        let speedMph = currentSpeedMps * 2.23694
        let minutesPerMile = 60.0 / speedMph
        guard minutesPerMile < 30 && minutesPerMile > 2.5 else { return "--:--" }
        let mins = Int(minutesPerMile)
        let secs = Int((minutesPerMile - Double(mins)) * 60)
        return String(format: "%d:%02d", mins, secs)
    }
    
    var averagePaceMinutesPerMile: Double {
        guard totalDistanceMiles > 0.02, elapsedSeconds > 5 else { return 8.5 }
        return (Double(elapsedSeconds) / 60.0) / totalDistanceMiles
    }
    
    var averagePaceFormatted: String {
        guard totalDistanceMiles > 0.02 else { return "--:--" }
        let mins = Int(averagePaceMinutesPerMile)
        let secs = Int((averagePaceMinutesPerMile - Double(mins)) * 60)
        return String(format: "%d:%02d", mins, secs)
    }
    
    var activeCaloriesBurned: Int {
        let weightKg = 72.0
        let met = 9.8
        let hours = Double(elapsedSeconds) / 3600.0
        return Int(met * weightKg * hours)
    }
    
    var averageHeartRateBpm: Int {
        guard !heartRateSamples.isEmpty else { return liveHeartRateBpm > 0 ? liveHeartRateBpm : 0 }
        let sum = heartRateSamples.reduce(0, +)
        return sum / heartRateSamples.count
    }
    
    var maxHeartRateBpm: Int {
        heartRateSamples.max() ?? liveHeartRateBpm
    }
    
    // MARK: - Run Tracking Controls
    func startRun() {
        elapsedSeconds = 0
        totalDistanceMeters = 0.0
        currentSpeedMps = 0.0
        splits.removeAll()
        laps.removeAll()
        heartRateSamples.removeAll()
        currentLapElapsedSeconds = 0
        currentLapDistanceMeters = 0.0
        routeCoordinates.removeAll()
        
        isTracking = true
        isPaused = false
        
        startTimer()
        startSimulation(startCoord: RunCoordinate(latitude: 37.7749, longitude: -122.4194))
    }
    
    func pauseRun() {
        isPaused = true
        timerSubscription?.cancel()
        simulatedTimerSubscription?.cancel()
    }
    
    func resumeRun() {
        isPaused = false
        startTimer()
        let initial = currentCoordinate ?? RunCoordinate(latitude: 37.7749, longitude: -122.4194)
        startSimulation(startCoord: initial)
    }
    
    func stopAndFinalizeRun() -> (distanceMiles: Double, durationSecs: Int, calories: Int, avgPace: String, route: [RunCoordinate], avgHr: Int, maxHr: Int, laps: [RunLapData]) {
        if isTracking && currentLapElapsedSeconds > 5 {
            recordLap(isManual: false)
        }
        
        let dist = totalDistanceMiles
        let duration = elapsedSeconds
        let cals = activeCaloriesBurned
        let pace = averagePaceFormatted
        let route = routeCoordinates
        let avgHr = averageHeartRateBpm
        let maxHr = maxHeartRateBpm
        let finalizedLaps = laps
        
        isTracking = false
        isPaused = false
        timerSubscription?.cancel()
        simulatedTimerSubscription?.cancel()
        
        return (dist, duration, cals, pace, route, avgHr, maxHr, finalizedLaps)
    }
    
    // MARK: - Timer & Simulation
    private func startTimer() {
        timerSubscription?.cancel()
        timerSubscription = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self, self.isTracking, !self.isPaused else { return }
                self.elapsedSeconds += 1
                self.currentLapElapsedSeconds += 1
                
                let simulatedHr = Int.random(in: 142...168)
                self.liveHeartRateBpm = simulatedHr
                self.heartRateSamples.append(simulatedHr)
            }
    }
    
    private func startSimulation(startCoord: RunCoordinate, speedMph: Double = 6.8) {
        simulatedTimerSubscription?.cancel()
        self.currentCoordinate = startCoord
        self.routeCoordinates.append(startCoord)
        
        let metersPerSecond = speedMph * 0.44704
        self.currentSpeedMps = metersPerSecond
        
        simulatedTimerSubscription = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self, self.isTracking, !self.isPaused else { return }
                
                var current = self.currentCoordinate ?? startCoord
                self.simulationHeading += Double.random(in: -8.0...8.0)
                let rad = self.simulationHeading * .pi / 180.0
                
                let metersTraveled = metersPerSecond + Double.random(in: -0.3...0.3)
                self.totalDistanceMeters += metersTraveled
                self.currentLapDistanceMeters += metersTraveled
                
                let dLat = (metersTraveled * cos(rad)) / 111111.0
                let dLon = (metersTraveled * sin(rad)) / (111111.0 * cos(current.latitude * .pi / 180.0))
                
                current = RunCoordinate(latitude: current.latitude + dLat, longitude: current.longitude + dLon)
                self.currentCoordinate = current
                self.routeCoordinates.append(current)
            }
    }
}

// MARK: - Mile Split Model
public struct RunSplit: Identifiable, Hashable, Codable {
    public let id: UUID
    public let mileNumber: Int
    public let splitDurationSeconds: Int
    public let formattedPace: String

    public init(
        id: UUID = UUID(),
        mileNumber: Int,
        splitDurationSeconds: Int,
        formattedPace: String
    ) {
        self.id = id
        self.mileNumber = mileNumber
        self.splitDurationSeconds = splitDurationSeconds
        self.formattedPace = formattedPace
    }
}
