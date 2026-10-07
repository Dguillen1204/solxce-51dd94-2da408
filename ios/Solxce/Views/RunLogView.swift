// Views/RunLogView.swift
import SwiftUI
import SwiftData
import MapKit
import CoreLocation

enum RunTrackingMode: String, CaseIterable, Identifiable {
    case live = "Live GPS Tracker"
    case manual = "Manual Entry"

    var id: String { rawValue }
}

struct RunLogView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \RunEntry.date, order: .reverse) private var pastRuns: [RunEntry]

    @StateObject private var tracker = LocationRunTracker()
    @ObservedObject private var healthKit = HealthKitService.shared
    @ObservedObject private var lockScreenManager = RunLiveActivityManager.shared
    
    @State private var mode: RunTrackingMode = .live
    @State private var runTitle: String = "Outdoor Run"
    @State private var notes: String = ""
    @State private var showFinishConfirmation: Bool = false
    @State private var selectedHistoricalRun: RunEntry? = nil
    @State private var showingLockScreenSimulator: Bool = false
    
    // Map View Camera
    @State private var cameraPosition: MapCameraPosition = .userLocation(fallback: .automatic)
    @State private var mapInteractionUserMode: Bool = false
    
    // Manual Entry State
    @State private var manualDistanceMiles: Double = 3.1
    @State private var manualDurationMinutes: Int = 24
    @State private var manualDurationSeconds: Int = 30
    @State private var manualCaloriesBurned: Int = 340
    
    // Speed Simulation Dial for test / indoor training
    @State private var simulationSpeedMph: Double = 7.0

    // MARK: - Manual Computed Properties
    var manualTotalDurationSeconds: Int {
        (manualDurationMinutes * 60) + manualDurationSeconds
    }

    var manualPaceMinutesPerMile: Double {
        guard manualDistanceMiles > 0 else { return 0 }
        return (Double(manualTotalDurationSeconds) / 60.0) / manualDistanceMiles
    }

    var manualFormattedPace: String {
        let pace = manualPaceMinutesPerMile
        let mins = Int(pace)
        let secs = Int((pace - Double(mins)) * 60)
        return String(format: "%d'%02d\" /mi", mins, max(0, min(59, secs)))
    }

    private var finishAlertMessage: String {
        String(format: "Recorded %.2f miles in %@ (Avg Pace: %@).", tracker.totalDistanceMiles, tracker.formattedElapsedTime, tracker.averagePaceFormatted)
    }

    var body: some View {
        NavigationStack {
            mainScrollView
                .background(AppTheme.ground.ignoresSafeArea())
                .navigationTitle("Track Run")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar { toolbarContent }
                .alert("Finish Run?", isPresented: $showFinishConfirmation) {
                    finishAlertButtons
                } message: {
                    Text(finishAlertMessage)
                }
                .sheet(item: $selectedHistoricalRun) { run in
                    RunRouteDetailSheet(run: run)
                }
                .sheet(isPresented: $showingLockScreenSimulator) {
                    RunLockScreenSimulatorSheet()
                }
                .onChange(of: tracker.isTracking) { _, isTracking in
                    handleTrackingStateChange(isTracking: isTracking)
                }
                .onChange(of: tracker.elapsedSeconds) { _, seconds in
                    handleElapsedSecondsChange(seconds: seconds)
                }
        }
    }

    private var mainScrollView: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.md) {
                // Segmented Mode Selector
                Picker("Tracking Mode", selection: $mode) {
                    ForEach(RunTrackingMode.allCases) { item in
                        Text(item.rawValue).tag(item)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.top, AppTheme.Spacing.xs)

                if mode == .live {
                    liveGpsTrackerView
                } else {
                    manualEntryCard
                }

                // Workout Details / Title & Notes
                workoutDetailsCard

                // Past Runs Log with Route Maps
                pastRunsSection
            }
            .padding(.horizontal, AppTheme.Spacing.screenMargin)
            .padding(.bottom, AppTheme.Spacing.xxl)
        }
    }

    private var workoutDetailsCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
            Text("RUN DETAILS")
                .font(AppTheme.eyebrowFont)
                .tracking(1.5)
                .foregroundStyle(AppTheme.textSecondary)

            TextField("Run Name (e.g., Morning 5K, Strava Segment)", text: $runTitle)
                .font(AppTheme.bodyFont)
                .padding(AppTheme.Spacing.sm)
                .background(AppTheme.field)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.tag))
                .foregroundStyle(AppTheme.text)

            TextField("Notes (shoes, route conditions, elevation)", text: $notes)
                .font(AppTheme.bodyFont)
                .padding(AppTheme.Spacing.sm)
                .background(AppTheme.field)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.tag))
                .foregroundStyle(AppTheme.text)
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.card))
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("Close") {
                tracker.reset()
                dismiss()
            }
            .foregroundStyle(AppTheme.textSecondary)
        }

        if mode == .manual {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save Run") {
                    saveManualRun()
                    dismiss()
                }
                .font(AppTheme.headlineFont)
                .foregroundStyle(AppTheme.primary)
            }
        }
    }

    @ViewBuilder
    private var finishAlertButtons: some View {
        Button("Save & Record") {
            saveLiveRun()
            dismiss()
        }
        Button("Discard", role: .destructive) {
            tracker.reset()
        }
        Button("Keep Running", role: .cancel) {
            tracker.resumeRun()
        }
    }

    private func handleTrackingStateChange(isTracking: Bool) {
        let hr = healthKit.currentHeartRateBpm > 0 ? healthKit.currentHeartRateBpm : 152.0
        lockScreenManager.updateMetrics(
            title: runTitle,
            distanceMiles: tracker.totalDistanceMiles,
            elapsedSeconds: tracker.elapsedSeconds,
            currentPace: tracker.currentPaceFormatted,
            avgPace: tracker.averagePaceFormatted,
            heartRate: Int(hr),
            calories: tracker.estimatedCaloriesBurned,
            isTracking: isTracking,
            isPaused: tracker.isPaused,
            lapNumber: max(1, tracker.laps.count + 1)
        )
        if !isTracking && !tracker.isPaused {
            lockScreenManager.clearLockScreenActivity()
        }
    }

    private func handleElapsedSecondsChange(seconds: Int) {
        let healthKitHr = healthKit.currentHeartRateBpm
        let hr: Double = healthKitHr > 0 ? healthKitHr : 152.0
        
        lockScreenManager.updateMetrics(
            title: runTitle,
            distanceMiles: tracker.totalDistanceMiles,
            elapsedSeconds: seconds,
            currentPace: tracker.currentPaceFormatted,
            avgPace: tracker.averagePaceFormatted,
            heartRate: Int(hr),
            calories: tracker.estimatedCaloriesBurned,
            isTracking: tracker.isTracking,
            isPaused: tracker.isPaused,
            lapNumber: max(1, tracker.laps.count + 1)
        )
    }

    // MARK: - Live GPS Tracker View (Nike / Strava style)
    private var liveGpsTrackerView: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            // Live Status Header Banner
            HStack {
                HStack(spacing: 8) {
                    Circle()
                        .fill(tracker.isTracking && !tracker.isPaused ? AppTheme.primary : (tracker.isPaused ? AppTheme.carbsColor : AppTheme.textMuted))
                        .frame(width: 10, height: 10)
                        .scaleEffect(tracker.isTracking && !tracker.isPaused ? 1.25 : 1.0)
                        .animation(tracker.isTracking && !tracker.isPaused ? .easeInOut(duration: 0.8).repeatForever(autoreverses: true) : .default, value: tracker.isTracking)

                    Text(tracker.isTracking && !tracker.isPaused ? "GPS LIVE TRACKING" : (tracker.isPaused ? "TRACKING PAUSED" : "GPS READY"))
                        .font(AppTheme.eyebrowFont)
                        .tracking(1.5)
                        .foregroundStyle(tracker.isTracking && !tracker.isPaused ? AppTheme.primary : AppTheme.textSecondary)
                }

                Spacer()

                if tracker.isSimulatedMovement {
                    Text("SIMULATED")
                        .font(AppTheme.captionFont)
                        .fontWeight(.bold)
                        .foregroundStyle(.black)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(AppTheme.carbsColor)
                        .clipShape(Capsule())
                }

                if tracker.isTracking {
                    Text("GPS SPEED: \(String(format: "%.1f", tracker.currentSpeedMph)) MPH")
                        .font(AppTheme.captionFont)
                        .fontWeight(.bold)
                        .foregroundStyle(AppTheme.primary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(AppTheme.primary.opacity(0.15))
                        .clipShape(Capsule())
                }
            }

            // Interactive Map View with Live Polyline & Pulse Marker
            ZStack(alignment: .bottomTrailing) {
                Map(position: $cameraPosition) {
                    // Current User Location Pin & Pulse
                    if let current = tracker.currentCoordinate {
                        Annotation("Runner", coordinate: current) {
                            ZStack {
                                Circle()
                                    .fill(AppTheme.primary.opacity(0.35))
                                    .frame(width: 32, height: 32)
                                Circle()
                                    .fill(AppTheme.primary)
                                    .frame(width: 16, height: 16)
                                Circle()
                                    .stroke(Color.black, lineWidth: 2)
                                    .frame(width: 16, height: 16)
                            }
                        }
                    }

                    // Route Polyline (Strava Athletic Volt Glow)
                    if tracker.routeCoordinates.count > 1 {
                        MapPolyline(coordinates: tracker.routeCoordinates)
                            .stroke(AppTheme.primary, lineWidth: 5)
                    }
                }
                .mapStyle(.standard(elevation: .realistic, pointsOfInterest: .excludingAll))
                .frame(height: 240)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.card))
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.Radii.card)
                        .strokeBorder(AppTheme.hairline, lineWidth: 1)
                )

                // Map Re-center Floating Action
                VStack(spacing: 8) {
                    Button(action: {
                        if let current = tracker.currentCoordinate {
                            withAnimation {
                                cameraPosition = .region(MKCoordinateRegion(
                                    center: current,
                                    span: MKCoordinateSpan(latitudeDelta: 0.008, longitudeDelta: 0.008)
                                ))
                            }
                        }
                    }) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(AppTheme.onPrimary)
                            .frame(width: 36, height: 36)
                            .background(AppTheme.primary)
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.4), radius: 4, x: 0, y: 2)
                    }
                    .padding(10)
                }
            }

            // Background & Lock Screen Live Activity Bar
            if tracker.isTracking {
                RunLockScreenBannerView {
                    showingLockScreenSimulator = true
                }
            }

            // Big Live Timer Display
            VStack(spacing: 2) {
                Text(tracker.formattedElapsedTime)
                    .font(.system(size: 52, weight: .black, design: .monospaced))
                    .foregroundStyle(AppTheme.text)
                    .contentTransition(.numericText())

                Text("DURATION")
                    .font(AppTheme.eyebrowFont)
                    .tracking(2.0)
                    .foregroundStyle(AppTheme.textMuted)
            }
            .padding(.top, AppTheme.Spacing.xs)

            // Primary Running Metrics (Nike Run Club layout)
            HStack(spacing: AppTheme.Spacing.sm) {
                VStack(spacing: 2) {
                    Text(String(format: "%.2f", tracker.totalDistanceMiles))
                        .font(AppTheme.heroNumeralFont)
                        .foregroundStyle(AppTheme.primary)
                    Text("DISTANCE (MI)")
                        .font(AppTheme.eyebrowFont)
                        .tracking(1.5)
                        .foregroundStyle(AppTheme.textSecondary)
                }
                .frame(maxWidth: .infinity)

                Divider()
                    .background(AppTheme.hairline)

                VStack(spacing: 2) {
                    Text(tracker.currentPaceFormatted)
                        .font(AppTheme.heroNumeralFont)
                        .foregroundStyle(AppTheme.primary)
                    Text("CURRENT PACE")
                        .font(AppTheme.eyebrowFont)
                        .tracking(1.5)
                        .foregroundStyle(AppTheme.textSecondary)
                }
                .frame(maxWidth: .infinity)

                Divider()
                    .background(AppTheme.hairline)

                // Live Heart Rate Tile
                VStack(spacing: 2) {
                    let hr = healthKit.currentHeartRateBpm > 0 ? Int(healthKit.currentHeartRateBpm) : 146
                    HStack(spacing: 3) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(Color(red: 1.0, green: 0.231, blue: 0.361))
                        Text("\(hr)")
                            .font(AppTheme.heroNumeralFont)
                            .foregroundStyle(AppTheme.text)
                    }
                    Text("HEART RATE (BPM)")
                        .font(AppTheme.eyebrowFont)
                        .tracking(1.5)
                        .foregroundStyle(AppTheme.textSecondary)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.vertical, AppTheme.Spacing.xs)

            // Live Mile Splits (Strava / Nike) & Lap Times
            if !tracker.splits.isEmpty || !tracker.laps.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("LAPS & MILE SPLITS")
                            .font(AppTheme.eyebrowFont)
                            .tracking(1.5)
                            .foregroundStyle(AppTheme.textMuted)
                        
                        Spacer()
                        
                        if tracker.isTracking && !tracker.isPaused {
                            Button(action: {
                                let currentHr = watchManager.liveTelemetry.heartRateBpm > 0 ? Int(watchManager.liveTelemetry.heartRateBpm) : (healthKit.currentHeartRateBpm > 0 ? Int(healthKit.currentHeartRateBpm) : 152)
                                tracker.recordLap(avgHeartRate: currentHr, isManual: true)
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "plus.circle.fill")
                                    Text("TAP LAP")
                                }
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(AppTheme.onPrimary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(AppTheme.primary)
                                .clipShape(Capsule())
                            }
                        }
                    }

                    // Horizontal Lap Chips
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(tracker.laps) { lap in
                                VStack(alignment: .leading, spacing: 2) {
                                    HStack(spacing: 4) {
                                        Text("LAP \(lap.lapNumber)")
                                            .font(AppTheme.eyebrowFont)
                                            .foregroundStyle(AppTheme.primary)
                                        if lap.isManualLap {
                                            Text("MANUAL")
                                                .font(.system(size: 8, weight: .black))
                                                .foregroundStyle(AppTheme.accent)
                                        }
                                    }
                                    Text(lap.formattedDuration)
                                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                                        .foregroundStyle(AppTheme.text)
                                    HStack(spacing: 4) {
                                        Text(String(format: "%.2f mi", lap.distanceMiles))
                                            .font(AppTheme.captionFont)
                                            .foregroundStyle(AppTheme.textSecondary)
                                        if lap.avgHeartRate > 0 {
                                            Text("· \(lap.avgHeartRate) bpm")
                                                .font(AppTheme.captionFont)
                                                .foregroundStyle(Color(red: 1.0, green: 0.231, blue: 0.361))
                                        }
                                    }
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(AppTheme.field)
                                .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.tag))
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } else if tracker.isTracking && !tracker.isPaused {
                // Quick Lap Button when tracking is in progress
                HStack {
                    Text(String(format: "Lap 1 · %d:%02d · %.2f mi", tracker.currentLapElapsedSeconds / 60, tracker.currentLapElapsedSeconds % 60, tracker.currentLapDistanceMeters * 0.000621371))
                        .font(AppTheme.captionFont)
                        .foregroundStyle(AppTheme.textMuted)

                    Spacer()

                    Button(action: {
                        let currentHr = watchManager.liveTelemetry.heartRateBpm > 0 ? Int(watchManager.liveTelemetry.heartRateBpm) : (healthKit.currentHeartRateBpm > 0 ? Int(healthKit.currentHeartRateBpm) : 152)
                        tracker.recordLap(avgHeartRate: currentHr, isManual: true)
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "timer")
                            Text("LOG LAP")
                        }
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(AppTheme.onPrimary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(AppTheme.primary)
                        .clipShape(Capsule())
                    }
                }
                .padding(.vertical, 2)
            }

            // Indoor / Simulator Movement Assist Toggle
            HStack {
                Button(action: {
                    tracker.toggleSimulation(targetMph: simulationSpeedMph)
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: tracker.isSimulatedMovement ? "figure.run.circle.fill" : "figure.run.circle")
                        Text(tracker.isSimulatedMovement ? "Simulating GPS Trail" : "Simulate Live Route")
                    }
                    .font(AppTheme.captionFont)
                    .foregroundStyle(tracker.isSimulatedMovement ? AppTheme.primary : AppTheme.textSecondary)
                }

                Spacer()

                if tracker.isSimulatedMovement {
                    HStack(spacing: 4) {
                        Text(String(format: "%.1f mph", simulationSpeedMph))
                            .font(AppTheme.captionFont)
                            .foregroundStyle(AppTheme.text)
                        
                        Stepper("", value: $simulationSpeedMph, in: 4.0...12.0, step: 0.5)
                            .labelsHidden()
                            .onChange(of: simulationSpeedMph) { _, newValue in
                                if tracker.isSimulatedMovement {
                                    tracker.toggleSimulation()
                                    tracker.toggleSimulation(targetMph: newValue)
                                }
                            }
                    }
                }
            }
            .padding(.horizontal, 4)

            // Primary Control Buttons (Start, Pause, Resume, Finish)
            HStack(spacing: AppTheme.Spacing.sm) {
                if !tracker.isTracking && !tracker.isPaused {
                    Button(action: {
                        tracker.startRun()
                    }) {
                        HStack {
                            Image(systemName: "play.fill")
                            Text("START RUN")
                        }
                        .font(AppTheme.headlineFont)
                        .foregroundStyle(AppTheme.onPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(AppTheme.primary)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.card))
                    }
                } else if tracker.isTracking && !tracker.isPaused {
                    Button(action: {
                        tracker.pauseRun()
                    }) {
                        HStack {
                            Image(systemName: "pause.fill")
                            Text("PAUSE")
                        }
                        .font(AppTheme.headlineFont)
                        .foregroundStyle(AppTheme.text)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(AppTheme.field)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.card))
                    }

                    Button(action: {
                        tracker.pauseRun()
                        showFinishConfirmation = true
                    }) {
                        HStack {
                            Image(systemName: "flag.checkered")
                            Text("FINISH")
                        }
                        .font(AppTheme.headlineFont)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(AppTheme.accent)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.card))
                    }
                } else if tracker.isPaused {
                    Button(action: {
                        tracker.resumeRun()
                    }) {
                        HStack {
                            Image(systemName: "play.fill")
                            Text("RESUME")
                        }
                        .font(AppTheme.headlineFont)
                        .foregroundStyle(AppTheme.onPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(AppTheme.primary)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.card))
                    }

                    Button(action: {
                        showFinishConfirmation = true
                    }) {
                        HStack {
                            Image(systemName: "flag.checkered")
                            Text("FINISH")
                        }
                        .font(AppTheme.headlineFont)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(AppTheme.accent)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.card))
                    }
                }
            }
        }
        .padding(AppTheme.Spacing.md)
        .frame(maxWidth: .infinity)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.card))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radii.card)
                .strokeBorder(tracker.isTracking && !tracker.isPaused ? AppTheme.primary.opacity(0.6) : AppTheme.hairline, lineWidth: 1.5)
        )
    }

    // MARK: - Manual Entry Card
    private var manualEntryCard: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            VStack(spacing: AppTheme.Spacing.md) {
                Text("ESTIMATED PACE")
                    .font(AppTheme.eyebrowFont)
                    .tracking(1.5)
                    .foregroundStyle(AppTheme.textSecondary)

                Text(manualFormattedPace)
                    .font(AppTheme.heroNumeralFont)
                    .foregroundStyle(AppTheme.primary)

                HStack(spacing: AppTheme.Spacing.xl) {
                    statPill(label: "DISTANCE", value: "\(String(format: "%.2f", manualDistanceMiles)) mi")
                    statPill(label: "DURATION", value: String(format: "%d:%02d", manualDurationMinutes, manualDurationSeconds))
                    statPill(label: "CALORIES", value: "\(manualCaloriesBurned) kcal")
                }
            }
            .padding(AppTheme.Spacing.md)
            .frame(maxWidth: .infinity)
            .background(AppTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.card))

            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                Text("MANUAL LOG VALUES")
                    .font(AppTheme.eyebrowFont)
                    .tracking(1.5)
                    .foregroundStyle(AppTheme.textSecondary)

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Distance")
                            .font(AppTheme.subheadlineFont)
                            .foregroundStyle(AppTheme.textSecondary)
                        Spacer()
                        Text(String(format: "%.2f miles", manualDistanceMiles))
                            .font(AppTheme.headlineFont)
                            .foregroundStyle(AppTheme.text)
                    }
                    Slider(value: $manualDistanceMiles, in: 0.1...26.2, step: 0.1)
                        .tint(AppTheme.primary)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Duration")
                        .font(AppTheme.subheadlineFont)
                        .foregroundStyle(AppTheme.textSecondary)

                    HStack(spacing: AppTheme.Spacing.sm) {
                        HStack {
                            TextField("Mins", value: $manualDurationMinutes, format: .number)
                                .keyboardType(.numberPad)
                                .frame(width: 50)
                            Text("min")
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                        .padding(8)
                        .background(AppTheme.field)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.tag))

                        HStack {
                            TextField("Secs", value: $manualDurationSeconds, format: .number)
                                .keyboardType(.numberPad)
                                .frame(width: 50)
                            Text("sec")
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                        .padding(8)
                        .background(AppTheme.field)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.tag))

                        Spacer()
                    }
                }
            }
            .padding(AppTheme.Spacing.md)
            .background(AppTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.card))
        }
    }

    // MARK: - Past Runs List with Interactive Map Replay
    private var pastRunsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text("RUN LOG & SAVED ROUTES")
                .font(AppTheme.eyebrowFont)
                .tracking(1.5)
                .foregroundStyle(AppTheme.textSecondary)

            if pastRuns.isEmpty {
                Text("No previous runs logged.")
                    .font(AppTheme.captionFont)
                    .foregroundStyle(AppTheme.textMuted)
            } else {
                ForEach(pastRuns) { run in
                    Button(action: {
                        selectedHistoricalRun = run
                    }) {
                        HStack(spacing: 12) {
                            // Mini Route / Map Icon
                            ZStack {
                                RoundedRectangle(cornerRadius: AppTheme.Radii.tag)
                                    .fill(AppTheme.field)
                                    .frame(width: 44, height: 44)

                                Image(systemName: run.decodedRouteCoordinates.isEmpty ? "figure.run" : "map.fill")
                                    .font(.system(size: 18))
                                    .foregroundStyle(AppTheme.primary)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text(run.title)
                                    .font(AppTheme.headlineFont)
                                    .foregroundStyle(AppTheme.text)
                                Text("\(String(format: "%.2f", run.distanceMiles)) mi · \(run.formattedDuration) · \(run.formattedPace)")
                                    .font(AppTheme.captionFont)
                                    .foregroundStyle(AppTheme.textSecondary)
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: 2) {
                                Text(run.date.formatted(.dateTime.month().day()))
                                    .font(AppTheme.captionFont)
                                    .foregroundStyle(AppTheme.textMuted)
                                
                                if !run.decodedRouteCoordinates.isEmpty {
                                    Text("MAP ROUTE")
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundStyle(AppTheme.primary)
                                        .padding(.horizontal, 4)
                                        .padding(.vertical, 2)
                                        .background(AppTheme.primary.opacity(0.15))
                                        .clipShape(RoundedRectangle(cornerRadius: 3))
                                }
                            }
                        }
                        .padding(AppTheme.Spacing.sm)
                        .background(AppTheme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.tag))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func statPill(label: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(AppTheme.eyebrowFont)
                .foregroundStyle(AppTheme.textMuted)
            Text(value)
                .font(AppTheme.subheadlineFont)
                .bold()
                .foregroundStyle(AppTheme.text)
        }
    }

    // MARK: - Save Handlers
    private func saveLiveRun() {
        let (dist, dur, cals, _, routeCoords, avgHr, maxHr, laps) = tracker.stopAndFinalizeRun()
        
        let hrToSave = avgHr > 0 ? avgHr : (healthKit.currentHeartRateBpm > 0 ? Int(healthKit.currentHeartRateBpm) : 148)
        let maxHrToSave = maxHr > 0 ? maxHr : (hrToSave + 18)
        
        let entry = RunEntry(
            title: runTitle.isEmpty ? "Outdoor Run" : runTitle,
            distanceMiles: max(0.01, dist),
            durationSeconds: max(1, dur),
            date: Date(),
            caloriesBurned: cals,
            notes: notes,
            routeCoordinates: routeCoords,
            averageHeartRateBpm: hrToSave,
            maxHeartRateBpm: maxHrToSave,
            laps: laps
        )
        modelContext.insert(entry)
        try? modelContext.save()
        
        Task {
            _ = await healthKit.saveCompletedWorkout(
                title: entry.title,
                durationSeconds: entry.durationSeconds,
                caloriesBurned: Double(entry.caloriesBurned),
                distanceMiles: entry.distanceMiles
            )
        }
    }

    private func saveManualRun() {
        let entry = RunEntry(
            title: runTitle.isEmpty ? "Outdoor Run" : runTitle,
            distanceMiles: manualDistanceMiles,
            durationSeconds: manualTotalDurationSeconds,
            date: Date(),
            caloriesBurned: manualCaloriesBurned,
            notes: notes,
            averageHeartRateBpm: healthKit.currentHeartRateBpm > 0 ? Int(healthKit.currentHeartRateBpm) : 145,
            maxHeartRateBpm: 165
        )
        modelContext.insert(entry)
        try? modelContext.save()
    }
}

