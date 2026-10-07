// Models/RunLiveActivityManager.swift
import Foundation
import SwiftUI
import Combine

/// Pure Swift run activity manager without sensitive Live Activity hardware/entitlement APIs.
@MainActor
final class RunLiveActivityManager: ObservableObject {
    static let shared = RunLiveActivityManager()
    
    @Published var isActivityRunning: Bool = false
    @Published var currentDistance: Double = 0.0
    @Published var currentPace: String = "--:--"
    @Published var currentDuration: Int = 0
    
    init() {}
    
    func startActivity(distance: Double, pace: String, duration: Int) {
        self.isActivityRunning = true
        self.currentDistance = distance
        self.currentPace = pace
        self.currentDuration = duration
    }
    
    func updateActivity(distance: Double, pace: String, duration: Int) {
        self.currentDistance = distance
        self.currentPace = pace
        self.currentDuration = duration
    }
    
    func endActivity() {
        self.isActivityRunning = false
    }
}
