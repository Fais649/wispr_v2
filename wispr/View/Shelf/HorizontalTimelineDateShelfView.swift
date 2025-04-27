
//
//  BaseDateShelfView.swift
//  wispr
//
//  Created by Faisal Alalaiwat on 29.03.25.
//
import EventKit
import SwiftData
import SwiftUI

struct HorizontalTimelineDateShelfView: View {
    @Environment(\.modelContext) private var modelContext: ModelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(NavigationStateService.self) private var navigationStateService
    @Environment(DayStateService.self) private var dayState
    @Environment(CalendarSyncService.self) private var calendarSyncService
    @Environment(ThemeStateService.self) private var theme: ThemeStateService
    @State var showCalendarShelf: Bool = false
    @State var loaded: Bool = false

    @State var eventCalendars: [String: [EventCalendar]] = [:]
    @Binding var selectedDate: Date
    @Binding var show: Bool

    var todayDate: Date {
        Calendar.current.startOfDay(for: Date())
    }

    func title() -> some View {
        Text("Date")
    }

    var body: some View {
        Screen(
            .dateShelf,
            title: title
        ) {
            DatePicker(
                "",
                selection: $selectedDate,
                displayedComponents: [.date]
            )
            .onChange(of: selectedDate) {
                dismiss()
            }
            .datePickerStyle(GraphicalLikeDatePickerStyle())
            .tint(theme.activeTheme.backgroundMaterialOverlay)
        }
        .shelfScreenStyle([.fraction(0.64)])
    }
}
