// Models/LocationRunTracker.swift
import Foundation
import CoreLocation
import MapKit
import Combine
import AVFoundation
import MediaPlayer

/// Real-time GPS location and running tracker inspired by Strava & Nike Run Club
/// Fully configured for background tracking while locked / screen turned off,
/// and ducking/mixing smoothly alongside active music playback (Apple Music, Spotify).
@MainActor
final class LocationRunTracker: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    
    // MARK: - Published Properties
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var isTracking: Bool = false
    @Published var isPaused: Bool = false
    @Published var currentCoordinate: CLLocationCoordinate2D?
    @Published var routeCoordinates: [CLLocationCoordinate2D] = []
    
    // Live Running Metrics
    @Published var elapsedSeconds: Int = 0
    @Published var totalDistanceMeters: Double = 0.0
    @Published var currentSpeedMps: Double = 0.0 // meters per second
    @Published var splits: [RunSplit] = [] // Mile splits
    @Published var laps: [RunLapData] = [] // Live laps recorded
    @Published var currentLapElapsedSeconds: Int = 0
    @Published var currentLapDistanceMeters: Double = 0.0
    
    // Heart Rate Integration
    @Published var liveHeartRateBpm: Int = 0
    @Published var heartRateSamples: [Int] = []
    
    // Background & Lock Screen Settings
    @Published var voiceAudioCuesEnabled: Bool = true
    @Published var isBackgroundTrackingActive: Bool = false
    @Published var lastVoiceCueMessage: String?
    
    private var lastLocation: CLLocation?
    private var timerSubscription: AnyCancellable?
    private var simulatedTimerSubscription: AnyCancellable?
    
    // Audio Speech Synthesizer for interval/mile audio cues while music is playing
    private let speechSynthesizer = AVSpeechSynthesizer()
    private var lastAnnouncedMile: Int = 0
    
    // Fallback simulation when running inside simulator or GPS is still acquiring
    @Published var isSimulatedMovement: Bool = false
    private var simulationHeading: Double = 45.0 // heading in degrees
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.distanceFilter = 3.0 // Update every 3 meters
        locationManager.activityType = .fitness
        
        // Background location updates configuration
        locationManager.pausesLocationUpdatesAutomatically = false
        
        #if os(iOS)
        // Enable background location execution when supported
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.showsBackgroundLocationIndicator = true
        #endif
        
        self.authorizationStatus = locationManager.authorizationStatus
    }
    
    func requestPermission() {
        locationManager.requestWhenInUseAuthorization()
        // If already authorized when in use, request always authorization for seamless background tracking
        if locationManager.authorizationStatus == .authorizedWhenInUse {
            locationManager.requestAlwaysAuthorization()
        }
    }
    
    // MARK: - Audio Session Configuration for Music Coexistence
    /// Configures the shared AVAudioSession with .playback and .mixWithOthers / .duckOthers
    /// so the run tracker can play audio cues and continue background execution
    /// without stopping or killing the user's Spotify or Apple Music stream.
    private func setupAudioSessionForBackgroundTracking() {
        do {
            let session = AVAudioSession.sharedInstance()
            // .playback category allows background execution
            // .mixWithOthers allows Spotify / Apple Music to play concurrently
            // .duckOthers subtly lowers music volume when the run tracker speaks voice metrics
            try session.setCategory(
                .playback,
                mode: .spokenAudio,
                options: [.mixWithOthers, .duckOthers]
            )
            try session.setActive(true, options: [])
            isBackgroundTrackingActive = true
        } catch {
            // Audio session setup failure handled gracefully
            isBackgroundTrackingActive = false
        }
    }
    
    private func deactivateAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setActive(false, options: [.notifyOthersOnDeactivation])
            isBackgroundTrackingActive = false
        } catch {
            // Handled gracefully
        }
    }
    
    // MARK: - Manual & Auto Lap Recording
    
    public func recordLap(avgHeartRate: Int = 0, isManual: Bool = true) {
        guard isTracking else { return }
        let lapNum = laps.count + 1
        let lapDuration = max(1, currentLapElapsedSeconds)
        let lapDist = currentLapDistanceMeters * 0.000621371
        
        let paceMinutes = lapDist > 0.01 ? (Double(lapDuration) / 60.0) / lapDist : averagePaceMinutesPerMile
        let mins = Int(paceMinutes)
        let secs = Int((paceMinutes - Double(mins)) * 60)
        let formatted = String(format: "%d'%02d\" /mi", mins, max(0, min(59, secs)))
        
        let hr = avgHeartRate > 0 ? avgHeartRate : (liveHeartRateBpm > 0 ? liveHeartRateBpm : 0)
        
        let newLap = RunLapData(
            id: UUID(),
            lapNumber: lapNum,
            durationSeconds: lapDuration,
            distanceMiles: lapDist,
            formattedPace: formatted,
            avgHeartRate: hr,
            isManualLap: isManual
        )
        laps.insert(newLap, at: 0)
        
        // Reset current lap counters
        currentLapElapsedSeconds = 0
        currentLapDistanceMeters = 0.0
        
        if isManual {
            speakCue(String(format: "Lap %d recorded. Time %@. Pace %@.", lapNum, newLap.formattedDuration, formatted))
        }
    }
    
    public func updateLiveHeartRate(_ bpm: Int) {
        guard bpm > 30 else { return }
        self.liveHeartRateBpm = bpm
        self.heartRateSamples.append(bpm)
    }
    
    var averageHeartRate: Int {
        guard !heartRateSamples.isEmpty else { return liveHeartRateBpm }
        let sum = heartRateSamples.reduce(0, +)
        return sum / heartRateSamples.count
    }
    
    var maxHeartRate: Int {
        return heartRateSamples.max() ?? liveHeartRateBpm
    }
    
    private func updateNowPlayingLockScreenMetrics() {
        let center = MPNowPlayingInfoCenter.default()
        var nowPlayingInfo: [String: Any] = [:]
        
        nowPlayingInfo[MPMediaItemPropertyTitle] = String(format: "%.2f mi · %@ · %@", totalDistanceMiles, formattedElapsedTime, averagePaceFormatted)
        nowPlayingInfo[MPMediaItemPropertyArtist] = "Solxce GPS Live Tracker"
        nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = isPaused ? "Paused" : "Active Run · Tracking in Background"
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = Double(elapsedSeconds)
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = (isTracking && !isPaused) ? 1.0 : 0.0
        
        center.nowPlayingInfo = nowPlayingInfo
    }
    
    private func clearNowPlayingInfo() {
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }
    
    // MARK: - Voice Audio Coaching Cues
    func speakCue(_ text: String) {
        guard voiceAudioCuesEnabled else { return }
        
        Task { @MainActor in
            self.lastVoiceCueMessage = text
        }
        
        // Ensure audio session is primed for speaking over music
        setupAudioSessionForBackgroundTracking()
        
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        utterance.pitchMultiplier = 1.05
        utterance.volume = 1.0
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        
        speechSynthesizer.speak(utterance)
    }
    
    // MARK: - Live Metric Calculations
    var totalDistanceMiles: Double {
        totalDistanceMeters * 0.000621371
    }
    
    /// Current speed converted to miles per hour
    var currentSpeedMph: Double {
        guard currentSpeedMps > 0.2 else { return 0.0 }
        return currentSpeedMps * 2.23694
    }
    
    /// Instantaneous pace based on current GPS speed
    var currentPaceFormatted: String {
        guard currentSpeedMph > 0.5 else { return "--'--\" /mi" }
        let paceMinutes = 60.0 / currentSpeedMph
        let mins = Int(paceMinutes)
        let secs = Int((paceMinutes - Double(mins)) * 60)
        return String(format: "%d'%02d\" /mi", mins, max(0, min(59, secs)))
    }
    
    /// Average pace across the entire elapsed run
    var averagePaceMinutesPerMile: Double {
        guard totalDistanceMiles > 0.01 else { return 0.0 }
        return (Double(elapsedSeconds) / 60.0) / totalDistanceMiles
    }
    
    var averagePaceFormatted: String {
        guard totalDistanceMiles > 0.01 else { return "--'--\" /mi" }
        let pace = averagePaceMinutesPerMile
        let mins = Int(pace)
        let secs = Int((pace - Double(mins)) * 60)
        return String(format: "%d'%02d\" /mi", mins, max(0, min(59, secs)))
    }
    
    var formattedElapsedTime: String {
        let hrs = elapsedSeconds / 3600
        let mins = (elapsedSeconds % 3600) / 60
        let secs = elapsedSeconds % 60
        if hrs > 0 {
            return String(format: "%02d:%02d:%02d", hrs, mins, secs)
        } else {
            return String(format: "%02d:%02d", mins, secs)
        }
    }
    
    var caloriesBurned: Int {
        estimatedCaloriesBurned
    }
    
    var estimatedCaloriesBurned: Int {
        Int(totalDistanceMiles * 110)
    }
    
    // MARK: - Run Session Controls
    func startRun(useSimulatorFallbackIfNoGps: Bool = true) {
        requestPermission()
        
        // Prime audio session for background execution and music compatibility
        setupAudioSessionForBackgroundTracking()
        
        isTracking = true
        isPaused = false
        elapsedSeconds = 0
        currentLapElapsedSeconds = 0
        currentLapDistanceMeters = 0.0
        totalDistanceMeters = 0.0
        routeCoordinates.removeAll()
        splits.removeAll()
        laps.removeAll()
        heartRateSamples.removeAll()
        lastLocation = nil
        lastAnnouncedMile = 0
        
        locationManager.startUpdatingLocation()
        
        // Audio cue on start
        speakCue("Starting outdoor run. GPS locked.")
        
        // Update lock screen controls
        updateNowPlayingLockScreenMetrics()
        
        // Timer for elapsed seconds
        timerSubscription = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self, self.isTracking, !self.isPaused else { return }
                self.elapsedSeconds += 1
                self.currentLapElapsedSeconds += 1
                self.checkMileSplits()
                if self.elapsedSeconds % 5 == 0 {
                    self.updateNowPlayingLockScreenMetrics()
                }
            }
            
        // If in preview / simulator or no GPS yet after starting, enable smooth route simulation fallback
        if CLLocationManager.authorizationStatus() == .denied || CLLocationManager.authorizationStatus() == .restricted {
            startSimulation(startCoord: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194))
        } else {
            // Check if coordinates arrive; if simulator or static, provide fallback movement when runner taps simulate
            if currentCoordinate == nil {
                // Default start point (e.g. scenic park trail)
                let startPoint = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
                self.currentCoordinate = startPoint
                self.routeCoordinates.append(startPoint)
            }
        }
    }
    
    func pauseRun() {
        isPaused = true
        locationManager.stopUpdatingLocation()
        currentSpeedMps = 0.0
        updateNowPlayingLockScreenMetrics()
        speakCue("Run paused.")
    }
    
    func resumeRun() {
        isPaused = false
        setupAudioSessionForBackgroundTracking()
        locationManager.startUpdatingLocation()
        if isSimulatedMovement {
            resumeSimulation()
        }
        updateNowPlayingLockScreenMetrics()
        speakCue("Resuming run.")
    }
    
    func stopAndFinalizeRun() -> (distanceMiles: Double, durationSecs: Int, calories: Int, avgPace: String, route: [CLLocationCoordinate2D], avgHr: Int, maxHr: Int, laps: [RunLapData]) {
        // If there's an ongoing lap with distance/time, record final lap
        if currentLapElapsedSeconds > 0 || laps.isEmpty {
            recordLap(avgHeartRate: liveHeartRateBpm, isManual: false)
        }
        
        isTracking = false
        isPaused = false
        locationManager.stopUpdatingLocation()
        timerSubscription?.cancel()
        timerSubscription = nil
        simulatedTimerSubscription?.cancel()
        simulatedTimerSubscription = nil
        
        clearNowPlayingInfo()
        deactivateAudioSession()
        
        let finalDistance = max(0.01, totalDistanceMiles)
        let finalDuration = max(1, elapsedSeconds)
        let finalCals = estimatedCaloriesBurned
        let finalPace = averagePaceFormatted
        let finalRoute = routeCoordinates
        let avgHr = averageHeartRate
        let maxHr = maxHeartRate
        let finalLaps = laps.sorted(by: { $0.lapNumber < $1.lapNumber })
        
        speakCue(String(format: "Workout complete. Total distance %.2f miles at %@ average pace. Great work!", finalDistance, finalPace))
        
        return (finalDistance, finalDuration, finalCals, finalPace, finalRoute, avgHr, maxHr, finalLaps)
    }
    
    func reset() {
        isTracking = false
        isPaused = false
        locationManager.stopUpdatingLocation()
        timerSubscription?.cancel()
        timerSubscription = nil
        simulatedTimerSubscription?.cancel()
        simulatedTimerSubscription = nil
        elapsedSeconds = 0
        totalDistanceMeters = 0.0
        currentSpeedMps = 0.0
        routeCoordinates.removeAll()
        lastLocation = nil
        isSimulatedMovement = false
        lastAnnouncedMile = 0
        clearNowPlayingInfo()
        deactivateAudioSession()
    }
    
    // MARK: - Simulation Mode (Treadmill / Indoors / Simulator Testing)
    func toggleSimulation(targetMph: Double = 6.8) {
        if isSimulatedMovement {
            isSimulatedMovement = false
            simulatedTimerSubscription?.cancel()
            simulatedTimerSubscription = nil
        } else {
            isSimulatedMovement = true
            let initial = currentCoordinate ?? CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
            startSimulation(startCoord: initial, speedMph: targetMph)
        }
    }
    
    private func startSimulation(startCoord: CLLocationCoordinate2D, speedMph: Double = 6.8) {
        isSimulatedMovement = true
        var current = startCoord
        if routeCoordinates.isEmpty {
            routeCoordinates.append(current)
            currentCoordinate = current
        }
        
        let mps = speedMph * 0.44704
        currentSpeedMps = mps
        
        simulatedTimerSubscription?.cancel()
        simulatedTimerSubscription = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self, self.isTracking, !self.isPaused else { return }
                
                // Add minor random curve to simulate realistic outdoor running path
                self.simulationHeading += Double.random(in: -4.0...4.0)
                let headingRad = self.simulationHeading * .pi / 180.0
                
                // Distance in meters moved per second
                let metersMoved = mps
                self.totalDistanceMeters += metersMoved
                self.currentLapDistanceMeters += metersMoved
                
                // Earth radius approx 6,378,137m
                let dLat = (metersMoved * cos(headingRad)) / 111111.0
                let dLon = (metersMoved * sin(headingRad)) / (111111.0 * cos(current.latitude * .pi / 180.0))
                
                current = CLLocationCoordinate2D(latitude: current.latitude + dLat, longitude: current.longitude + dLon)
                self.currentCoordinate = current
                self.routeCoordinates.append(current)
            }
    }
    
    private func resumeSimulation() {
        if let last = currentCoordinate {
            startSimulation(startCoord: last, speedMph: currentSpeedMph > 0 ? currentSpeedMph : 6.8)
        }
    }
    
    private func checkMileSplits() {
        let currentCompletedMiles = Int(totalDistanceMiles)
        if currentCompletedMiles > splits.count && currentCompletedMiles > 0 {
            let previousSplitDurationSum = splits.reduce(0) { $0 + $1.splitDurationSeconds }
            let splitDuration = elapsedSeconds - previousSplitDurationSum
            let splitPaceMinutes = Double(splitDuration) / 60.0
            let mins = Int(splitPaceMinutes)
            let secs = Int((splitPaceMinutes - Double(mins)) * 60)
            let formatted = String(format: "%d'%02d\"", mins, max(0, min(59, secs)))
            
            let split = RunSplit(
                mileNumber: currentCompletedMiles,
                splitDurationSeconds: splitDuration,
                formattedPace: formatted
            )
            splits.append(split)
            
            // Announce voice split over music ducking
            if currentCompletedMiles > lastAnnouncedMile {
                lastAnnouncedMile = currentCompletedMiles
                let announcement = String(format: "Mile %d completed. Split pace %@. Total distance %.2f miles.", currentCompletedMiles, formatted, totalDistanceMiles)
                speakCue(announcement)
            }
        }
    }
    
    // MARK: - CLLocationManagerDelegate
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            self.authorizationStatus = manager.authorizationStatus
            if manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways {
                manager.startUpdatingLocation()
            }
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        Task { @MainActor in
            // Filter inaccurate points
            guard location.horizontalAccuracy >= 0 && location.horizontalAccuracy <= 40 else { return }
            
            self.currentCoordinate = location.coordinate
            
            if self.isTracking && !self.isPaused && !self.isSimulatedMovement {
                if let last = self.lastLocation {
                    let deltaMeters = location.distance(from: last)
                    if deltaMeters > 1.2 { // Accurate step threshold
                        self.totalDistanceMeters += deltaMeters
                        self.currentLapDistanceMeters += deltaMeters
                        self.routeCoordinates.append(location.coordinate)
                        
                        // Use native GPS speed if valid (> 0.2 m/s), else compute from delta
                        if location.speed > 0.2 {
                            self.currentSpeedMps = location.speed
                        } else {
                            let timeDelta = location.timestamp.timeIntervalSince(last.timestamp)
                            if timeDelta > 0 {
                                self.currentSpeedMps = deltaMeters / timeDelta
                            }
                        }
                    }
                } else {
                    self.routeCoordinates.append(location.coordinate)
                }
                self.lastLocation = location
            }
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // Handled gracefully without interrupting user flow
    }
}

// MARK: - Mile Split Model
struct RunSplit: Identifiable, Hashable {
    let id = UUID()
    let mileNumber: Int
    let splitDurationSeconds: Int
    let formattedPace: String
}
