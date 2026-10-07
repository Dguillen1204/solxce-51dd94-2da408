// Views/PlannerView.swift
import SwiftUI
import SwiftData
import EventKit

struct PlannerView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \PlannerDay.dayOfWeek) private var days: [PlannerDay]
    
    @ObservedObject private var calendarSync = CalendarSyncManager.shared
    
    @State private var editingDay: PlannerDay?
    @State private var inspectingDay: PlannerDay?
    @State private var selectedCalendarTab: CalendarViewMode = .splitPlanner
    @State private var showingSyncSheet: Bool = false
    @State private var selectedDateForInspection: Date = Date()

    enum CalendarViewMode: String, CaseIterable {
        case splitPlanner = "Solar Split"
        case dualView = "Dual Calendar"
    }

    // Custom sort order so Monday is first (2,3,4,5,6,7,1)
    var sortedDays: [PlannerDay] {
        days.sorted { a, b in
            let orderA = a.dayOfWeek == 1 ? 8 : a.dayOfWeek
            let orderB = b.dayOfWeek == 1 ? 8 : b.dayOfWeek
            return orderA < orderB
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.lg) {
                    // Header / Overview with Sync Status Button
                    headerSection
                    
                    // Segmented Control: Solar Split vs Dual Calendar
                    calendarModePicker
                    
                    if selectedCalendarTab == .splitPlanner {
                        // 7-Day Split Weekly Schedule
                        weeklySplitSection

                        // Split distribution summary
                        splitSummaryCard
                    } else {
                        // Dual Calendar Mode: Solar Split + Device Phone Calendar
                        dualCalendarSection
                    }
                }
                .padding(.horizontal, AppTheme.Spacing.screenMargin)
                .padding(.top, AppTheme.Spacing.sm)
                .padding(.bottom, AppTheme.Spacing.xxl)
            }
            .background(AppTheme.ground.ignoresSafeArea())
            .navigationTitle("Solar Split Planner")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingSyncSheet = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.system(size: 13, weight: .bold))
                            Text("Sync Phone")
                                .font(AppTheme.eyebrowFont)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(AppTheme.primary.opacity(0.15))
                        .foregroundStyle(AppTheme.primary)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule().strokeBorder(AppTheme.primary.opacity(0.3), lineWidth: 1)
                        )
                    }
                }
            }
            .sheet(item: $editingDay) { day in
                EditPlannerDaySheet(day: day)
            }
            .sheet(item: $inspectingDay) { day in
                DayDetailExerciseSheet(day: day, onEdit: {
                    let target = day
                    inspectingDay = nil
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        editingDay = target
                    }
                })
            }
            .sheet(isPresented: $showingSyncSheet) {
                CalendarSyncConfigSheet(days: days)
            }
            .onAppear {
                Task {
                    await calendarSync.fetchUpcomingDeviceEvents()
                }
            }
        }
    }

    // MARK: - Header Section
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                HStack(spacing: 6) {
                    Circle()
                        .fill(AppTheme.primary)
                        .frame(width: 8, height: 8)
                    Text("SOLAR 7-DAY SPLIT ENGINE")
                        .font(AppTheme.eyebrowFont)
                        .tracking(1.5)
                        .foregroundStyle(AppTheme.primary)
                }
                
                Spacer()
                
                if let lastSync = calendarSync.lastSyncDate {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(AppTheme.primary)
                        Text("Synced \(lastSync.formatted(.dateTime.hour().minute()))")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(AppTheme.textMuted)
                    }
                }
            }

            Text("Weekly Muscle Target & Exercises")
                .font(AppTheme.largeTitleFont)
                .foregroundStyle(AppTheme.text)

            Text("Plan each day's targeted muscle focus, customize exact lift routines, and sync straight into Apple Calendar.")
                .font(AppTheme.subheadlineFont)
                .foregroundStyle(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Calendar Mode Picker
    private var calendarModePicker: some View {
        HStack(spacing: 0) {
            ForEach(CalendarViewMode.allCases, id: \.self) { mode in
                let isSelected = selectedCalendarTab == mode
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedCalendarTab = mode
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: mode == .splitPlanner ? "figure.run.square.stack.fill" : "calendar.badge.clock")
                            .font(.system(size: 13))
                        Text(mode.rawValue)
                            .font(AppTheme.subheadlineFont)
                            .fontWeight(isSelected ? .bold : .medium)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(isSelected ? AppTheme.surfaceRaised : Color.clear)
                    .foregroundStyle(isSelected ? AppTheme.primary : AppTheme.textSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.button))
                }
            }
        }
        .padding(3)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.button + 2))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radii.button + 2)
                .strokeBorder(AppTheme.hairline, lineWidth: 1)
        )
    }

    // MARK: - Weekly Split Section
    private var weeklySplitSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            HStack {
                Text("WEEKLY MUSCLE ARCHITECTURE")
                    .font(AppTheme.eyebrowFont)
                    .tracking(1.2)
                    .foregroundStyle(AppTheme.textSecondary)
                
                Spacer()
                
                Text("Tap to edit exercises")
                    .font(AppTheme.captionFont)
                    .foregroundStyle(AppTheme.textMuted)
            }
            .padding(.horizontal, 2)

            ForEach(sortedDays) { day in
                plannerDayCard(day)
            }
        }
    }

    // MARK: - Split Card
    private func plannerDayCard(_ day: PlannerDay) -> some View {
        let isToday = isDayToday(day.dayOfWeek)
        let exercisesList = parseExercises(day.targetExercisesDescription)
        let muscleColor = colorForMuscleGroup(day.focusBodyPart, isRest: day.isRestDay)

        return VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: AppTheme.Spacing.md) {
                // Day Badge
                VStack(spacing: 2) {
                    Text(day.dayName.prefix(3).uppercased())
                        .font(AppTheme.eyebrowFont)
                        .foregroundStyle(day.isRestDay ? AppTheme.accent : AppTheme.primary)
                    Text(shortDayNumber(day.dayOfWeek))
                        .font(AppTheme.titleFont)
                        .bold()
                        .foregroundStyle(AppTheme.text)
                }
                .frame(width: 50, height: 52)
                .background(AppTheme.surfaceRaised)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.tag))
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.Radii.tag)
                        .strokeBorder(isToday ? AppTheme.primary : AppTheme.hairline, lineWidth: isToday ? 1.5 : 1)
                )

                // Day Info & Muscle Target
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(day.dayName)
                            .font(AppTheme.headlineFont)
                            .foregroundStyle(AppTheme.text)

                        if isToday {
                            Text("TODAY")
                                .font(.system(size: 9, weight: .heavy))
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(AppTheme.primary.opacity(0.2))
                                .foregroundStyle(AppTheme.primary)
                                .clipShape(Capsule())
                        }

                        Spacer()

                        // Quick Edit Button
                        Button {
                            editingDay = day
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "pencil")
                                    .font(.system(size: 11, weight: .semibold))
                                Text("Edit")
                                    .font(AppTheme.captionFont.weight(.semibold))
                            }
                            .padding(.horizontal, 9)
                            .padding(.vertical, 4)
                            .background(AppTheme.surfaceRaised)
                            .foregroundStyle(AppTheme.primary)
                            .clipShape(Capsule())
                        }
                    }

                    // Target Muscle Banner
                    HStack(spacing: 6) {
                        Circle()
                            .fill(muscleColor)
                            .frame(width: 7, height: 7)

                        Text("TARGET:")
                            .font(AppTheme.eyebrowFont)
                            .foregroundStyle(AppTheme.textMuted)

                        Text(day.focusBodyPart)
                            .font(AppTheme.subheadlineFont.weight(.bold))
                            .foregroundStyle(muscleColor)

                        if day.isRestDay {
                            Text("RECOVERY")
                                .font(AppTheme.eyebrowFont)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(AppTheme.accent.opacity(0.18))
                                .foregroundStyle(AppTheme.accent)
                                .clipShape(Capsule())
                        }
                    }
                }
            }

            // Exercise Tags List
            if !exercisesList.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("PLANNED EXERCISES (\(exercisesList.count))")
                        .font(AppTheme.eyebrowFont)
                        .tracking(1.0)
                        .foregroundStyle(AppTheme.textMuted)

                    FlowLayout(spacing: 6) {
                        ForEach(exercisesList, id: \.self) { ex in
                            HStack(spacing: 4) {
                                Image(systemName: "dumbbell.fill")
                                    .font(.system(size: 9))
                                    .foregroundStyle(AppTheme.primary.opacity(0.8))
                                Text(ex)
                                    .font(AppTheme.captionFont)
                                    .foregroundStyle(AppTheme.text)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(AppTheme.surfaceRaised)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                    }
                }
                .padding(.top, 4)
            } else if !day.isRestDay {
                HStack(spacing: 6) {
                    Image(systemName: "plus.circle")
                        .font(.system(size: 12))
                        .foregroundStyle(AppTheme.primary)
                    Text("No exercises set yet — Tap Edit to add your custom workout routine.")
                        .font(AppTheme.captionFont)
                        .foregroundStyle(AppTheme.textSecondary)
                }
                .padding(.top, 2)
            } else {
                HStack(spacing: 6) {
                    Image(systemName: "moon.stars.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(AppTheme.accent)
                    Text("Muscle recovery, hydration, mobility, and clean nutrition replenishment.")
                        .font(AppTheme.captionFont)
                        .foregroundStyle(AppTheme.textSecondary)
                }
                .padding(.top, 2)
            }
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.card))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radii.card)
                .strokeBorder(isToday ? AppTheme.primary.opacity(0.5) : (day.isRestDay ? AppTheme.hairline : AppTheme.primary.opacity(0.2)), lineWidth: isToday ? 1.5 : 1)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            inspectingDay = day
        }
    }

    private func shortDayNumber(_ dayOfWeek: Int) -> String {
        switch dayOfWeek {
        case 2: return "M"
        case 3: return "Tu"
        case 4: return "W"
        case 5: return "Th"
        case 6: return "F"
        case 7: return "Sa"
        case 1: return "Su"
        default: return ""
        }
    }

    private func isDayToday(_ dayOfWeek: Int) -> Bool {
        Calendar.current.component(.weekday, from: Date()) == dayOfWeek
    }

    private func parseExercises(_ description: String) -> [String] {
        let trimmed = description.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        // Split by commas or newlines
        let parts = trimmed.components(separatedBy: CharacterSet(charactersIn: ",\n•"))
        return parts.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
    }

    private func colorForMuscleGroup(_ bodyPart: String, isRest: Bool) -> Color {
        if isRest { return AppTheme.accent }
        let lower = bodyPart.lowercased()
        if lower.contains("chest") { return Color(red: 1.0, green: 0.42, blue: 0.24) } // Solar Orange
        if lower.contains("back") { return Color(red: 0.22, green: 0.74, blue: 0.97) }  // Sky Blue
        if lower.contains("leg") { return Color(red: 0.83, green: 1.0, blue: 0.25) }   // Volt Green
        if lower.contains("shoulder") || lower.contains("arm") { return Color(red: 0.66, green: 0.33, blue: 0.97) } // Purple
        if lower.contains("full") { return Color(red: 0.98, green: 0.75, blue: 0.14) }  // Amber
        if lower.contains("cardio") || lower.contains("run") { return Color(red: 0.06, green: 0.73, blue: 0.51) } // Emerald
        return AppTheme.primary
    }

    // MARK: - Dual Calendar Unified View
    private var dualCalendarSection: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            // Interactive 7-Day Week Strip
            weekDaySelectorStrip
            
            // Selected Day Breakdown (Solar Split Training + Phone Events)
            selectedDayScheduleCard
            
            // Sync Promo Card
            syncToPhoneBanner
        }
    }

    // MARK: - 7-Day Week Strip
    private var weekDaySelectorStrip: some View {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(0..<14, id: \.self) { offset in
                    if let date = calendar.date(byAdding: .day, value: offset, to: today) {
                        let isSelected = calendar.isDate(date, inSameDayAs: selectedDateForInspection)
                        let weekday = calendar.component(.weekday, from: date)
                        let plannerDay = days.first { $0.dayOfWeek == weekday }
                        let dayEvents = eventsForDate(date)
                        
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedDateForInspection = date
                            }
                        } label: {
                            VStack(spacing: 4) {
                                Text(date.formatted(.dateTime.weekday(.abbreviated)).uppercased())
                                    .font(AppTheme.eyebrowFont)
                                    .foregroundStyle(isSelected ? AppTheme.primary : AppTheme.textMuted)
                                
                                Text(date.formatted(.dateTime.day()))
                                    .font(AppTheme.headlineFont)
                                    .foregroundStyle(isSelected ? AppTheme.text : AppTheme.textSecondary)
                                
                                // Indicators
                                HStack(spacing: 3) {
                                    if let plan = plannerDay, !plan.isRestDay {
                                        Circle()
                                            .fill(AppTheme.primary)
                                            .frame(width: 5, height: 5)
                                    }
                                    if !dayEvents.isEmpty {
                                        Circle()
                                            .fill(Color.blue)
                                            .frame(width: 5, height: 5)
                                    }
                                }
                                .frame(height: 6)
                            }
                            .frame(width: 52, height: 72)
                            .background(isSelected ? AppTheme.surfaceRaised : AppTheme.surface)
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.card))
                            .overlay(
                                RoundedRectangle(cornerRadius: AppTheme.Radii.card)
                                    .strokeBorder(isSelected ? AppTheme.primary : AppTheme.hairline, lineWidth: isSelected ? 1.5 : 1)
                            )
                        }
                    }
                }
            }
            .padding(.horizontal, 2)
        }
    }

    // MARK: - Selected Day Combined Schedule
    private var selectedDayScheduleCard: some View {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: selectedDateForInspection)
        let plannerDay = days.first { $0.dayOfWeek == weekday }
        let phoneEvents = eventsForDate(selectedDateForInspection)
        let isToday = calendar.isDateInToday(selectedDateForInspection)

        return VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            // Day Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(selectedDateForInspection.formatted(.dateTime.weekday(.wide).month().day()))
                            .font(AppTheme.headlineFont)
                            .foregroundStyle(AppTheme.text)
                        
                        if isToday {
                            Text("TODAY")
                                .font(AppTheme.eyebrowFont)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(AppTheme.primary.opacity(0.18))
                                .foregroundStyle(AppTheme.primary)
                                .clipShape(Capsule())
                        }
                    }
                    Text("Unified Solar Split + Phone Schedule")
                        .font(AppTheme.captionFont)
                        .foregroundStyle(AppTheme.textSecondary)
                }
                Spacer()
            }

            Divider().background(AppTheme.hairline)

            // Section 1: Solar Training Target
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: "dumbbell.fill")
                        .foregroundStyle(AppTheme.primary)
                    Text("SOLAR TRAINING FOCUS")
                        .font(AppTheme.eyebrowFont)
                        .tracking(1.2)
                        .foregroundStyle(AppTheme.primary)
                }

                if let plan = plannerDay {
                    HStack(spacing: AppTheme.Spacing.md) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(plan.focusBodyPart)
                                .font(AppTheme.headlineFont)
                                .foregroundStyle(plan.isRestDay ? AppTheme.accent : AppTheme.text)
                            
                            if !plan.targetExercisesDescription.isEmpty {
                                Text(plan.targetExercisesDescription)
                                    .font(AppTheme.captionFont)
                                    .foregroundStyle(AppTheme.textSecondary)
                            } else if plan.isRestDay {
                                Text("Active recovery & muscle regeneration")
                                    .font(AppTheme.captionFont)
                                    .foregroundStyle(AppTheme.textSecondary)
                            } else {
                                Text("Target hypertrophy & strength sets")
                                    .font(AppTheme.captionFont)
                                    .foregroundStyle(AppTheme.textSecondary)
                            }
                        }
                        
                        Spacer()

                        Button {
                            editingDay = plan
                        } label: {
                            Text("Edit")
                                .font(AppTheme.captionFont)
                                .foregroundStyle(AppTheme.primary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(AppTheme.surfaceRaised)
                                .clipShape(Capsule())
                        }
                    }
                    .padding(AppTheme.Spacing.sm)
                    .background(AppTheme.surfaceRaised)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.card))
                }
            }

            // Section 2: Phone's Native Calendar Events
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: "calendar")
                        .foregroundStyle(Color.blue)
                    Text("PHONE CALENDAR EVENTS (\(phoneEvents.count))")
                        .font(AppTheme.eyebrowFont)
                        .tracking(1.2)
                        .foregroundStyle(Color.blue)
                }

                if phoneEvents.isEmpty {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle")
                            .foregroundStyle(AppTheme.textMuted)
                        Text("No conflicting phone events scheduled for this day.")
                            .font(AppTheme.captionFont)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    .padding(AppTheme.Spacing.sm)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AppTheme.surfaceRaised.opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.card))
                } else {
                    VStack(spacing: 6) {
                        ForEach(phoneEvents) { ev in
                            HStack(spacing: AppTheme.Spacing.sm) {
                                Circle()
                                    .fill(ev.calendarColor)
                                    .frame(width: 8, height: 8)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(ev.title)
                                        .font(AppTheme.subheadlineFont)
                                        .foregroundStyle(AppTheme.text)
                                    
                                    HStack(spacing: 6) {
                                        if ev.isAllDay {
                                            Text("All-day")
                                                .font(AppTheme.captionFont)
                                                .foregroundStyle(AppTheme.textMuted)
                                        } else {
                                            Text("\(ev.startDate.formatted(.dateTime.hour().minute())) - \(ev.endDate.formatted(.dateTime.hour().minute()))")
                                                .font(AppTheme.captionFont)
                                                .foregroundStyle(AppTheme.textMuted)
                                        }

                                        if let loc = ev.location, !loc.isEmpty {
                                            Text("• \(loc)")
                                                .font(AppTheme.captionFont)
                                                .foregroundStyle(AppTheme.textMuted)
                                                .lineLimit(1)
                                        }
                                    }
                                }

                                Spacer()

                                Text(ev.calendarTitle)
                                    .font(.system(size: 10, weight: .bold))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(ev.calendarColor.opacity(0.15))
                                    .foregroundStyle(ev.calendarColor)
                                    .clipShape(Capsule())
                            }
                            .padding(AppTheme.Spacing.sm)
                            .background(AppTheme.surfaceRaised)
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.card))
                        }
                    }
                }
            }
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.card))
    }

    // MARK: - Sync to Phone Banner
    private var syncToPhoneBanner: some View {
        Button {
            showingSyncSheet = true
        } label: {
            HStack(spacing: AppTheme.Spacing.md) {
                ZStack {
                    Circle()
                        .fill(AppTheme.primary.opacity(0.18))
                        .frame(width: 44, height: 44)
                    Image(systemName: "calendar.badge.plus")
                        .font(.system(size: 18))
                        .foregroundStyle(AppTheme.primary)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Export Solar Split to Phone Calendar")
                        .font(AppTheme.headlineFont)
                        .foregroundStyle(AppTheme.text)
                    Text("Auto-schedules recurring Apple Calendar reminders for each workout day.")
                        .font(AppTheme.captionFont)
                        .foregroundStyle(AppTheme.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppTheme.textMuted)
            }
            .padding(AppTheme.Spacing.md)
            .background(AppTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.card))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Radii.card)
                    .strokeBorder(AppTheme.primary.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func eventsForDate(_ date: Date) -> [DeviceCalendarEvent] {
        let calendar = Calendar.current
        return calendarSync.deviceEvents.filter {
            calendar.isDate($0.startDate, inSameDayAs: date)
        }
    }

    private var splitSummaryCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text("SOLAR SPLIT BALANCE")
                .font(AppTheme.eyebrowFont)
                .tracking(1.5)
                .foregroundStyle(AppTheme.textSecondary)

            let trainingDays = days.filter { !$0.isRestDay }.count
            let restDays = days.filter { $0.isRestDay }.count

            HStack(spacing: AppTheme.Spacing.md) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(trainingDays) Days")
                        .font(AppTheme.titleFont)
                        .foregroundStyle(AppTheme.primary)
                    Text("Training Sessions")
                        .font(AppTheme.captionFont)
                        .foregroundStyle(AppTheme.textSecondary)
                }

                Spacer()

                VStack(alignment: .leading, spacing: 2) {
                    Text("\(restDays) Days")
                        .font(AppTheme.titleFont)
                        .foregroundStyle(AppTheme.accent)
                    Text("Recovery Days")
                        .font(AppTheme.captionFont)
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.card))
    }
}

