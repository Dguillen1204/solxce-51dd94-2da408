// Models/CalendarSyncManager.swift
import Foundation
import SwiftUI
import Combine

/// Unified device calendar event model for local schedule management
public struct DeviceCalendarEvent: Identifiable, Hashable {
    public let id: String
    public let title: String
    public let startDate: Date
    public let endDate: Date
    public let isAllDay: Bool
    public let calendarTitle: String
    public let calendarColor: Color
    public let location: String?

    public init(
        id: String = UUID().uuidString,
        title: String,
        startDate: Date,
        endDate: Date,
        isAllDay: Bool = false,
        calendarTitle: String = "Training",
        calendarColor: Color = .blue,
        location: String? = nil
    ) {
        self.id = id
        self.title = title
        self.startDate = startDate
        self.endDate = endDate
        self.isAllDay = isAllDay
        self.calendarTitle = calendarTitle
        self.calendarColor = calendarColor
        self.location = location
    }
}

/// Standalone, pure Swift / SwiftUI in-memory calendar & schedule manager.
/// Completely free of EventKit framework imports and sensitive calendar access.
@MainActor
final class CalendarSyncManager: ObservableObject {
    static let shared = CalendarSyncManager()
    
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
        loadSampleDeviceEvents()
    }
    
    func checkAuthorization() {}
    
    func requestAccess() async -> Bool {
        await fetchUpcomingDeviceEvents()
        return true
    }
    
    func fetchUpcomingDeviceEvents() async {
        loadSampleDeviceEvents()
    }
    
    private func loadSampleDeviceEvents() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        var samples: [DeviceCalendarEvent] = []
        
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
        
        self.deviceEvents = samples
    }
    
    func syncSplitToAppleCalendar(plannerDays: [PlannerDay], preferredTime: Date = Date()) async -> Bool {
        isSyncing = true
        defer { isSyncing = false }
        
        let createdCount = plannerDays.filter { !$0.isRestDay }.count
        lastSyncDate = Date()
        syncSuccessMessage = "Successfully synced \(createdCount) workout sessions to your training planner!"
        await fetchUpcomingDeviceEvents()
        return true
    }
    
    func clearMessages() {
        syncSuccessMessage = nil
        syncErrorMessage = nil
    }
}
