// Views/PlannerView.swift
import SwiftUI
import SwiftData

struct PlannerView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \PlannerDay.dayOfWeek) private var days: [PlannerDay]
    
    @ObservedObject private var calendarSync = CalendarSyncManager.shared
    
    @State private var editingDay: PlannerDay?
    @State private var selectedCalendarTab: CalendarViewMode = .splitPlanner
    @State private var showingSyncSheet: Bool = false
    @State private var selectedDateForInspection: Date = Date()

    enum CalendarViewMode: String, CaseIterable {
        case splitPlanner = "Solxce Split"
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
                    
                    // Segmented Control: Solxce Split vs Dual Calendar
                    calendarModePicker
                    
                    if selectedCalendarTab == .splitPlanner {
                        // 7-Day Split Cards
                        VStack(spacing: AppTheme.Spacing.sm) {
                            ForEach(sortedDays) { day in
                                plannerDayRow(day)
                            }
                        }

                        // Split distribution summary
                        splitSummaryCard
                    } else {
                        // Dual Calendar Mode: Solxce Split + Device Phone Calendar
                        dualCalendarSection
                    }
                }
                .padding(.horizontal, AppTheme.Spacing.screenMargin)
                .padding(.top, AppTheme.Spacing.sm)
                .padding(.bottom, AppTheme.Spacing.xxl)
            }
            .background(AppTheme.ground.ignoresSafeArea())
            .navigationTitle("Planner & Calendar")
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
                Text("INTEGRATED SCHEDULE")
                    .font(AppTheme.eyebrowFont)
                    .tracking(1.5)
                    .foregroundStyle(AppTheme.primary)
                
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

            Text("Training & Life Calendar")
                .font(AppTheme.largeTitleFont)
                .foregroundStyle(AppTheme.text)

            Text("Sync your weekly training split straight into Apple Calendar to see workouts alongside meetings and events.")
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

    // MARK: - Split Row
    private func plannerDayRow(_ day: PlannerDay) -> some View {
        Button(action: { editingDay = day }) {
            HStack(spacing: AppTheme.Spacing.md) {
                // Day Badge
                VStack {
                    Text(day.dayName.prefix(3).uppercased())
                        .font(AppTheme.eyebrowFont)
                        .foregroundStyle(day.isRestDay ? AppTheme.accent : AppTheme.primary)
                    Text(String(day.dayOfWeek == 1 ? "Sun" : day.dayName.prefix(1)))
                        .font(AppTheme.titleFont)
                        .bold()
                        .foregroundStyle(AppTheme.text)
                }
                .frame(width: 48)
                .padding(.vertical, 8)
                .background(AppTheme.surfaceRaised)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.tag))

                // Split Details
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(day.focusBodyPart)
                            .font(AppTheme.headlineFont)
                            .foregroundStyle(day.isRestDay ? AppTheme.textSecondary : AppTheme.text)

                        if day.isRestDay {
                            Text("REST")
                                .font(AppTheme.eyebrowFont)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(AppTheme.accent.opacity(0.18))
                                .foregroundStyle(AppTheme.accent)
                                .clipShape(Capsule())
                        }
                    }

                    if !day.targetExercisesDescription.isEmpty {
                        Text(day.targetExercisesDescription)
                            .font(AppTheme.captionFont)
                            .foregroundStyle(AppTheme.textSecondary)
                            .lineLimit(1)
                    }
                }

                Spacer()

                Image(systemName: "pencil")
                    .font(.system(size: 14))
                    .foregroundStyle(AppTheme.textMuted)
            }
            .padding(AppTheme.Spacing.sm)
            .background(AppTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.card))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Radii.card)
                    .strokeBorder(day.isRestDay ? AppTheme.hairline : AppTheme.primary.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Dual Calendar Unified View
    private var dualCalendarSection: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            // Interactive 7-Day Week Strip
            weekDaySelectorStrip
            
            // Selected Day Breakdown (Solxce Training + Phone Events)
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
                    Text("Unified Solxce + Phone Schedule")
                        .font(AppTheme.captionFont)
                        .foregroundStyle(AppTheme.textSecondary)
                }
                Spacer()
            }

            Divider().background(AppTheme.hairline)

            // Section 1: Solxce Training Target
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: "dumbbell.fill")
                        .foregroundStyle(AppTheme.primary)
                    Text("SOLXCE TRAINING FOCUS")
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
                    Text("Export Split to Phone Calendar")
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
            Text("SPLIT BALANCE")
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
                        Text("Export your customized Solxce training split into Apple Calendar so workouts live alongside your meetings and appointments.")
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
                    Text("💡 After syncing, toggle to **Dual Calendar** mode on the Planner tab to view your Solxce workouts side-by-side with your daily phone events.")
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

// MARK: - Edit Planner Day Sheet
struct EditPlannerDaySheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var day: PlannerDay

    let bodyPartOptions = [
        "Chest & Triceps",
        "Back & Biceps",
        "Legs & Core",
        "Shoulders & Arms",
        "Full Body Power",
        "Push (Chest/Shoulders/Tris)",
        "Pull (Back/Biceps)",
        "Legs & Hamstrings",
        "Upper Body",
        "Lower Body",
        "Running & Cardio",
        "Active Recovery",
        "Rest Day"
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("\(day.dayName) Focus") {
                    Toggle("Is Rest Day", isOn: $day.isRestDay)
                        .tint(AppTheme.primary)

                    if !day.isRestDay {
                        Picker("Target Muscle Group", selection: $day.focusBodyPart) {
                            ForEach(bodyPartOptions, id: \.self) {
                                Text($0).tag($0)
                            }
                        }

                        TextField("Target Exercises / Notes", text: $day.targetExercisesDescription, axis: .vertical)
                            .lineLimit(3...5)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppTheme.ground.ignoresSafeArea())
            .navigationTitle("Edit \(day.dayName)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        if day.isRestDay {
                            day.focusBodyPart = "Rest Day"
                        }
                        try? modelContext.save()
                        dismiss()
                    }
                    .font(AppTheme.headlineFont)
                    .foregroundStyle(AppTheme.primary)
                }
            }
        }
    }
}