// MARK: - FlowLayout Component for Wrapping Tags
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 0
        var height: CGFloat = 0
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var rowMaxHeight: CGFloat = 0

        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if currentX + size.width > width && currentX > 0 {
                currentX = 0
                currentY += rowMaxHeight + spacing
                rowMaxHeight = 0
            }
            rowMaxHeight = max(rowMaxHeight, size.height)
            currentX += size.width + spacing
        }
        height = currentY + rowMaxHeight
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var currentX = bounds.minX
        var currentY = bounds.minY
        var rowMaxHeight: CGFloat = 0

        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if currentX + size.width > bounds.maxX && currentX > bounds.minX {
                currentX = bounds.minX
                currentY += rowMaxHeight + spacing
                rowMaxHeight = 0
            }
            view.place(at: CGPoint(x: currentX, y: currentY), proposal: .unspecified)
            rowMaxHeight = max(rowMaxHeight, size.height)
            currentX += size.width + spacing
        }
    }
}

// MARK: - Day Detail Exercise Sheet (Read & Quick Action)
struct DayDetailExerciseSheet: View {
    @Environment(\.dismiss) private var dismiss
    let day: PlannerDay
    let onEdit: () -> Void

    var exercises: [String] {
        let trimmed = day.targetExercisesDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        return trimmed.components(separatedBy: CharacterSet(charactersIn: ",\n•"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.lg) {
                    // Header Card
                    VStack(spacing: 8) {
                        Text(day.dayName.uppercased())
                            .font(AppTheme.eyebrowFont)
                            .tracking(2)
                            .foregroundStyle(day.isRestDay ? AppTheme.accent : AppTheme.primary)

                        Text(day.focusBodyPart)
                            .font(AppTheme.largeTitleFont)
                            .foregroundStyle(AppTheme.text)
                            .multilineTextAlignment(.center)

                        if day.isRestDay {
                            Text("Active recovery, mobility stretching, and macro fueling.")
                                .font(AppTheme.subheadlineFont)
                                .foregroundStyle(AppTheme.textSecondary)
                        } else {
                            Text("Target hypertrophy stimulus and planned sets for this day.")
                                .font(AppTheme.subheadlineFont)
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(AppTheme.Spacing.lg)
                    .background(AppTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.card))

                    // Exercise List
                    if !day.isRestDay {
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                            HStack {
                                Text("SCHEDULED EXERCISES")
                                    .font(AppTheme.eyebrowFont)
                                    .tracking(1.2)
                                    .foregroundStyle(AppTheme.textSecondary)
                                Spacer()
                                Text("\(exercises.count) Total")
                                    .font(AppTheme.captionFont)
                                    .foregroundStyle(AppTheme.primary)
                            }

                            if exercises.isEmpty {
                                VStack(spacing: 8) {
                                    Image(systemName: "dumbbell")
                                        .font(.system(size: 28))
                                        .foregroundStyle(AppTheme.textMuted)
                                    Text("No exercises specified for this workout yet.")
                                        .font(AppTheme.subheadlineFont)
                                        .foregroundStyle(AppTheme.textSecondary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 32)
                                .background(AppTheme.surface)
                                .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.card))
                            } else {
                                ForEach(Array(exercises.enumerated()), id: \.offset) { index, ex in
                                    HStack(spacing: AppTheme.Spacing.md) {
                                        ZStack {
                                            Circle()
                                                .fill(AppTheme.primary.opacity(0.15))
                                                .frame(width: 32, height: 32)
                                            Text("\(index + 1)")
                                                .font(.system(size: 13, weight: .bold))
                                                .foregroundStyle(AppTheme.primary)
                                        }

                                        Text(ex)
                                            .font(AppTheme.headlineFont)
                                            .foregroundStyle(AppTheme.text)

                                        Spacer()

                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(AppTheme.primary.opacity(0.6))
                                            .font(.system(size: 16))
                                    }
                                    .padding(AppTheme.Spacing.md)
                                    .background(AppTheme.surface)
                                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.card))
                                }
                            }
                        }
                    }

