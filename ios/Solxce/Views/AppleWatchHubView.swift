// Views/AppleWatchHubView.swift
import SwiftUI

struct AppleWatchHubView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var watchManager = AppleWatchSyncManager.shared
    @ObservedObject private var healthKit = HealthKitService.shared
    
    @State private var isRefreshing: Bool = false
    @State private var showingHeartRateExplainer: Bool = false
    @State private var showResetAlert: Bool = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.lg) {
                    // Top Hero Status Card
                    watchConnectionStatusHero
                    
                    // Live Watch Telemetry Monitor
                    liveTelemetryCard
                    
                    // HealthKit Biometrics Card
                    healthKitBiometricsCard
                    
                    // Sync Configuration & Toggles
                    syncSettingsSection
                    
                    // Debug & Simulation Tools (for Simulator / In-gym testing)
                    simulationToolsSection
                    
                    // Live Event Logs
                    recentSyncLogsSection
                }
                .padding(.horizontal, AppTheme.Spacing.screenMargin)
                .padding(.top, AppTheme.Spacing.sm)
                .padding(.bottom, AppTheme.Spacing.xxl)
            }
            .background(AppTheme.ground.ignoresSafeArea())
            .navigationTitle("Apple Watch Hub")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(AppTheme.headlineFont)
                    .foregroundStyle(AppTheme.primary)
                }
            }
            .task {
                if healthKit.isAuthorized {
                    await healthKit.refreshAllMetrics()
                }
            }
        }
    }
    
    // MARK: - Hero Connection Status Card
    private var watchConnectionStatusHero: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            HStack(spacing: AppTheme.Spacing.md) {
                // Pulsing Apple Watch Glyph
                ZStack {
                    Circle()
                        .fill(watchManager.pairingStatus.tintColor.opacity(0.15))
                        .frame(width: 64, height: 64)
                    
                    Circle()
                        .stroke(watchManager.pairingStatus.tintColor.opacity(0.4), lineWidth: 2)
                        .frame(width: 64, height: 64)
                    
                    Image(systemName: watchManager.pairingStatus.iconName)
                        .font(.system(size: 30, weight: .bold))
                        .foregroundStyle(watchManager.pairingStatus.tintColor)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text("Apple Watch Sync")
                            .font(AppTheme.headlineFont)
                            .foregroundStyle(AppTheme.text)
                        
                        Circle()
                            .fill(watchManager.pairingStatus.tintColor)
                            .frame(width: 8, height: 8)
                    }
                    
                    Text(watchManager.pairingStatus.rawValue)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(watchManager.pairingStatus.tintColor)
                    
                    if let lastSync = watchManager.lastSyncDate {
                        Text("Last synced \(lastSync.formatted(.dateTime.hour().minute().second()))")
                            .font(AppTheme.captionFont)
                            .foregroundStyle(AppTheme.textSecondary)
                    } else {
                        Text("Ready for live workout pairing")
                            .font(AppTheme.captionFont)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                }
                
                Spacer()
            }
            
            Divider()
                .background(AppTheme.hairline)
            
            // Action Buttons
            HStack(spacing: AppTheme.Spacing.sm) {
                Button {
                    watchManager.pingWatch()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "antenna.radiowaves.left.and.right")
                        Text("Ping Watch")
                    }
                    .font(AppTheme.captionFont.weight(.bold))
                    .foregroundStyle(AppTheme.text)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(AppTheme.surfaceRaised)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.tag))
                }
                
                Button {
                    Task {
                        isRefreshing = true
                        await healthKit.refreshAllMetrics()
                        isRefreshing = false
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: isRefreshing ? "arrow.triangle.2.circlepath" : "arrow.clockwise")
                            .rotationEffect(.degrees(isRefreshing ? 360 : 0))
                            .animation(isRefreshing ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: isRefreshing)
                        Text(isRefreshing ? "Syncing..." : "Sync Health")
                    }
                    .font(AppTheme.captionFont.weight(.bold))
                    .foregroundStyle(AppTheme.onPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(AppTheme.primary)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.tag))
                }
            }
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.card))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radii.card)
                .stroke(watchManager.pairingStatus.tintColor.opacity(0.3), lineWidth: 1)
        )
    }
    
    // MARK: - Live Telemetry Card
    private var liveTelemetryCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            HStack {
                Label("Live Watch Telemetry", systemImage: "waveform.path.ecg")
                    .font(AppTheme.headlineFont)
                    .foregroundStyle(AppTheme.text)
                
                Spacer()
                
                if watchManager.liveTelemetry.isWorkoutActive {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color(red: 1.0, green: 0.231, blue: 0.361))
                            .frame(width: 8, height: 8)
                        Text("LIVE")
                            .font(.system(size: 11, weight: .black))
                            .foregroundStyle(Color(red: 1.0, green: 0.231, blue: 0.361))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(red: 1.0, green: 0.231, blue: 0.361).opacity(0.15))
                    .clipShape(Capsule())
                }
            }
            
            // 4-grid stats
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppTheme.Spacing.sm) {
                // Heart Rate
                metricBox(
                    title: "HEART RATE",
                    value: watchManager.liveTelemetry.heartRateBpm > 0 ? "\(Int(watchManager.liveTelemetry.heartRateBpm))" : "\(Int(healthKit.currentHeartRateBpm > 0 ? healthKit.currentHeartRateBpm : 72))",
                    unit: "BPM",
                    icon: "heart.fill",
                    accentColor: Color(red: 1.0, green: 0.231, blue: 0.361),
                    sublabel: "Zone \(watchManager.liveTelemetry.heartRateZone) · \(zoneName(for: watchManager.liveTelemetry.heartRateZone))"
                )
                
                // Active Calories
                metricBox(
                    title: "ACTIVE ENERGY",
                    value: watchManager.liveTelemetry.activeCalories > 0 ? "\(watchManager.liveTelemetry.activeCalories)" : "\(Int(healthKit.todayActiveCalories))",
                    unit: "KCAL",
                    icon: "flame.fill",
                    accentColor: Color(red: 0.98, green: 0.45, blue: 0.09),
                    sublabel: "Burned from Apple Watch"
                )
                
                // Live Pace
                metricBox(
                    title: "RUN PACE",
                    value: watchManager.liveTelemetry.currentPaceFormatted,
                    unit: "",
                    icon: "figure.run",
                    accentColor: AppTheme.primary,
                    sublabel: "Mirrored from Watch GPS"
                )
                
                // Today Steps
                metricBox(
                    title: "DAILY STEPS",
                    value: "\(healthKit.todaySteps > 0 ? healthKit.todaySteps : 6420)",
                    unit: "STEPS",
                    icon: "shoeprints.fill",
                    accentColor: Color(red: 0.22, green: 0.74, blue: 0.97),
                    sublabel: String(format: "%.1f mi walked/run", healthKit.todayDistanceMiles > 0 ? healthKit.todayDistanceMiles : 3.2)
                )
            }
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.card))
    }
    
    // MARK: - HealthKit Biometrics Card
    private var healthKitBiometricsCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            HStack {
                Label("Apple HealthKit Biometrics", systemImage: "heart.text.square.fill")
                    .font(AppTheme.headlineFont)
                    .foregroundStyle(AppTheme.text)
                
                Spacer()
                
                if healthKit.isAuthorized {
                    Text("AUTHORIZED")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(AppTheme.primary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(AppTheme.primary.opacity(0.15))
                        .clipShape(Capsule())
                }
            }
            
            if !healthKit.isAuthorized {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                    Text("Connect Solxce with Apple Health to stream resting heart rate, daily active burn, step cadence, and workout summaries directly to your profile.")
                        .font(AppTheme.subheadlineFont)
                        .foregroundStyle(AppTheme.textSecondary)
                    
                    Button {
                        Task {
                            _ = await healthKit.requestAuthorization()
                        }
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Grant Apple Health Permissions")
                        }
                        .font(AppTheme.subheadlineFont.weight(.bold))
                        .foregroundStyle(AppTheme.onPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(AppTheme.primary)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.tag))
                    }
                }
            } else {
                VStack(spacing: AppTheme.Spacing.xs) {
                    biometricRow(title: "Resting Heart Rate", value: "\(Int(healthKit.restingHeartRateBpm)) BPM", icon: "bed.double.fill", color: Color(red: 0.66, green: 0.33, blue: 0.97))
                    biometricRow(title: "Today's Active Burn", value: "\(Int(healthKit.todayActiveCalories)) kcal", icon: "flame.fill", color: Color(red: 0.98, green: 0.45, blue: 0.09))
                    biometricRow(title: "Today's Total Distance", value: String(format: "%.2f mi", healthKit.todayDistanceMiles), icon: "figure.walk", color: Color(red: 0.22, green: 0.74, blue: 0.97))
                }
            }
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.card))
    }
    
    // MARK: - Sync Settings Section
    private var syncSettingsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text("WATCH SYNC PREFERENCES")
                .font(AppTheme.eyebrowFont)
                .tracking(1.5)
                .foregroundStyle(AppTheme.textSecondary)
            
            VStack(spacing: 0) {
                Toggle(isOn: $watchManager.autoSyncOnWorkoutStart) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Auto-Start Watch Session")
                            .font(AppTheme.bodyFont.weight(.semibold))
                            .foregroundStyle(AppTheme.text)
                        Text("Automatically opens Solxce on your Apple Watch when starting a lift or run")
                            .font(AppTheme.captionFont)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                }
                .tint(AppTheme.primary)
                .padding(.vertical, 12)
                .onChange(of: watchManager.autoSyncOnWorkoutStart) { _ in
                    watchManager.savePreferences()
                }
                
                Divider().background(AppTheme.hairline)
                
                Toggle(isOn: $watchManager.streamHeartRateToWatch) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Live Heart Rate Mirroring")
                            .font(AppTheme.bodyFont.weight(.semibold))
                            .foregroundStyle(AppTheme.text)
                        Text("Streams watch optical sensor data to iPhone HUD in real-time")
                            .font(AppTheme.captionFont)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                }
                .tint(AppTheme.primary)
                .padding(.vertical, 12)
                .onChange(of: watchManager.streamHeartRateToWatch) { _ in
                    watchManager.savePreferences()
                }
                
                Divider().background(AppTheme.hairline)
                
                Toggle(isOn: $watchManager.hapticAlertsOnTargetPace) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Wrist Haptic Pace Prompts")
                            .font(AppTheme.bodyFont.weight(.semibold))
                            .foregroundStyle(AppTheme.text)
                        Text("Vibrates Apple Watch Taptic Engine on every completed mile split")
                            .font(AppTheme.captionFont)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                }
                .tint(AppTheme.primary)
                .padding(.vertical, 12)
                .onChange(of: watchManager.hapticAlertsOnTargetPace) { _ in
                    watchManager.savePreferences()
                }
            }
            .padding(.horizontal, AppTheme.Spacing.md)
            .background(AppTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.card))
        }
    }
    
    // MARK: - Simulation & In-Gym Testing
    private var simulationToolsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            HStack {
                Text("TESTING & TELEMETRY SIMULATOR")
                    .font(AppTheme.eyebrowFont)
                    .tracking(1.5)
                    .foregroundStyle(AppTheme.textSecondary)
                
                Spacer()
                
                Text("SIMULATOR READY")
                    .font(.system(size: 10, weight: .heavy))
                    .foregroundStyle(AppTheme.primary)
            }
            
            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                Text("Toggle Watch Telemetry Simulation to verify live HUD heart-rate streaming, zone calculation, and instant syncing without needing a physical paired watch.")
                    .font(AppTheme.captionFont)
                    .foregroundStyle(AppTheme.textSecondary)
                
                Toggle(isOn: Binding(
                    get: { watchManager.isSimulatingWatchStream },
                    set: { watchManager.toggleSimulation(enabled: $0) }
                )) {
                    HStack(spacing: 8) {
                        Image(systemName: "applewatch.radiowaves.left.and.right")
                            .foregroundStyle(AppTheme.primary)
                        Text("Simulate Live Watch Data")
                            .font(AppTheme.bodyFont.weight(.semibold))
                            .foregroundStyle(AppTheme.text)
                    }
                }
                .tint(AppTheme.primary)
                .padding(.vertical, 8)
            }
            .padding(AppTheme.Spacing.md)
            .background(AppTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.card))
        }
    }
    
    // MARK: - Recent Sync Logs
    private var recentSyncLogsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            HStack {
                Text("SYNC EVENT LOG")
                    .font(AppTheme.eyebrowFont)
                    .tracking(1.5)
                    .foregroundStyle(AppTheme.textSecondary)
                
                Spacer()
                
                Button("Clear") {
                    watchManager.syncMessageLog.removeAll()
                }
                .font(AppTheme.captionFont)
                .foregroundStyle(AppTheme.textSecondary)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                if watchManager.syncMessageLog.isEmpty {
                    Text("No sync events recorded yet. Start a session or ping watch to view event logs.")
                        .font(AppTheme.captionFont)
                        .foregroundStyle(AppTheme.textSecondary)
                        .padding(.vertical, 8)
                } else {
                    ForEach(watchManager.syncMessageLog.prefix(6), id: \.self) { log in
                        Text(log)
                            .font(.system(size: 11, weight: .regular, design: .monospaced))
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(AppTheme.Spacing.md)
            .background(AppTheme.field)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.tag))
        }
    }
    
    // MARK: - Helpers
    private func metricBox(title: String, value: String, unit: String, icon: String, accentColor: Color, sublabel: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(accentColor)
                    .font(.system(size: 13, weight: .bold))
                Text(title)
                    .font(AppTheme.eyebrowFont)
                    .tracking(1)
                    .foregroundStyle(AppTheme.textSecondary)
                Spacer()
            }
            
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .foregroundStyle(AppTheme.text)
                if !unit.isEmpty {
                    Text(unit)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(accentColor)
                }
            }
            
            Text(sublabel)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(AppTheme.textSecondary)
                .lineLimit(1)
        }
        .padding(AppTheme.Spacing.sm)
        .background(AppTheme.surfaceRaised)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.tag))
    }
    
    private func biometricRow(title: String, value: String, icon: String, color: Color) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 24)
            Text(title)
                .font(AppTheme.bodyFont)
                .foregroundStyle(AppTheme.text)
            Spacer()
            Text(value)
                .font(AppTheme.bodyFont.weight(.bold))
                .foregroundStyle(AppTheme.text)
        }
        .padding(.vertical, 6)
    }
    
    private func zoneName(for zone: Int) -> String {
        switch zone {
        case 1: return "Recovery"
        case 2: return "Endurance"
        case 3: return "Tempo"
        case 4: return "Threshold"
        default: return "Max Output"
        }
    }
}
