// Views/PlannerView.swift
import SwiftUI
import SwiftData
import EventKit

struct PlannerView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \PlannerDay.dayOfWeek) private var days: [PlannerDay]
    
    @ObservedObject private var calendarSync = CalendarSyncManager.shared
    
    @State private var editingDay: PlannerDay?
    @State private var selectedCalendarTab: CalendarViewMode = .splitPlanner
    @State private var showingSyncSheet: Bool = false
    @State private var showingSplitPresetsSheet: Bool = false
    @State private var selectedDateForInspection: Date = Date()
    @State private var presetAppliedToast: String? = nil

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
                    
                    // Split Switcher & Presets Quick Action Bar
                    splitActionBar
                    
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
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showingSplitPresetsSheet = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "slider.horizontal.3")
                                .font(.system(size: 13, weight: .bold))
                            Text("Change Split")
                                .font(AppTheme.eyebrowFont)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.08))
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                    }
                }
                
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
            .sheet(isPresented: $showingSplitPresetsSheet) {
                SplitPresetsSelectionSheet(days: days) { appliedPresetName in
                    withAnimation {
                        presetAppliedToast = appliedPresetName
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                        withAnimation {
                            presetAppliedToast = nil
                        }
                    }
                }
            }
            .overlay(alignment: .bottom) {
                if let toast = presetAppliedToast {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(AppTheme.primary)
                        Text("Applied '\(toast)' Split Schedule")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color(red: 0.12, green: 0.12, blue: 0.14))
                    .clipShape(Capsule())
                    .overlay(Capsule().strokeBorder(AppTheme.primary.opacity(0.4), lineWidth: 1))
                    .shadow(color: .black.opacity(0.4), radius: 10, y: 5)
                    .padding(.bottom, 24)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
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

            Text("Customize your 7-day routine, apply proven workout split templates, or edit target muscle groups per day.")
                .font(AppTheme.subheadlineFont)
                .foregroundStyle(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Split Action Bar
    private var splitActionBar: some View {
        HStack(spacing: 12) {
            Button {
                showingSplitPresetsSheet = true
            } label: {
                HStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(AppTheme.primary.opacity(0.18))
                            .frame(width: 36, height: 36)
                        Image(systemName: "square.grid.2x2.fill")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(AppTheme.primary)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Workout Split Templates")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(AppTheme.text)
                        Text("PPL, Upper/Lower, Hybrid, Arnold & more")
                            .font(.system(size: 12))
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(AppTheme.textMuted)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(AppTheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.card))
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.Radii.card)
                        .strokeBorder(AppTheme.hairline, lineWidth: 1)
                )
            }
        }
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
                    .foregroundStyle(isSelected ? AppTheme.text : AppTheme.textMuted)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
        .padding(4)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Planner Day Row
    private func plannerDayRow(_ day: PlannerDay) -> some View {
        let isToday = Calendar.current.component(.weekday, from: Date()) == day.dayOfWeek
        
        return Button {
            editingDay = day
        } label: {
            HStack(spacing: AppTheme.Spacing.md) {
                // Day Badge
                VStack(spacing: 2) {
                    Text(day.dayName.prefix(3).uppercased())
                        .font(.system(size: 13, weight: .black, design: .monospaced))
                        .foregroundStyle(isToday ? AppTheme.primary : AppTheme.textSecondary)
                    
                    if isToday {
                        Circle()
                            .fill(AppTheme.primary)
                            .frame(width: 4, height: 4)
                    }
                }
                .frame(width: 44)
                .padding(.vertical, 8)
                .background(isToday ? AppTheme.primary.opacity(0.12) : AppTheme.surfaceRaised)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(isToday ? AppTheme.primary.opacity(0.4) : Color.clear, lineWidth: 1)
                )

                // Details
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(day.focusBodyPart)
                            .font(AppTheme.headlineFont)
                            .foregroundStyle(day.isRestDay ? AppTheme.textMuted : AppTheme.text)
                        
                        if isToday {
                            Text("TODAY")
                                .font(.system(size: 9, weight: .heavy))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(AppTheme.primary)
                                .foregroundStyle(AppTheme.onPrimary)
                                .clipShape(Capsule())
                        }
                    }

                    if day.isRestDay {
                        Text("Active recovery, mobility, or total rest")
                            .font(AppTheme.captionFont)
                            .foregroundStyle(AppTheme.textMuted)
                    } else {
                        Text(day.targetExercisesDescription.isEmpty ? "Tap to add exercises & target routine" : day.targetExercisesDescription)
                            .font(AppTheme.captionFont)
                            .foregroundStyle(AppTheme.textSecondary)
                            .lineLimit(1)
                    }
                }

                Spacer()

                // Edit indicator / Rest badge
                if day.isRestDay {
                    Image(systemName: "bed.double.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(AppTheme.textMuted)
                } else {
                    Image(systemName: "pencil")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(AppTheme.textMuted)
                }
            }
            .padding(AppTheme.Spacing.md)
            .background(AppTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.card))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Radii.card)
                    .strokeBorder(isToday ? AppTheme.primary.opacity(0.3) : AppTheme.hairline, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Split Summary Card
    private var splitSummaryCard: some View {
        let trainingDays = days.filter { !$0.isRestDay }
        let restDays = days.filter { $0.isRestDay }

        return VStack(spacing: AppTheme.Spacing.md) {
            HStack {
                Text("WEEKLY SPLIT BREAKDOWN")
                    .font(AppTheme.eyebrowFont)
                    .foregroundStyle(AppTheme.textMuted)
                Spacer()
                Text("\(trainingDays.count) Training / \(restDays.count) Rest")
                    .font(AppTheme.captionFont)
                    .foregroundStyle(AppTheme.primary)
            }

            // Visual frequency bar
            HStack(spacing: 4) {
                ForEach(sortedDays) { day in
                    VStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(day.isRestDay ? AppTheme.surfaceRaised : AppTheme.primary)
                            .frame(height: 6)
                        Text(day.dayName.prefix(1))
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(day.isRestDay ? AppTheme.textMuted : AppTheme.text)
                    }
                    .frame(maxWidth: .infinity)
                }
            }

            Divider().background(AppTheme.hairline)

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Ready to adjust your routine?")
                        .font(AppTheme.captionFont)
                        .foregroundStyle(AppTheme.textSecondary)
                    Text("Tap any individual day above or pick a full split preset.")
                        .font(.system(size: 11))
                        .foregroundStyle(AppTheme.textMuted)
                }
                Spacer()
                Button {
                    showingSplitPresetsSheet = true
                } label: {
                    Text("Browse Splits")
                        .font(.system(size: 12, weight: .bold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(AppTheme.primary.opacity(0.15))
                        .foregroundStyle(AppTheme.primary)
                        .clipShape(Capsule())
                }
            }
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.card))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radii.card)
                .strokeBorder(AppTheme.hairline, lineWidth: 1)
        )
    }

    // MARK: - Dual Calendar Section
    private var dualCalendarSection: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            // Day selector strip for dual inspection
            dualDayPickerStrip

            // Solxce Workout for selected date
            selectedDateSolxceCard

            // Device Calendar Events for selected date
            selectedDateDeviceEventsCard
        }
    }

    private var dualDayPickerStrip: some View {
        HStack(spacing: 6) {
            ForEach(0..<7) { offset in
                let targetDate = Calendar.current.date(byAdding: .day, value: offset, to: Date()) ?? Date()
                let isSelected = Calendar.current.isDate(targetDate, inSameDayAs: selectedDateForInspection)
                let weekday = Calendar.current.component(.weekday, from: targetDate)
                let dayLetter = Calendar.current.shortWeekdaySymbols[weekday - 1].prefix(1)
                let dayNumber = Calendar.current.component(.day, from: targetDate)

                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedDateForInspection = targetDate
                    }
                } label: {
                    VStack(spacing: 4) {
                        Text(dayLetter)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(isSelected ? AppTheme.onPrimary : AppTheme.textMuted)
                        Text("\(dayNumber)")
                            .font(.system(size: 14, weight: .heavy))
                            .foregroundStyle(isSelected ? AppTheme.onPrimary : AppTheme.text)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(isSelected ? AppTheme.primary : AppTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(isSelected ? Color.clear : AppTheme.hairline, lineWidth: 1)
                    )
                }
            }
        }
    }

    private var selectedDateSolxceCard: some View {
        let weekday = Calendar.current.component(.weekday, from: selectedDateForInspection)
        let plannerDay = days.first(where: { $0.dayOfWeek == weekday })

        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "dumbbell.fill")
                    .foregroundStyle(AppTheme.primary)
                Text("SOLXCE WORKOUT SCHEDULE")
                    .font(AppTheme.eyebrowFont)
                    .foregroundStyle(AppTheme.primary)
                Spacer()
                Text(selectedDateForInspection.formatted(.dateTime.weekday(.wide).month().day()))
                    .font(AppTheme.captionFont)
                    .foregroundStyle(AppTheme.textMuted)
            }

            if let day = plannerDay {
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(day.focusBodyPart)
                            .font(AppTheme.headlineFont)
                            .foregroundStyle(AppTheme.text)

                        Text(day.isRestDay ? "Designated rest & recovery day" : (day.targetExercisesDescription.isEmpty ? "No specific exercises logged" : day.targetExercisesDescription))
                            .font(AppTheme.captionFont)
                            .foregroundStyle(AppTheme.textSecondary)
                    }

                    Spacer()

                    Button {
                        editingDay = day
                    } label: {
                        Text("Edit")
                            .font(.system(size: 12, weight: .bold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(AppTheme.surfaceRaised)
                            .foregroundStyle(AppTheme.text)
                            .clipShape(Capsule())
                    }
                }
            } else {
                Text("No routine assigned for this day.")
                    .font(AppTheme.captionFont)
                    .foregroundStyle(AppTheme.textMuted)
            }
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.card))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radii.card)
                .strokeBorder(AppTheme.hairline, lineWidth: 1)
        )
    }

    private var selectedDateDeviceEventsCard: some View {
        let eventsOnDate = calendarSync.deviceEvents.filter { event in
            Calendar.current.isDate(event.startDate, inSameDayAs: selectedDateForInspection)
        }

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "calendar")
                    .foregroundStyle(.blue)
                Text("PHONE CALENDAR EVENTS")
                    .font(AppTheme.eyebrowFont)
                    .foregroundStyle(.blue)
                Spacer()
                Text("\(eventsOnDate.count) Events")
                    .font(AppTheme.captionFont)
                    .foregroundStyle(AppTheme.textMuted)
            }

            if eventsOnDate.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 28))
                        .foregroundStyle(AppTheme.textMuted)
                    Text("No personal calendar conflicts found")
                        .font(AppTheme.captionFont)
                        .foregroundStyle(AppTheme.textMuted)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
            } else {
                VStack(spacing: 8) {
                    ForEach(eventsOnDate) { event in
                        let isSolxce = event.title.localizedCaseInsensitiveContains("Solxce")
                        HStack(spacing: 12) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(isSolxce ? AppTheme.primary : event.calendarColor)
                                .frame(width: 4, height: 32)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(event.title)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(AppTheme.text)
                                Text("\(event.startDate.formatted(.dateTime.hour().minute())) - \(event.endDate.formatted(.dateTime.hour().minute()))")
                                    .font(AppTheme.captionFont)
                                    .foregroundStyle(AppTheme.textSecondary)
                            }

                            Spacer()

                            if isSolxce {
                                Text("SOLXCE")
                                    .font(.system(size: 9, weight: .bold))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(AppTheme.primary.opacity(0.15))
                                    .foregroundStyle(AppTheme.primary)
                                    .clipShape(Capsule())
                            }
                        }
                        .padding(8)
                        .background(AppTheme.surfaceRaised)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.card))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radii.card)
                .strokeBorder(AppTheme.hairline, lineWidth: 1)
        )
    }
}

