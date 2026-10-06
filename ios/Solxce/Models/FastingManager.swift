// Models/FastingManager.swift
import SwiftUI
import UserNotifications
import Combine

enum FastingProtocol: String, CaseIterable, Identifiable {
    case sixteenEight = "16:8 (LeanGains)"
    case eighteenSix = "18:6 (Warrior)"
    case twentyFour = "20:4 (OMAD-lite)"
    case circadian = "14:10 (Circadian)"
    case custom = "Custom"

    var id: String { rawValue }

    var fastHours: Int {
        switch self {
        case .sixteenEight: return 16
        case .eighteenSix: return 18
        case .twentyFour: return 20
        case .circadian: return 14
        case .custom: return 16
        }
    }

    var eatHours: Int {
        24 - fastHours
    }

    var description: String {
        "\(fastHours)h Fast / \(eatHours)h Eat"
    }
}

enum FastingState: String {
    case fasting = "Fasting"
    case eating = "Eating Window"
    case idle = "Ready to Start"
}

@MainActor
final class FastingManager: ObservableObject {
    static let shared = FastingManager()

    @AppStorage("fasting_is_active") var isFastingActive: Bool = false
    @AppStorage("fasting_start_time") var startTimeInterval: Double = 0
    @AppStorage("fasting_target_hours") var targetFastHours: Int = 16
    @AppStorage("fasting_protocol_raw") var protocolRaw: String = FastingProtocol.sixteenEight.rawValue
    @AppStorage("fasting_notifications_enabled") var notificationsEnabled: Bool = true

    @Published var currentTime: Date = Date()
    @Published var notificationStatusMessage: String = ""

    private var timer: AnyCancellable?

