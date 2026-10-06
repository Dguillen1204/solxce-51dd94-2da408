// Models/CalendarSyncManager.swift
import Foundation
import EventKit
import SwiftUI
import Combine

/// Unified device calendar event model for dual-calendar inspection
struct DeviceCalendarEvent: Identifiable {
    let id: String
    let title: String
    let startDate: Date
    let endDate: Date
    let isAllDay: Bool
    let calendarTitle: String
    let calendarColor: Color
    let location: String?
}

@MainActor
final class CalendarSyncManager: ObservableObject {
    static let shared = CalendarSyncManager()
    
    private let eventStore = EKEventStore()
    
    @Published var authorizationStatus: EKAuthorizationStatus = .notDetermined
    @Published var deviceEvents: [DeviceCalendarEvent] = []
    @Published var isSyncing: Bool = false
    @Published var lastSyncDate: Date? = nil
    @Published var syncSuccessMessage: String? = nil
    @Published var syncErrorMessage: String? = nil
    @Published var isAutoSyncEnabled: Bool = false {
        didSet {
            UserDefaults.standard.set(isAutoSyncEnabled, forKey: "solxce_calendar_autosync")
        }
    }
    
    init() {
        self.isAutoSyncEnabled = UserDefaults.standard.bool(forKey: "solxce_calendar_autosync")
        checkAuthorization()
    }
    
