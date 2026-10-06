// Models/HealthKitService.swift
import Foundation
import HealthKit
import Combine

/// Service managing HealthKit authorization and biometric queries
/// for Apple Watch workout metrics (Heart Rate, Active Calories, Steps, Resting HR).
@MainActor
final class HealthKitService: ObservableObject {
    static let shared = HealthKitService()
    
    let healthStore = HKHealthStore()
    
    @Published var isAvailable: Bool = HKHealthStore.isHealthDataAvailable()
    @Published var isAuthorized: Bool = false
    @Published var currentHeartRateBpm: Double = 0.0
    @Published var todayActiveCalories: Double = 0.0
    @Published var todaySteps: Int = 0
    @Published var todayDistanceMiles: Double = 0.0
    @Published var restingHeartRateBpm: Double = 62.0
    @Published var heartRateZone: Int = 2
    @Published var lastSyncTimestamp: Date? = nil
    @Published var isSyncing: Bool = false
    @Published var authorizationError: String? = nil
    
    // Heart rate query anchor
    private var heartRateQuery: HKAnchoredObjectQuery?
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        if HKHealthStore.isHealthDataAvailable() {
            checkExistingAuthorization()
        }
    }
    
    // MARK: - Authorization
    func requestAuthorization() async -> Bool {
        guard HKHealthStore.isHealthDataAvailable() else {
            authorizationError = "HealthKit is not supported on this device."
            return false
        }
        
        guard let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate),
              let activeEnergyType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned),
              let stepCountType = HKObjectType.quantityType(forIdentifier: .stepCount),
              let distanceType = HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning),
              let restingHeartRateType = HKObjectType.quantityType(forIdentifier: .restingHeartRate) else {
            return false
        }
        
        let typesToRead: Set<HKObjectType> = [
            heartRateType,
            activeEnergyType,
            stepCountType,
            distanceType,
            restingHeartRateType,
            HKObjectType.workoutType()
        ]
        
        let typesToWrite: Set<HKSampleType> = [
            activeEnergyType,
            distanceType,
            HKObjectType.workoutType()
        ]
        
        do {
            try await healthStore.requestAuthorization(toShare: typesToWrite, read: typesToRead)
            self.isAuthorized = true
            self.authorizationError = nil
            await refreshAllMetrics()
            startHeartRateLiveStream()
            return true
        } catch {
            self.authorizationError = error.localizedDescription
            return false
        }
    }
    
    private func checkExistingAuthorization() {
        guard let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate) else { return }
        let status = healthStore.authorizationStatus(for: heartRateType)
        if status == .sharingAuthorized {
            self.isAuthorized = true
            Task {
                await refreshAllMetrics()
            }
        }
    }
    
    // MARK: - Metric Queries
    func refreshAllMetrics() async {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        isSyncing = true
        
        await fetchTodaySteps()
        await fetchTodayCalories()
        await fetchTodayDistance()
        await fetchLatestHeartRate()
        await fetchRestingHeartRate()
        
        self.lastSyncTimestamp = Date()
        self.isSyncing = false
    }
    
    private func fetchTodaySteps() async {
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return }
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum) { [weak self] _, statistics, _ in
                let steps = statistics?.sumQuantity().map { Int($0.doubleValue(for: HKUnit.count())) } ?? 0
                Task { @MainActor [weak self] in
                    if steps > 0 {
                        self?.todaySteps = steps
                    }
                    continuation.resume()
                }
            }
            healthStore.execute(query)
        }
    }
    
    private func fetchTodayCalories() async {
        guard let calorieType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else { return }
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: calorieType, quantitySamplePredicate: predicate, options: .cumulativeSum) { [weak self] _, statistics, _ in
                let calories = statistics?.sumQuantity().map { $0.doubleValue(for: HKUnit.kilocalorie()) } ?? 0.0
                Task { @MainActor [weak self] in
                    if calories > 0 {
                        self?.todayActiveCalories = calories
                    }
                    continuation.resume()
                }
            }
            healthStore.execute(query)
        }
    }
    
    private func fetchTodayDistance() async {
        guard let distanceType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning) else { return }
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: distanceType, quantitySamplePredicate: predicate, options: .cumulativeSum) { [weak self] _, statistics, _ in
                let miles = statistics?.sumQuantity().map { $0.doubleValue(for: HKUnit.mile()) } ?? 0.0
                Task { @MainActor [weak self] in
                    if miles > 0 {
                        self?.todayDistanceMiles = miles
                    }
                    continuation.resume()
                }
            }
            healthStore.execute(query)
        }
    }
    
    private func fetchLatestHeartRate() async {
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else { return }
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: heartRateType, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { [weak self] _, samples, _ in
                let sample = samples?.first as? HKQuantitySample
                let bpm = sample?.quantity.doubleValue(for: HKUnit(from: "count/min")) ?? 0.0
                Task { @MainActor [weak self] in
                    if bpm > 0 {
                        self?.currentHeartRateBpm = bpm
                        self?.updateHeartRateZone(bpm: bpm)
                    }
                    continuation.resume()
                }
            }
            healthStore.execute(query)
        }
    }
    
    private func fetchRestingHeartRate() async {
        guard let restingType = HKQuantityType.quantityType(forIdentifier: .restingHeartRate) else { return }
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: restingType, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { [weak self] _, samples, _ in
                let sample = samples?.first as? HKQuantitySample
                let bpm = sample?.quantity.doubleValue(for: HKUnit(from: "count/min")) ?? 0.0
                Task { @MainActor [weak self] in
                    if bpm > 0 {
                        self?.restingHeartRateBpm = bpm
                    }
                    continuation.resume()
                }
            }
            healthStore.execute(query)
        }
    }
    
    // MARK: - Live Stream & Zones
    func startHeartRateLiveStream() {
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else { return }
        let predicate = HKQuery.predicateForSamples(withStart: Date().addingTimeInterval(-60), end: nil, options: .strictStartDate)
        
        let query = HKAnchoredObjectQuery(type: heartRateType, predicate: predicate, anchor: nil, limit: HKObjectQueryNoLimit) { [weak self] _, samples, _, _, _ in
            if let samples = samples as? [HKQuantitySample], let lastSample = samples.last {
                let bpm = lastSample.quantity.doubleValue(for: HKUnit(from: "count/min"))
                Task { @MainActor [weak self] in
                    self?.currentHeartRateBpm = bpm
                    self?.updateHeartRateZone(bpm: bpm)
                }
            }
        }
        
        query.updateHandler = { [weak self] _, samples, _, _, _ in
            if let samples = samples as? [HKQuantitySample], let lastSample = samples.last {
                let bpm = lastSample.quantity.doubleValue(for: HKUnit(from: "count/min"))
                Task { @MainActor [weak self] in
                    self?.currentHeartRateBpm = bpm
                    self?.updateHeartRateZone(bpm: bpm)
                }
            }
        }
        
        self.heartRateQuery = query
        healthStore.execute(query)
    }
    
    func stopHeartRateLiveStream() {
        if let query = heartRateQuery {
            healthStore.stop(query)
            self.heartRateQuery = nil
        }
    }
    
    private func updateHeartRateZone(bpm: Double) {
        // Approximate standard 5-zone model for max HR 190
        if bpm < 114 {
            heartRateZone = 1 // Recovery (<60%)
        } else if bpm < 133 {
            heartRateZone = 2 // Aerobic Endurance (60-70%)
        } else if bpm < 152 {
            heartRateZone = 3 // Tempo / Aerobic Power (70-80%)
        } else if bpm < 171 {
            heartRateZone = 4 // Threshold (80-90%)
        } else {
            heartRateZone = 5 // Anaerobic / Max (>90%)
        }
    }
    
    // MARK: - Save Workout to Apple Health
    func saveCompletedWorkout(title: String, durationSeconds: Int, caloriesBurned: Double, distanceMiles: Double = 0.0) async -> Bool {
        guard isAuthorized else { return false }
        
        let startDate = Date().addingTimeInterval(-Double(durationSeconds))
        let endDate = Date()
        
        let workoutConfiguration = HKWorkoutConfiguration()
        workoutConfiguration.activityType = distanceMiles > 0 ? .running : .traditionalStrengthTraining
        workoutConfiguration.locationType = distanceMiles > 0 ? .outdoor : .indoor
        
        let workoutBuilder = HKWorkoutBuilder(healthStore: healthStore, configuration: workoutConfiguration, device: .local())
        
        do {
            try await workoutBuilder.beginCollection(at: startDate)
            
            var samples: [HKSample] = []
            
            if caloriesBurned > 0, let calType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) {
                let calQuantity = HKQuantity(unit: .kilocalorie(), doubleValue: caloriesBurned)
                let calSample = HKCumulativeQuantitySample(type: calType, quantity: calQuantity, start: startDate, end: endDate)
                samples.append(calSample)
            }
            
            if distanceMiles > 0, let distType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning) {
                let distQuantity = HKQuantity(unit: .mile(), doubleValue: distanceMiles)
                let distSample = HKCumulativeQuantitySample(type: distType, quantity: distQuantity, start: startDate, end: endDate)
                samples.append(distSample)
            }
            
            if !samples.isEmpty {
                try await workoutBuilder.addSamples(samples)
            }
            
            try await workoutBuilder.endCollection(at: endDate)
            _ = try await workoutBuilder.finishWorkout()
            return true
        } catch {
            return false
        }
    }
}