                    // Edit Routine Button
                    Button {
                        onEdit()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "pencil")
                            Text("CUSTOMIZE EXERCISES & TARGET MUSCLE")
                        }
                        .font(AppTheme.headlineFont)
                        .foregroundStyle(AppTheme.onPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(AppTheme.primary)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.button))
                    }
                }
                .padding(.horizontal, AppTheme.Spacing.screenMargin)
                .padding(.vertical, AppTheme.Spacing.md)
            }
            .background(AppTheme.ground.ignoresSafeArea())
            .navigationTitle("\(day.dayName) Overview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(AppTheme.headlineFont)
                    .foregroundStyle(AppTheme.primary)
                }
            }
        }
    }
}

// MARK: - Calendar Sync Config Sheet
struct CalendarSyncConfigSheet: View {
    @Environment(\.dismiss) private var dismiss
    let days: [PlannerDay]
    @ObservedObject private var syncManager = CalendarSyncManager.shared
    
    @State private var preferredTime: Date = {
        var comp = DateComponents()
        comp.hour = 7
        comp.minute = 0
        return Calendar.current.date(from: comp) ?? Date()
    }()
    @State private var enable15MinReminder: Bool = true
    @State private var isSyncingNow: Bool = false
    @State private var showSuccessBanner: Bool = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.lg) {
                    // Hero Icon
                    ZStack {
                        Circle()
                            .fill(AppTheme.primary.opacity(0.15))
                            .frame(width: 80, height: 80)
                        Image(systemName: "calendar.badge.clock")
                            .font(.system(size: 34))
                            .foregroundStyle(AppTheme.primary)
                    }
                    .padding(.top, AppTheme.Spacing.md)

                    VStack(spacing: 4) {
                        Text("Sync to Phone Calendar")
                            .font(AppTheme.titleFont)
                            .foregroundStyle(AppTheme.text)
                        Text("Export your customized Solar training split into Apple Calendar so workouts live alongside your meetings and appointments.")
                            .font(AppTheme.subheadlineFont)
                            .foregroundStyle(AppTheme.textSecondary)
                            .multilineTextAlignment(.center)
                    }

                    // Configuration Box
                    VStack(spacing: AppTheme.Spacing.md) {
                        // Training time
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Preferred Workout Time")
                                    .font(AppTheme.headlineFont)
                                    .foregroundStyle(AppTheme.text)
                                Text("When workouts will be slotted in your phone calendar")
                                    .font(AppTheme.captionFont)
                                    .foregroundStyle(AppTheme.textSecondary)
                            }
                            Spacer()
                            DatePicker("", selection: $preferredTime, displayedComponents: .hourAndMinute)
                                .labelsHidden()
                                .tint(AppTheme.primary)
                        }

                        Divider().background(AppTheme.hairline)

                        // 15 Min Reminder
                        Toggle(isOn: $enable15MinReminder) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("15-Min Prep Alarm")
                                    .font(AppTheme.headlineFont)
                                    .foregroundStyle(AppTheme.text)
                                Text("Receive a calendar notification before training starts")
                                    .font(AppTheme.captionFont)
                                    .foregroundStyle(AppTheme.textSecondary)
                            }
                        }
                        .tint(AppTheme.primary)

                        Divider().background(AppTheme.hairline)

                        // Scheduled days count
                        let activeDays = days.filter { !$0.isRestDay }
                        HStack {
                            Text("Scheduled Training Days")
                                .font(AppTheme.subheadlineFont)
                                .foregroundStyle(AppTheme.textSecondary)
                            Spacer()
                            Text("\(activeDays.count) sessions / week")
                                .font(AppTheme.headlineFont)
                                .foregroundStyle(AppTheme.primary)
                        }
                    }
                    .padding(AppTheme.Spacing.md)
                    .background(AppTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.card))

                    if let msg = syncManager.syncSuccessMessage, showSuccessBanner {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(AppTheme.primary)
                            Text(msg)
                                .font(AppTheme.captionFont)
                                .foregroundStyle(AppTheme.text)
                        }
                        .padding(AppTheme.Spacing.md)
                        .background(AppTheme.primary.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.card))
                    }

                    // Big Sync Button
                    Button {
                        isSyncingNow = true
                        Task {
                            _ = await syncManager.syncSplitToAppleCalendar(plannerDays: days, preferredTime: preferredTime)
                            isSyncingNow = false
                            showSuccessBanner = true
                        }
                    } label: {
                        HStack(spacing: 8) {
                            if isSyncingNow {
                                ProgressView()
                                    .tint(.black)
                            } else {
                                Image(systemName: "arrow.triangle.2.circlepath")
                            }
                            Text(isSyncingNow ? "Syncing Calendar..." : "SYNC TO APPLE CALENDAR")
                        }
                        .font(AppTheme.headlineFont)
                        .foregroundStyle(AppTheme.onPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(AppTheme.primary)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.button))
                    }
                    .disabled(isSyncingNow)

                    // Dual view advice
                    Text("💡 After syncing, toggle to **Dual Calendar** mode on the Planner tab to view your Solar workouts side-by-side with your daily phone events.")
                        .font(AppTheme.captionFont)
                        .foregroundStyle(AppTheme.textMuted)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, AppTheme.Spacing.md)
                }
                .padding(.horizontal, AppTheme.Spacing.screenMargin)
                .padding(.vertical, AppTheme.Spacing.lg)
            }
            .background(AppTheme.ground.ignoresSafeArea())
            .navigationTitle("Calendar Sync")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(AppTheme.headlineFont)
                    .foregroundStyle(AppTheme.primary)
                }
            }
        }
    }
}