// MARK: - Split Presets Selection Sheet
struct SplitPresetsSelectionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let days: [PlannerDay]
    var onApplied: ((String) -> Void)?

    @State private var selectedPresetId: String = "ppl_6day"

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.lg) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("SELECT A WORKOUT SPLIT")
                            .font(AppTheme.eyebrowFont)
                            .tracking(1.5)
                            .foregroundStyle(AppTheme.primary)

                        Text("Prebuilt Training Programs")
                            .font(AppTheme.largeTitleFont)
                            .foregroundStyle(AppTheme.text)

                        Text("Choose a structured routine. Applying a preset updates your entire 7-day schedule with optimized muscle group distributions.")
                            .font(AppTheme.subheadlineFont)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    // Presets List
                    VStack(spacing: 12) {
                        ForEach(SplitPresetCatalog.allPresets) { preset in
                            presetCard(preset)
                        }
                    }
                }
                .padding(.horizontal, AppTheme.Spacing.screenMargin)
                .padding(.vertical, AppTheme.Spacing.lg)
            }
            .background(AppTheme.ground.ignoresSafeArea())
            .navigationTitle("Change Workout Split")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(AppTheme.textSecondary)
                }
            }
        }
    }

    private func presetCard(_ preset: WorkoutSplitPreset) -> some View {
        let isSelected = selectedPresetId == preset.id

        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(preset.accentColor.opacity(0.18))
                        .frame(width: 44, height: 44)
                    Image(systemName: preset.iconName)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(preset.accentColor)
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(preset.name)
                            .font(AppTheme.headlineFont)
                            .foregroundStyle(AppTheme.text)
                        
                        Text("\(preset.frequencyDays) Days/Wk")
                            .font(.system(size: 10, weight: .heavy))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(preset.accentColor.opacity(0.15))
                            .foregroundStyle(preset.accentColor)
                            .clipShape(Capsule())
                    }

                    Text(preset.subtitle)
                        .font(AppTheme.captionFont)
                        .foregroundStyle(AppTheme.textSecondary)
                }

                Spacer()
            }

            // Preview 7 days in miniature
            VStack(spacing: 4) {
                ForEach(preset.schedule.sorted(by: { a, b in
                    let orderA = a.dayOfWeek == 1 ? 8 : a.dayOfWeek
                    let orderB = b.dayOfWeek == 1 ? 8 : b.dayOfWeek
                    return orderA < orderB
                }), id: \.dayOfWeek) { item in
                    let dayName = Calendar.current.shortWeekdaySymbols[item.dayOfWeek - 1]
                    HStack(spacing: 8) {
                        Text(dayName.uppercased())
                            .font(.system(size: 10, weight: .black, design: .monospaced))
                            .foregroundStyle(item.isRestDay ? AppTheme.textMuted : preset.accentColor)
                            .frame(width: 32, alignment: .leading)

                        Text(item.focusBodyPart)
                            .font(.system(size: 12, weight: item.isRestDay ? .regular : .semibold))
                            .foregroundStyle(item.isRestDay ? AppTheme.textMuted : AppTheme.text)

                        Spacer()

                        if item.isRestDay {
                            Text("Rest")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(AppTheme.textMuted)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
            .padding(10)
            .background(AppTheme.surfaceRaised)
            .clipShape(RoundedRectangle(cornerRadius: 10))

            // Apply Button
            Button {
                applySplitPreset(preset)
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Apply \(preset.name)")
                        .font(.system(size: 13, weight: .bold))
                }
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(preset.accentColor)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.card))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radii.card)
                .strokeBorder(isSelected ? preset.accentColor.opacity(0.5) : AppTheme.hairline, lineWidth: 1)
        )
    }

    private func applySplitPreset(_ preset: WorkoutSplitPreset) {
        for template in preset.schedule {
            if let targetDay = days.first(where: { $0.dayOfWeek == template.dayOfWeek }) {
                targetDay.focusBodyPart = template.focusBodyPart
                targetDay.isRestDay = template.isRestDay
                targetDay.targetExercisesDescription = template.targetExercises
            }
        }
        try? modelContext.save()
        onApplied?(preset.name)
        dismiss()
    }
}