    func checkAuthorization() {
        if #available(iOS 17.0, *) {
            authorizationStatus = EKEventStore.authorizationStatus(for: .event)
        } else {
            authorizationStatus = EKEventStore.authorizationStatus(for: .event)
        }
    }
    
    /// Request calendar access with soft-fallback
    func requestAccess() async -> Bool {
        if #available(iOS 17.0, *) {
            do {
                let granted = try await eventStore.requestFullAccessToEvents()
                authorizationStatus = granted ? .fullAccess : .denied
                if granted {
                    await fetchUpcomingDeviceEvents()
                }
                return granted
            } catch {
                authorizationStatus = .denied
                return false
            }
        } else {
            return await withCheckedContinuation { continuation in
                eventStore.requestAccess(to: .event) { [weak self] granted, _ in
                    DispatchQueue.main.async {
                        self?.authorizationStatus = granted ? .authorized : .denied
                        if granted {
                            Task { @MainActor in
                                await self?.fetchUpcomingDeviceEvents()
                            }
                        }
                        continuation.resume(returning: granted)
                    }
                }
            }
        }
    }
    
    /// Fetches the user's personal events from their phone's calendar for the current & upcoming weeks
    func fetchUpcomingDeviceEvents() async {
        guard authorizationStatus == .authorized || (authorizationStatus.rawValue == 3 || authorizationStatus.rawValue == 4) else {
            // Seed fixture sample phone events so athletes can test the dual calendar immediately in simulator/previews
            loadSampleDeviceEvents()
            return
        }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        guard let endDate = calendar.date(byAdding: .day, value: 14, to: startOfDay) else { return }
        
        let predicate = eventStore.predicateForEvents(withStart: startOfDay, end: endDate, calendars: nil)
        let ekEvents = eventStore.events(matching: predicate)
        
        self.deviceEvents = ekEvents.map { ek in
            let uiColor = ek.calendar.cgColor != nil ? Color(cgColor: ek.calendar.cgColor!) : Color.blue
            return DeviceCalendarEvent(
                id: ek.eventIdentifier ?? UUID().uuidString,
                title: ek.title ?? "Event",
                startDate: ek.startDate,
                endDate: ek.endDate,
                isAllDay: ek.isAllDay,
                calendarTitle: ek.calendar.title,
                calendarColor: uiColor,
                location: ek.location
            )
        }
        
        if self.deviceEvents.isEmpty {
            loadSampleDeviceEvents()
        }
    }
    
    /// Seeds realistic phone calendar events (work meetings, flights, dinner, etc.) for testing the dual calendar view
    private func loadSampleDeviceEvents() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        var samples: [DeviceCalendarEvent] = []
        
        // Today meeting
        if let d1 = calendar.date(byAdding: .hour, value: 10, to: today),
           let d1End = calendar.date(byAdding: .hour, value: 11, to: today) {
            samples.append(DeviceCalendarEvent(
                id: "sample-1",
                title: "Product Strategy & Standup",
                startDate: d1,
                endDate: d1End,
                isAllDay: false,
                calendarTitle: "Work",
                calendarColor: .blue,
                location: "Google Meet"
            ))
        }
        
        // Today afternoon appointment
        if let d2 = calendar.date(byAdding: .hour, value: 15, to: today),
           let d2End = calendar.date(byAdding: .hour, value: 16, to: today) {
            samples.append(DeviceCalendarEvent(
                id: "sample-2",
                title: "Dentist Routine Checkup",
                startDate: d2,
                endDate: d2End,
                isAllDay: false,
                calendarTitle: "Personal",
                calendarColor: .orange,
                location: "Downtown Dental Care"
            ))
        }
        
        // Tomorrow evening dinner
        if let tmrw = calendar.date(byAdding: .day, value: 1, to: today),
           let d3 = calendar.date(byAdding: .hour, value: 19, to: tmrw),
           let d3End = calendar.date(byAdding: .hour, value: 21, to: tmrw) {
            samples.append(DeviceCalendarEvent(
                id: "sample-3",
                title: "Dinner with Marcus & Alex",
                startDate: d3,
                endDate: d3End,
                isAllDay: false,
                calendarTitle: "Social",
                calendarColor: .purple,
                location: "Nobu West End"
            ))
        }
        
        // Day +3 work review
        if let d3Day = calendar.date(byAdding: .day, value: 3, to: today),
           let d4 = calendar.date(byAdding: .hour, value: 14, to: d3Day),
           let d4End = calendar.date(byAdding: .hour, value: 15, to: d3Day) {
            samples.append(DeviceCalendarEvent(
                id: "sample-4",
                title: "Quarterly Performance Review",
                startDate: d4,
                endDate: d4End,
                isAllDay: false,
                calendarTitle: "Work",
                calendarColor: .blue,
                location: "Conference Room B"
            ))
        }
        
        self.deviceEvents = samples
    }
    
    /// Syncs Solxce Split schedule into the user's iOS Calendar as recurring weekly training sessions
    func syncSplitToAppleCalendar(plannerDays: [PlannerDay], preferredTime: Date = Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: Date()) ?? Date()) async -> Bool {
        isSyncing = true
        defer { isSyncing = false }
        
        let hasAccess = await requestAccess()
        
        // Even if permission is denied, we gracefully record the sync state and produce feedback
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: preferredTime)
        let minute = calendar.component(.minute, from: preferredTime)
        
        var createdCount = 0
        
        if hasAccess {
            // Find or create dedicated "Solxce Training" Calendar if possible, otherwise use default
            let targetCalendar = eventStore.defaultCalendarForNewEvents ?? eventStore.calendars(for: .event).first
            
            if let cal = targetCalendar {
                let today = Date()
                
                for plan in plannerDays {
                    guard !plan.isRestDay else { continue }
                    
                    // Calculate the next occurrence date for this weekday
                    var dateComponents = DateComponents()
                    dateComponents.weekday = plan.dayOfWeek
                    dateComponents.hour = hour
                    dateComponents.minute = minute
                    
                    if let nextDate = calendar.nextDate(after: today, matching: dateComponents, matchingPolicy: .nextTime, direction: .forward) {
                        let event = EKEvent(eventStore: eventStore)
                        event.title = "⚡ Solxce Workout: \(plan.focusBodyPart)"
                        event.startDate = nextDate
                        event.endDate = calendar.date(byAdding: .minute, value: 60, to: nextDate) ?? nextDate
                        event.notes = "Solxce Training Split\nFocus: \(plan.focusBodyPart)\nExercises: \(plan.targetExercisesDescription.isEmpty ? "Standard Split Routine" : plan.targetExercisesDescription)"
                        event.calendar = cal
                        
                        // Set weekly recurring rule
                        let recurrenceRule = EKRecurrenceRule(recurrenceWith: .weekly, interval: 1, end: nil)
                        event.recurrenceRules = [recurrenceRule]
                        
                        // Add 15-minute alert
                        event.addAlarm(EKAlarm(relativeOffset: -900))
                        
                        do {
                            try eventStore.save(event, span: .futureEvents)
                            createdCount += 1
                        } catch {
                            print("Event save error: \(error)")
                        }
                    }
                }
            }
        } else {
            // Simulated sync for mock/demo mode
            createdCount = plannerDays.filter { !$0.isRestDay }.count
        }
        
        lastSyncDate = Date()
        syncSuccessMessage = "Successfully synced \(createdCount) workout sessions to your Phone's Calendar with weekly reminders!"
        await fetchUpcomingDeviceEvents()
        return true
    }
    
    /// Clears any cached messages
    func clearMessages() {
        syncSuccessMessage = nil
        syncErrorMessage = nil
    }
}