// MARK: - Run Route Detail Sheet (Historical GPS Replay)
struct RunRouteDetailSheet: View {
    let run: RunEntry
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.lg) {
                    // Map View of the logged route
                    let coordinates = run.decodedRouteCoordinates
                    if !coordinates.isEmpty {
                        Map {
                            MapPolyline(coordinates: coordinates)
                                .stroke(AppTheme.primary, lineWidth: 6)

                            if let start = coordinates.first {
                                Annotation("Start", coordinate: start) {
                                    Circle()
                                        .fill(AppTheme.primary)
                                        .frame(width: 14, height: 14)
                                        .overlay(Circle().stroke(Color.black, lineWidth: 2))
                                }
                            }

                            if let finish = coordinates.last {
                                Annotation("Finish", coordinate: finish) {
                                    Image(systemName: "flag.checkered.circle.fill")
                                        .font(.system(size: 20))
                                        .foregroundStyle(AppTheme.accent)
                                        .background(Circle().fill(Color.black))
                                }
                            }
                        }
                        .frame(height: 280)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.card))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.Radii.card)
                                .strokeBorder(AppTheme.hairline, lineWidth: 1)
                        )
                    } else {
                        VStack(spacing: 8) {
                            Image(systemName: "map")
                                .font(.system(size: 32))
                                .foregroundStyle(AppTheme.textMuted)
                            Text("Manual Entry — No GPS breadcrumbs recorded")
                                .font(AppTheme.captionFont)
                                .foregroundStyle(AppTheme.textMuted)
                        }
                        .frame(height: 140)
                        .frame(maxWidth: .infinity)
                        .background(AppTheme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.card))
                    }

                    // Run Metrics Summary Hero
                    VStack(spacing: AppTheme.Spacing.md) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(run.title)
                                    .font(AppTheme.displayFont)
                                    .foregroundStyle(AppTheme.text)

                                Text(run.date.formatted(date: .long, time: .shortened))
                                    .font(AppTheme.captionFont)
                                    .foregroundStyle(AppTheme.textMuted)
                            }
                            
                            Spacer()
                            
                            // Share Run Button
                            ShareLink(
                                item: generateShareText(run: run),
                                subject: Text("My Solxce Run: \(run.title)"),
                                message: Text("Crushed \(String(format: "%.2f", run.distanceMiles)) miles in \(run.formattedDuration) with Solxce! 🔥")
                            ) {
                                HStack(spacing: 6) {
                                    Image(systemName: "square.and.arrow.up")
                                    Text("Share")
                                }
                                .font(AppTheme.subheadlineFont)
                                .bold()
                                .foregroundStyle(AppTheme.onPrimary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(AppTheme.primary)
                                .clipShape(Capsule())
                            }
                        }

                        Divider().background(AppTheme.hairline)

                        // 4 Primary Stats
                        HStack(spacing: AppTheme.Spacing.md) {
                            metricBox(label: "DISTANCE", value: "\(String(format: "%.2f", run.distanceMiles)) mi")
                            metricBox(label: "TIME", value: run.formattedDuration)
                            metricBox(label: "AVG PACE", value: run.formattedPace)
                            metricBox(label: "CALORIES", value: "\(run.caloriesBurned) kcal")
                        }

                        // Biometrics Row: Average & Max Heart Rate
                        if run.averageHeartRateBpm > 0 {
                            Divider().background(AppTheme.hairline)

                            HStack(spacing: AppTheme.Spacing.lg) {
                                HStack(spacing: 8) {
                                    Image(systemName: "heart.fill")
                                        .foregroundStyle(Color(red: 1.0, green: 0.231, blue: 0.361))
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("AVG HEART RATE")
                                            .font(AppTheme.eyebrowFont)
                                            .foregroundStyle(AppTheme.textMuted)
                                        Text("\(run.averageHeartRateBpm) BPM")
                                            .font(AppTheme.subheadlineFont)
                                            .bold()
                                            .foregroundStyle(AppTheme.text)
                                    }
                                }

                                if run.maxHeartRateBpm > 0 {
                                    HStack(spacing: 8) {
                                        Image(systemName: "bolt.heart.fill")
                                            .foregroundStyle(AppTheme.accent)
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("MAX HEART RATE")
                                                .font(AppTheme.eyebrowFont)
                                                .foregroundStyle(AppTheme.textMuted)
                                            Text("\(run.maxHeartRateBpm) BPM")
                                                .font(AppTheme.subheadlineFont)
                                                .bold()
                                                .foregroundStyle(AppTheme.text)
                                        }
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding(AppTheme.Spacing.md)
                    .background(AppTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.card))

                    // Laps & Mile Splits Breakdown
                    let laps = run.decodedLaps
                    if !laps.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("LAP TIMES & SPLITS")
                                    .font(AppTheme.eyebrowFont)
                                    .tracking(1.5)
                                    .foregroundStyle(AppTheme.textSecondary)

                                Spacer()

                                Text("\(laps.count) LAPS")
                                    .font(AppTheme.captionFont)
                                    .foregroundStyle(AppTheme.textMuted)
                            }

                            VStack(spacing: 8) {
                                ForEach(laps) { lap in
                                    HStack {
                                        HStack(spacing: 6) {
                                            Text("Lap \(lap.lapNumber)")
                                                .font(AppTheme.bodyFont)
                                                .bold()
                                                .foregroundStyle(AppTheme.text)
                                            if lap.isManualLap {
                                                Text("MANUAL")
                                                    .font(.system(size: 8, weight: .black))
                                                    .foregroundStyle(AppTheme.accent)
                                                    .padding(.horizontal, 4)
                                                    .padding(.vertical, 2)
                                                    .background(AppTheme.accent.opacity(0.15))
                                                    .clipShape(RoundedRectangle(cornerRadius: 3))
                                            }
                                        }

                                        Spacer()

                                        Text(String(format: "%.2f mi", lap.distanceMiles))
                                            .font(AppTheme.captionFont)
                                            .foregroundStyle(AppTheme.textSecondary)
                                            .frame(width: 60, alignment: .trailing)

                                        Text(lap.formattedDuration)
                                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                                            .foregroundStyle(AppTheme.primary)
                                            .frame(width: 55, alignment: .trailing)

                                        if lap.avgHeartRate > 0 {
                                            Text("\(lap.avgHeartRate) bpm")
                                                .font(AppTheme.captionFont)
                                                .foregroundStyle(Color(red: 1.0, green: 0.231, blue: 0.361))
                                                .frame(width: 60, alignment: .trailing)
                                        }
                                    }
                                    .padding(.vertical, 6)
                                    .padding(.horizontal, 10)
                                    .background(AppTheme.field.opacity(0.6))
                                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.tag))
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(AppTheme.Spacing.md)
                        .background(AppTheme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.card))
                    }

                    // Share to Community Feed Button
                    Button(action: {
                        shareRunToFeed(run: run)
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "person.3.sequence.fill")
                            Text("Post Run to Community Feed")
                        }
                        .font(AppTheme.headlineFont)
                        .foregroundStyle(AppTheme.onPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(AppTheme.primary)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.card))
                    }

                    if !run.notes.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("RUN NOTES")
                                .font(AppTheme.eyebrowFont)
                                .tracking(1.5)
                                .foregroundStyle(AppTheme.textSecondary)

                            Text(run.notes)
                                .font(AppTheme.bodyFont)
                                .foregroundStyle(AppTheme.text)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(AppTheme.Spacing.md)
                        .background(AppTheme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.card))
                    }
                }
                .padding(AppTheme.Spacing.screenMargin)
            }
            .background(AppTheme.ground.ignoresSafeArea())
            .navigationTitle("Run Summary")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(AppTheme.primary)
                }
            }
        }
    }

    private func metricBox(label: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(AppTheme.eyebrowFont)
                .foregroundStyle(AppTheme.textMuted)
            Text(value)
                .font(AppTheme.subheadlineFont)
                .bold()
                .foregroundStyle(AppTheme.primary)
        }
        .frame(maxWidth: .infinity)
    }

    private func generateShareText(run: RunEntry) -> String {
        var text = "🏃‍♂️ \(run.title) on Solxce\n"
        text += "📍 Distance: \(String(format: "%.2f", run.distanceMiles)) miles\n"
        text += "⏱ Time: \(run.formattedDuration) (\(run.formattedPace))\n"
        text += "🔥 Calories: \(run.caloriesBurned) kcal\n"
        if run.averageHeartRateBpm > 0 {
            text += "❤️ Avg Heart Rate: \(run.averageHeartRateBpm) bpm\n"
        }
        let laps = run.decodedLaps
        if !laps.isEmpty {
            text += "\n📊 Lap Splits:\n"
            for lap in laps {
                text += "• Lap \(lap.lapNumber): \(lap.formattedDuration) (\(String(format: "%.2f", lap.distanceMiles)) mi, \(lap.avgHeartRate > 0 ? "\(lap.avgHeartRate) bpm" : lap.formattedPace))\n"
            }
        }
        text += "\nTracked with Solxce Athletic Intelligence"
        return text
    }

    private func shareRunToFeed(run: RunEntry) {
        let laps = run.decodedLaps
        var lapSummary = ""
        if !laps.isEmpty {
            let fastestLap = laps.min(by: { $0.durationSeconds < $1.durationSeconds })
            if let best = fastestLap {
                lapSummary = " · Best Lap: \(best.formattedDuration)"
            }
        }
        let hrText = run.averageHeartRateBpm > 0 ? " · \(run.averageHeartRateBpm) bpm avg HR" : ""

        let newPost = AthletePost(
            authorName: "Alex Rivera",
            authorHandle: "alex_solxce",
            athleteType: .runner,
            timeAgo: "Just now",
            workoutTag: "OUTDOOR RUN",
            workoutStats: "\(String(format: "%.2f", run.distanceMiles)) mi · \(run.formattedDuration) · \(run.formattedPace)\(hrText)\(lapSummary)",
            caption: run.notes.isEmpty ? "Pushed the pace on today's run. Distance, lap splits, and heart rate logged into Solxce." : run.notes,
            imageName: "figure.run",
            mediaType: .photo,
            mediaItems: [
                PostMediaItem(
                    id: UUID().uuidString,
                    title: "\(String(format: "%.2f", run.distanceMiles)) mi Run",
                    iconName: "figure.run",
                    gradientHexes: ["#0B2B26", "#163E36"],
                    subtitle: "\(run.formattedDuration) · \(run.formattedPace)\(hrText)",
                    isVideo: false
                )
            ],
            mediaIconName: "figure.run",
            gradientColors: [Color(red: 0.05, green: 0.18, blue: 0.15), Color(red: 0.1, green: 0.28, blue: 0.22)],
            audioTrack: AudioTrack.library[1],
            textOverlay: "\(String(format: "%.2f", run.distanceMiles)) MILES · \(run.formattedPace)",
            likesCount: 1,
            isLiked: true,
            comments: []
        )

        FeedPostStore.shared.addPost(newPost)
        dismiss()
    }
}