// MARK: - Calendar Sync Config Sheet
struct CalendarSyncConfigSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var syncManager = CalendarSyncManager.shared
    let days: [PlannerDay]

    @State private var preferredTime: Date = {
        var comps = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        comps.hour = 7
        comps.minute = 0
        return Calendar.current.date(from: comps) ?? Date()
    }()
    @State private var enable15MinReminder: Bool = true
    @State private var isSyncingNow: Bool = false
    @State private var showSuccessBanner: Bool = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.lg) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("AUTOMATIC INTEGRATION")
                            .font(AppTheme.eyebrowFont)
                            .tracking(1.5)
                            .foregroundStyle(AppTheme.primary)

                        Text("Sync Solxce to Calendar")
                            .font(AppTheme.largeTitleFont)
                            .foregroundStyle(AppTheme.text)

                        Text("Solxce can create dedicated calendar events in Apple Calendar for your workout schedule with built-in reminder alarms.")
                            .font(AppTheme.subheadlineFont)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    // Preferences Box
                    VStack(spacing: AppTheme.Spacing.md) {
                        // Preferred Time Picker
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
        "Push (Chest & Triceps)",
        "Pull (Back & Biceps)",
        "Legs & Core",
        "Chest & Triceps",
        "Back & Biceps",
        "Shoulders & Arms",
        "Upper Body Strength",
        "Lower Body Strength",
        "Full Body Power",
        "Endurance & Running",
        "Speed Intervals & Track",
        "Active Recovery & Mobility",
        "Rest Day"
    ]

    let quickExerciseSuggestions: [String: [String]] = [
        "Push": ["Barbell Bench Press", "Incline DB Press", "Overhead Press", "Triceps Pushdown", "Lateral Raises", "Cable Flyes"],
        "Pull": ["Deadlifts", "Barbell Rows", "Weighted Pull-Ups", "Lat Pulldown", "Incline Curls", "Hammer Curls", "Facepulls"],
        "Legs": ["Barbell Back Squats", "Romanian Deadlifts", "Leg Press", "Bulgarian Split Squats", "Lying Leg Curls", "Calf Raises"],
        "Shoulders": ["Military Press", "DB Lateral Raises", "Rear Delt Flyes", "Upright Rows", "Shrugs"],
        "Running": ["5 Mile Zone-2 Run", "6x400m Track Intervals", "3 Mile Tempo Run", "Hill Repeats", "Long Slow Distance"]
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle(isOn: $day.isRestDay) {
                        HStack(spacing: 10) {
                            Image(systemName: day.isRestDay ? "bed.double.fill" : "figure.run")
                                .foregroundStyle(day.isRestDay ? AppTheme.textMuted : AppTheme.primary)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Rest Day")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(.white)
                                Text("Pause scheduled workout for recovery")
                                    .font(.system(size: 12))
                                    .foregroundStyle(AppTheme.textSecondary)
                            }
                        }
                    }
                    .tint(AppTheme.primary)

                    if !day.isRestDay {
                        Picker("Target Focus", selection: $day.focusBodyPart) {
                            ForEach(bodyPartOptions, id: \.self) { option in
                                Text(option).tag(option)
                            }
                        }
                        .foregroundStyle(.white)
                    }
                } header: {
                    Text("\(day.dayName.uppercased()) FOCUS")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(AppTheme.primary)
                }
                .listRowBackground(Color.white.opacity(0.04))

                if !day.isRestDay {
                    Section {
                        TextField("e.g. Incline Bench, Overhead Press, Cable Flyes...", text: $day.targetExercisesDescription, axis: .vertical)
                            .lineLimit(3...6)
                            .foregroundStyle(.white)
                    } header: {
                        Text("TARGET EXERCISES & NOTES")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(AppTheme.primary)
                    } footer: {
                        Text("These notes sync with your daily workout card and Apple Calendar event.")
                            .font(.system(size: 11))
                            .foregroundStyle(AppTheme.textMuted)
                    }
                    .listRowBackground(Color.white.opacity(0.04))

                    // Quick suggestion chips
                    Section {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("TAP TO ADD EXERCISE")
                                .font(.system(size: 10, weight: .heavy))
                                .foregroundStyle(AppTheme.textMuted)

                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 140))], spacing: 8) {
                                ForEach(currentSuggestions, id: \.self) { item in
                                    Button {
                                        addExerciseToDescription(item)
                                    } label: {
                                        HStack(spacing: 4) {
                                            Image(systemName: "plus.circle.fill")
                                                .font(.system(size: 11))
                                            Text(item)
                                                .font(.system(size: 12, weight: .medium))
                                                .lineLimit(1)
                                        }
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(AppTheme.surfaceRaised)
                                        .foregroundStyle(AppTheme.primary)
                                        .clipShape(Capsule())
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 6)
                    }
                    .listRowBackground(Color.white.opacity(0.04))
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppTheme.ground.ignoresSafeArea())
            .navigationTitle("Edit \(day.dayName)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if day.isRestDay {
                            day.focusBodyPart = "Rest Day"
                        }
                        try? modelContext.save()
                        dismiss()
                    }
                    .font(AppTheme.headlineFont)
                    .foregroundStyle(AppTheme.primary)
                }
                
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(AppTheme.textSecondary)
                }
            }
        }
    }

    private var currentSuggestions: [String] {
        if day.focusBodyPart.lowercased().contains("push") || day.focusBodyPart.lowercased().contains("chest") {
            return quickExerciseSuggestions["Push"] ?? []
        } else if day.focusBodyPart.lowercased().contains("pull") || day.focusBodyPart.lowercased().contains("back") {
            return quickExerciseSuggestions["Pull"] ?? []
        } else if day.focusBodyPart.lowercased().contains("leg") {
            return quickExerciseSuggestions["Legs"] ?? []
        } else if day.focusBodyPart.lowercased().contains("shoulder") || day.focusBodyPart.lowercased().contains("arm") {
            return quickExerciseSuggestions["Shoulders"] ?? []
        } else if day.focusBodyPart.lowercased().contains("run") || day.focusBodyPart.lowercased().contains("cardio") {
            return quickExerciseSuggestions["Running"] ?? []
        } else {
            return (quickExerciseSuggestions["Push"] ?? []) + (quickExerciseSuggestions["Pull"] ?? [])
        }
    }

    private func addExerciseToDescription(_ exercise: String) {
        if day.targetExercisesDescription.isEmpty {
            day.targetExercisesDescription = exercise
        } else {
            if !day.targetExercisesDescription.contains(exercise) {
                day.targetExercisesDescription += ", \(exercise)"
            }
        }
    }
}