// MARK: - Edit Planner Day Sheet (Full Exercise Customizer)
struct EditPlannerDaySheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var day: PlannerDay

    @State private var exerciseList: [String] = []
    @State private var newExerciseText: String = ""
    @State private var selectedMuscleGroup: String = "Chest & Triceps"
    @State private var isRest: Bool = false
    @State private var showPresetSelector: Bool = false

    let bodyPartOptions = [
        "Chest & Triceps",
        "Back & Biceps",
        "Legs & Core",
        "Shoulders & Arms",
        "Full Body Power",
        "Push (Chest/Shoulders/Tris)",
        "Pull (Back/Biceps)",
        "Legs & Hamstrings",
        "Upper Body Power",
        "Lower Body Strength",
        "Running & Conditioning",
        "Active Recovery",
        "Rest Day"
    ]

    let presetLibrary: [String: [String]] = [
        "Chest & Triceps": [
            "Barbell Bench Press", "Incline Dumbbell Press", "Dips (Chest Focus)", "Cable Tricep Pushdowns", "Incline Cable Flyes", "Overhead Rope Extension"
        ],
        "Back & Biceps": [
            "Barbell Deadlift", "Weighted Pull-Ups", "Chest-Supported T-Bar Row", "Lat Pulldown", "Barbell Bicep Curls", "Incline Dumbbell Curls"
        ],
        "Legs & Core": [
            "Barbell Back Squats", "Romanian Deadlifts (RDL)", "Bulgarian Split Squats", "Leg Extension", "Seated Leg Curl", "Hanging Leg Raises"
        ],
        "Shoulders & Arms": [
            "Overhead Barbell Press", "Dumbbell Lateral Raises", "Cable Face Pulls", "Incline Skullcrushers", "Cross-Body Hammer Curls", "Rear Delt Flyes"
        ],
        "Full Body Power": [
            "Power Cleans", "Front Squats", "Push Press", "Kettlebell Swings", "Farmer's Carries", "Pull-Ups"
        ],
        "Push (Chest/Shoulders/Tris)": [
            "Flat Dumbbell Press", "Seated DB Overhead Press", "Incline DB Press", "Cable Lateral Raises", "Overhead Tricep Extension"
        ],
        "Pull (Back/Biceps)": [
            "Barbell Row", "Neutral Grip Pull-Down", "Single-Arm DB Row", "Hammer Curls", "Preacher Curls", "Face Pulls"
        ],
        "Legs & Hamstrings": [
            "Front Squat", "Stiff-Leg Deadlift", "Walking Lunges", "Lying Leg Curl", "Standing Calf Raises"
        ],
        "Running & Conditioning": [
            "3 Mile Zone 2 Warmup", "6x400m Speed Repeats", "Core Plank Circuit", "Foam Rolling & Mobility"
        ],
        "Active Recovery": [
            "20 Min Incline Treadmill Walk", "Full Body Foam Rolling", "Hip & Shoulder Dynamic Mobility", "10 Min Sauna & Hydration"
        ]
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.lg) {
                    // Day Header & Rest Switch
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("\(day.dayName) Training Target")
                                    .font(AppTheme.headlineFont)
                                    .foregroundStyle(AppTheme.text)
                                Text("Choose target muscle group or toggle Rest Day")
                                    .font(AppTheme.captionFont)
                                    .foregroundStyle(AppTheme.textSecondary)
                            }
                            Spacer()
                        }

                        Toggle(isOn: $isRest) {
                            HStack(spacing: 8) {
                                Image(systemName: isRest ? "moon.stars.fill" : "flame.fill")
                                    .foregroundStyle(isRest ? AppTheme.accent : AppTheme.primary)
                                Text("Scheduled Rest Day")
                                    .font(AppTheme.subheadlineFont.weight(.semibold))
                                    .foregroundStyle(AppTheme.text)
                            }
                        }
                        .tint(AppTheme.accent)
                        .onChange(of: isRest) { _, newValue in
                            if newValue {
                                selectedMuscleGroup = "Rest Day"
                            } else if selectedMuscleGroup == "Rest Day" {
                                selectedMuscleGroup = "Chest & Triceps"
                            }
                        }
                    }
                    .padding(AppTheme.Spacing.md)
                    .background(AppTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.card))

                    if !isRest {
                        // Target Muscle Picker
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                            Text("TARGET MUSCLE GROUP")
                                .font(AppTheme.eyebrowFont)
                                .tracking(1.2)
                                .foregroundStyle(AppTheme.textSecondary)

                            Menu {
                                ForEach(bodyPartOptions, id: \.self) { option in
                                    Button {
                                        selectedMuscleGroup = option
                                    } label: {
                                        HStack {
                                            Text(option)
                                            if selectedMuscleGroup == option {
                                                Image(systemName: "checkmark")
                                            }
                                        }
                                    }
                                }
                            } label: {
                                HStack {
                                    Image(systemName: "figure.strengthtraining.traditional")
                                        .foregroundStyle(AppTheme.primary)
                                    Text(selectedMuscleGroup)
                                        .font(AppTheme.headlineFont)
                                        .foregroundStyle(AppTheme.text)
                                    Spacer()
                                    Image(systemName: "chevron.up.chevron.down")
                                        .font(.system(size: 12))
                                        .foregroundStyle(AppTheme.textMuted)
                                }
                                .padding(AppTheme.Spacing.md)
                                .background(AppTheme.surface)
                                .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.card))
                                .overlay(
                                    RoundedRectangle(cornerRadius: AppTheme.Radii.card)
                                        .strokeBorder(AppTheme.primary.opacity(0.3), lineWidth: 1)
                                )
                            }
                        }

                        // Exercise Customizer Section
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                            HStack {
                                Text("PLANNED EXERCISES")
                                    .font(AppTheme.eyebrowFont)
                                    .tracking(1.2)
                                    .foregroundStyle(AppTheme.textSecondary)

                                Spacer()

                                if let presets = presetLibrary[selectedMuscleGroup], !presets.isEmpty {
                                    Button {
                                        loadPresets(presets)
                                    } label: {
                                        HStack(spacing: 4) {
                                            Image(systemName: "sparkles")
                                                .font(.system(size: 11))
                                            Text("Load Preset Routine")
                                                .font(AppTheme.eyebrowFont)
                                        }
                                        .foregroundStyle(AppTheme.primary)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(AppTheme.primary.opacity(0.12))
                                        .clipShape(Capsule())
                                    }
                                }
                            }

                            // Add New Exercise Row
                            HStack(spacing: 8) {
                                TextField("Add exercise (e.g. Incline DB Press)", text: $newExerciseText)
                                    .font(AppTheme.subheadlineFont)
                                    .foregroundStyle(AppTheme.text)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 10)
                                    .background(AppTheme.field)
                                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.tag))
                                    .onSubmit {
                                        addExercise()
                                    }

                                Button(action: addExercise) {
                                    Image(systemName: "plus")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundStyle(AppTheme.onPrimary)
                                        .padding(11)
                                        .background(newExerciseText.trimmingCharacters(in: .whitespaces).isEmpty ? AppTheme.surfaceRaised : AppTheme.primary)
                                        .clipShape(Circle())
                                }
                                .disabled(newExerciseText.trimmingCharacters(in: .whitespaces).isEmpty)
                            }

                            // Exercise List Items
                            if exerciseList.isEmpty {
                                VStack(spacing: 6) {
                                    Image(systemName: "list.bullet.rectangle")
                                        .font(.system(size: 26))
                                        .foregroundStyle(AppTheme.textMuted)
                                    Text("No exercises added yet")
                                        .font(AppTheme.subheadlineFont)
                                        .foregroundStyle(AppTheme.textSecondary)
                                    Text("Type an exercise above or tap 'Load Preset Routine'.")
                                        .font(AppTheme.captionFont)
                                        .foregroundStyle(AppTheme.textMuted)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 24)
                                .background(AppTheme.surface)
                                .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.card))
                            } else {
                                VStack(spacing: 6) {
                                    ForEach(Array(exerciseList.enumerated()), id: \.offset) { index, item in
                                        HStack(spacing: 10) {
                                            ZStack {
                                                Circle()
                                                    .fill(AppTheme.primary.opacity(0.15))
                                                    .frame(width: 26, height: 26)
                                                Text("\(index + 1)")
                                                    .font(.system(size: 11, weight: .bold))
                                                    .foregroundStyle(AppTheme.primary)
                                            }

                                            Text(item)
                                                .font(AppTheme.subheadlineFont)
                                                .foregroundStyle(AppTheme.text)

                                            Spacer()

                                            Button {
                                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                    exerciseList.remove(at: index)
                                                }
                                            } label: {
                                                Image(systemName: "trash")
                                                    .font(.system(size: 12))
                                                    .foregroundStyle(Color(red: 1.0, green: 0.231, blue: 0.361))
                                                    .padding(6)
                                            }
                                        }
                                        .padding(AppTheme.Spacing.sm)
                                        .background(AppTheme.surface)
                                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.tag))
                                    }
                                }
                            }

                            // Suggested Quick-Add Pills
                            if let presets = presetLibrary[selectedMuscleGroup] {
                                let unadded = presets.filter { !exerciseList.contains($0) }
                                if !unadded.isEmpty {
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text("QUICK SUGGESTIONS")
                                            .font(AppTheme.eyebrowFont)
                                            .foregroundStyle(AppTheme.textMuted)

                                        FlowLayout(spacing: 6) {
                                            ForEach(unadded, id: \.self) { suggestion in
                                                Button {
                                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                        exerciseList.append(suggestion)
                                                    }
                                                } label: {
                                                    HStack(spacing: 4) {
                                                        Image(systemName: "plus")
                                                            .font(.system(size: 9))
                                                        Text(suggestion)
                                                            .font(AppTheme.captionFont)
                                                    }
                                                    .padding(.horizontal, 9)
                                                    .padding(.vertical, 5)
                                                    .background(AppTheme.surfaceRaised)
                                                    .foregroundStyle(AppTheme.primary)
                                                    .clipShape(Capsule())
                                                }
                                            }
                                        }
                                    }
                                    .padding(.top, 4)
                                }
                            }
                        }
                    } else {
                        // Rest Day Information
                        VStack(spacing: 12) {
                            Image(systemName: "bed.double.fill")
                                .font(.system(size: 34))
                                .foregroundStyle(AppTheme.accent)
                            Text("Scheduled Rest & Recovery Day")
                                .font(AppTheme.headlineFont)
                                .foregroundStyle(AppTheme.text)
                            Text("This day is marked for muscle protein synthesis, central nervous system reset, and hydration.")
                                .font(AppTheme.captionFont)
                                .foregroundStyle(AppTheme.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(AppTheme.Spacing.xl)
                        .background(AppTheme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.card))
                    }
                }
                .padding(.horizontal, AppTheme.Spacing.screenMargin)
                .padding(.vertical, AppTheme.Spacing.md)
            }
            .background(AppTheme.ground.ignoresSafeArea())
            .navigationTitle("Edit \(day.dayName)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(AppTheme.textSecondary)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveDayChanges()
                    }
                    .font(AppTheme.headlineFont)
                    .foregroundStyle(AppTheme.primary)
                }
            }
            .onAppear {
                self.isRest = day.isRestDay
                self.selectedMuscleGroup = day.focusBodyPart
                self.exerciseList = parseInitialExercises(day.targetExercisesDescription)
            }
        }
    }

    private func addExercise() {
        let trimmed = newExerciseText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            exerciseList.append(trimmed)
            newExerciseText = ""
        }
    }

    private func loadPresets(_ presets: [String]) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            self.exerciseList = presets
        }
    }

    private func parseInitialExercises(_ description: String) -> [String] {
        let trimmed = description.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        return trimmed.components(separatedBy: CharacterSet(charactersIn: ",\n•"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private func saveDayChanges() {
        day.isRestDay = isRest
        if isRest {
            day.focusBodyPart = "Rest Day"
            day.targetExercisesDescription = "Full muscle recovery, meal prep, and nutrition replenishment"
        } else {
            day.focusBodyPart = selectedMuscleGroup
            day.targetExercisesDescription = exerciseList.joined(separator: ", ")
        }
        try? modelContext.save()
        dismiss()
    }
}