    init() {
        // Run light timer tick for UI updates
        timer = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] newTime in
                self?.currentTime = newTime
            }
        
        // Request notification permission if needed
        checkNotificationStatus()
    }

    var selectedProtocol: FastingProtocol {
        get { FastingProtocol(rawValue: protocolRaw) ?? .sixteenEight }
        set {
            protocolRaw = newValue.rawValue
            targetFastHours = newValue.fastHours
        }
    }

    var fastStartTime: Date {
        Date(timeIntervalSince1970: startTimeInterval)
    }

    var fastTargetEndTime: Date {
        fastStartTime.addingTimeInterval(Double(targetFastHours) * 3600)
    }

    var eatingWindowEndTime: Date {
        fastTargetEndTime.addingTimeInterval(Double(24 - targetFastHours) * 3600)
    }

    var elapsedSeconds: TimeInterval {
        guard isFastingActive else { return 0 }
        return max(0, currentTime.timeIntervalSince(fastStartTime))
    }

    var totalTargetSeconds: TimeInterval {
        Double(targetFastHours) * 3600
    }

    var progress: Double {
        guard totalTargetSeconds > 0, isFastingActive else { return 0 }
        return min(1.0, elapsedSeconds / totalTargetSeconds)
    }

    var currentFastingState: FastingState {
        guard isFastingActive else { return .idle }
        if currentTime < fastTargetEndTime {
            return .fasting
        } else if currentTime < eatingWindowEndTime {
            return .eating
        } else {
            return .idle
        }
    }

    var isEatingWindowOpen: Bool {
        guard isFastingActive else { return true }
        return currentTime >= fastTargetEndTime && currentTime < eatingWindowEndTime
    }

    var remainingTimeFormatted: String {
        guard isFastingActive else { return "00:00:00" }
        if currentFastingState == .fasting {
            let remaining = max(0, fastTargetEndTime.timeIntervalSince(currentTime))
            return formatInterval(remaining)
        } else if currentFastingState == .eating {
            let remaining = max(0, eatingWindowEndTime.timeIntervalSince(currentTime))
            return formatInterval(remaining)
        } else {
            return "Complete"
        }
    }

    var elapsedTimeFormatted: String {
        formatInterval(elapsedSeconds)
    }

    private func formatInterval(_ interval: TimeInterval) -> String {
        let hrs = Int(interval) / 3600
        let mins = (Int(interval) % 3600) / 60
        let secs = Int(interval) % 60
        return String(format: "%02d:%02d:%02d", hrs, mins, secs)
    }

    func startFast(customHours: Int? = nil) {
        if let customHours = customHours {
            targetFastHours = customHours
        }
        startTimeInterval = Date().timeIntervalSince1970
        isFastingActive = true
        scheduleFastingNotifications()
    }

    func endFast() {
        isFastingActive = false
        startTimeInterval = 0
        cancelFastingNotifications()
    }

    // MARK: - Notifications
    func checkNotificationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                if settings.authorizationStatus == .authorized {
                    self.notificationStatusMessage = "Notifications Active"
                } else {
                    self.notificationStatusMessage = "Enable for Eating Alerts"
                }
            }
        }
    }

    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            DispatchQueue.main.async {
                self.notificationsEnabled = granted
                if granted {
                    self.notificationStatusMessage = "Notifications Active"
                    if self.isFastingActive {
                        self.scheduleFastingNotifications()
                    }
                }
            }
        }
    }

    func scheduleFastingNotifications() {
        guard notificationsEnabled, isFastingActive else { return }

        cancelFastingNotifications()

        let center = UNUserNotificationCenter.current()

        // 1. Notification: Eating Window Opens
        let eatOpenContent = UNMutableNotificationContent()
        eatOpenContent.title = "🍽️ Eating Window is OPEN!"
        eatOpenContent.body = "Great job! You completed your \(targetFastHours)-hour fast. You can now break your fast and log your meal in Solxce."
        eatOpenContent.sound = .default

        let eatOpenTriggerDate = fastTargetEndTime
        let timeUntilEatOpen = max(5, eatOpenTriggerDate.timeIntervalSinceNow)
        let eatOpenTrigger = UNTimeIntervalNotificationTrigger(timeInterval: timeUntilEatOpen, repeats: false)
        let eatOpenRequest = UNNotificationRequest(identifier: "solxce_eat_window_open", content: eatOpenContent, trigger: eatOpenTrigger)

        center.add(eatOpenRequest)

        // 2. Notification: Eating Window Closing in 30 Mins
        let closeSoonContent = UNMutableNotificationContent()
        closeSoonContent.title = "⏳ Eating Window Closes in 30 Mins"
        closeSoonContent.body = "Finish your hydration & nutrition goals before your new fast starts."
        closeSoonContent.sound = .default

        let closeSoonDate = eatingWindowEndTime.addingTimeInterval(-1800)
        let timeUntilCloseSoon = max(10, closeSoonDate.timeIntervalSinceNow)
        if timeUntilCloseSoon > 0 {
            let closeSoonTrigger = UNTimeIntervalNotificationTrigger(timeInterval: timeUntilCloseSoon, repeats: false)
            let closeSoonRequest = UNNotificationRequest(identifier: "solxce_eat_window_warning", content: closeSoonContent, trigger: closeSoonTrigger)
            center.add(closeSoonRequest)
        }

        // 3. Notification: Fast Starts Now
        let fastStartContent = UNMutableNotificationContent()
        fastStartContent.title = "⚡ Fasting Window Started"
        fastStartContent.body = "Your eating window has closed. Stay hydrated with water, black coffee, or electrolytes!"
        fastStartContent.sound = .default

        let timeUntilFastStart = max(15, eatingWindowEndTime.timeIntervalSinceNow)
        let fastStartTrigger = UNTimeIntervalNotificationTrigger(timeInterval: timeUntilFastStart, repeats: false)
        let fastStartRequest = UNNotificationRequest(identifier: "solxce_fast_window_start", content: fastStartContent, trigger: fastStartTrigger)
        center.add(fastStartRequest)
    }

    func cancelFastingNotifications() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [
            "solxce_eat_window_open",
            "solxce_eat_window_warning",
            "solxce_fast_window_start"
        ])
    }
}
