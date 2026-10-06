// Models/NotificationManager.swift
import Foundation
import UserNotifications
import SwiftUI
import Combine

/// Centralized notification manager handling permissions, in-app banner delivery,
/// and local notification scheduling for Fasting, Workouts, Hydration, and Socials.
@MainActor
public final class NotificationManager: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    public static let shared = NotificationManager()

    // MARK: - Published State
    @Published public var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @Published public var isPermissionGranted: Bool = false
    
    // User Notification Preferences (persisted in UserDefaults)
    @AppStorage("notif_fasting_timer_enabled") public var fastingNotificationsEnabled: Bool = true
    @AppStorage("notif_eating_window_warning_enabled") public var eatingWindowWarningEnabled: Bool = true
    @AppStorage("notif_workout_reminder_enabled") public var workoutReminderEnabled: Bool = true
    @AppStorage("notif_workout_reminder_hour") public var workoutReminderHour: Int = 8 // 8:00 AM
    @AppStorage("notif_workout_reminder_minute") public var workoutReminderMinute: Int = 0
    @AppStorage("notif_hydration_enabled") public var hydrationReminderEnabled: Bool = false
    @AppStorage("notif_hydration_interval_hours") public var hydrationIntervalHours: Int = 2
    @AppStorage("notif_social_messages_enabled") public var socialMessagesEnabled: Bool = true

    // Active in-app notification banner
    @Published public var activeInAppBanner: InAppNotificationBanner? = nil

    public struct InAppNotificationBanner: Identifiable {
        public let id = UUID()
        public let title: String
        public let body: String
        public let icon: String
        public let color: Color
    }

    override private init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
        checkAuthorization()
    }

    // MARK: - Permission Check & Request
    public func checkAuthorization() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            Task { @MainActor in
                self.authorizationStatus = settings.authorizationStatus
                self.isPermissionGranted = (settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional)
            }
        }
    }

    public func requestAuthorization(completion: ((Bool) -> Void)? = nil) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            Task { @MainActor in
                self.isPermissionGranted = granted
                self.checkAuthorization()
                if granted {
                    self.syncAllScheduledNotifications()
                }
                completion?(granted)
            }
        }
    }

    // MARK: - Fasting Notifications
    public func scheduleFastingCompletion(
        targetEndTime: Date,
        fastingHours: Int,
        eatingWindowEndTime: Date
    ) {
        guard isPermissionGranted, fastingNotificationsEnabled else { return }

        // Remove previous fasting notifications first
        cancelFastingNotifications()

        let center = UNUserNotificationCenter.current()

        // 1. Fast Completed / Eating Window Opens
        let fastEndContent = UNMutableNotificationContent()
        fastEndContent.title = "🎉 Fast Completed! Eating Window Open"
        fastEndContent.body = "You completed your \(fastingHours)-hour fast! Log your first meal in Solxce."
        fastEndContent.sound = .default
        fastEndContent.badge = 1
        fastEndContent.userInfo = ["type": "fasting_complete"]

        let secondsUntilEnd = targetEndTime.timeIntervalSinceNow
        if secondsUntilEnd > 0 {
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, secondsUntilEnd), repeats: false)
            let request = UNNotificationRequest(identifier: "solxce_fasting_complete", content: fastEndContent, trigger: trigger)
            center.add(request) { error in
                if let error = error {
                    print("Error scheduling fast complete: \(error.localizedDescription)")
                }
            }
        }

        // 2. Pre-warning: 30 minutes before eating window closes
        if eatingWindowWarningEnabled {
            let closeWarningContent = UNMutableNotificationContent()
            closeWarningContent.title = "⏳ Eating Window Closes in 30 Minutes"
            closeWarningContent.body = "Wrap up your final meal and hydration before your next fast begins."
            closeWarningContent.sound = .default
            closeWarningContent.userInfo = ["type": "fasting_window_warning"]

            let warningTime = eatingWindowEndTime.addingTimeInterval(-1800)
            let secondsUntilWarning = warningTime.timeIntervalSinceNow
            if secondsUntilWarning > 0 {
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, secondsUntilWarning), repeats: false)
                let request = UNNotificationRequest(identifier: "solxce_fasting_close_warning", content: closeWarningContent, trigger: trigger)
                center.add(request)
            }
        }

        // 3. Fasting Window Starts (Eating Window Ends)
        let fastStartContent = UNMutableNotificationContent()
        fastStartContent.title = "⚡ Fasting Window Has Started"
        fastStartContent.body = "Your eating window is now closed. Stay strong and keep hydrated with water or electrolytes!"
        fastStartContent.sound = .default
        fastStartContent.userInfo = ["type": "fasting_start"]

        let secondsUntilStart = eatingWindowEndTime.timeIntervalSinceNow
        if secondsUntilStart > 0 {
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, secondsUntilStart), repeats: false)
            let request = UNNotificationRequest(identifier: "solxce_fasting_start", content: fastStartContent, trigger: trigger)
            center.add(request)
        }
    }

    public func cancelFastingNotifications() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [
            "solxce_fasting_complete",
            "solxce_fasting_close_warning",
            "solxce_fasting_start"
        ])
    }

    // MARK: - Daily Workout Reminders
    public func scheduleWorkoutReminder() {
        guard isPermissionGranted, workoutReminderEnabled else {
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["solxce_daily_workout_reminder"])
            return
        }

        let content = UNMutableNotificationContent()
        content.title = "🔥 Time to Train"
        content.body = "Your daily workout awaits. Crush your sets and log your progress in Solxce!"
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = workoutReminderHour
        dateComponents.minute = workoutReminderMinute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "solxce_daily_workout_reminder", content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Hydration Reminders
    public func scheduleHydrationReminders() {
        guard isPermissionGranted, hydrationReminderEnabled else {
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["solxce_hydration_reminder"])
            return
        }

        let content = UNMutableNotificationContent()
        content.title = "💧 Stay Hydrated"
        content.body = "Drink a glass of water or electrolytes to maintain athletic endurance and recovery."
        content.sound = .default

        let interval = TimeInterval(max(1, hydrationIntervalHours) * 3600)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: true)
        let request = UNNotificationRequest(identifier: "solxce_hydration_reminder", content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Send Test Notification
    public func sendTestNotification(title: String = "⚡ Fast Completed!", body: String = "Your fasting timer has reached 100%. Great work!") {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.badge = 1

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)
        let request = UNNotificationRequest(identifier: "solxce_test_notification_\(UUID().uuidString)", content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { _ in
            Task { @MainActor in
                self.showInAppBanner(title: title, body: body, icon: "bell.badge.fill", color: Color.green)
            }
        }
    }

    public func showInAppBanner(title: String, body: String, icon: String = "bell.fill", color: Color = Color.green) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            self.activeInAppBanner = InAppNotificationBanner(title: title, body: body, icon: icon, color: color)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.5) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                if self.activeInAppBanner?.title == title {
                    self.activeInAppBanner = nil
                }
            }
        }
    }

    public func syncAllScheduledNotifications() {
        if workoutReminderEnabled {
            scheduleWorkoutReminder()
        }
        if hydrationReminderEnabled {
            scheduleHydrationReminders()
        }
    }

    // MARK: - UNUserNotificationCenterDelegate (Foreground notifications)
    nonisolated public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let title = notification.request.content.title
        let body = notification.request.content.body
        
        Task { @MainActor in
            NotificationManager.shared.showInAppBanner(
                title: title,
                body: body,
                icon: "bell.badge.fill",
                color: Color.green
            )
        }

        // Show banner, play sound, and update badge even while app is in foreground
        completionHandler([.banner, .sound, .badge, .list])
    }

    nonisolated public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        completionHandler()
    }
}
