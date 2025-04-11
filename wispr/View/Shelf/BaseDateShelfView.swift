//
//  BaseDateShelfView.swift
//  wispr
//
//  Created by Faisal Alalaiwat on 29.03.25.
//
import EventKit
import SwiftData
import SwiftUI

struct BaseDateShelfView: View {
    @Environment(\.modelContext) private var modelContext: ModelContext
    @Environment(NavigationStateService.self) private var navigationStateService
    @Environment(DayStateService.self) private var dayState
    @Environment(CalendarSyncService.self) private var calendarSyncService
    @Environment(ThemeStateService.self) private var theme: ThemeStateService
    @State var showCalendarShelf: Bool = false
    @State var loaded: Bool = false

    @State var eventCalendars: [String: [EventCalendar]] = [:]
    @State var selectedDate: Date = .init()
    @Query() var days: [Day]

    func title() -> some View {
        Text("Date")
    }

    var body: some View {
        Screen(
            .dateShelf,
            loaded: true,
            title: title
        ) {
            DatePicker(
                "",
                selection: $selectedDate,
                displayedComponents: [.date]
            )
            .datePickerStyle(.graphical)
            .tint(theme.activeTheme.backgroundMaterialOverlay)
            HStack(spacing: Spacing.l) {
                ToolbarButton {
                    dayState.yesterday()
                    navigationStateService.shelfState.dismissShelf()
                } label: {
                    Text("Yesterday")
                }

                ToolbarButton {
                    dayState.setTodayActive()
                    navigationStateService.shelfState.dismissShelf()
                } label: {
                    Text("Today")
                }

                ToolbarButton {
                    dayState.tomorrow()
                    navigationStateService.shelfState.dismissShelf()
                } label: {
                    Text("Tomorrow")
                }
            }.padding(Spacing.m)
        }
        .task {
            selectedDate = dayState.active.date
        }
        .padding(.top, Spacing.m)
        .onChange(of: selectedDate) {
            if selectedDate != dayState.active.date {
                if let d = DayStore.loadDay(from: days, by: selectedDate) {
                    dayState.setActive(d)
                } else {
                    dayState.setActive(DayStore.createBlank(selectedDate))
                }

                navigationStateService.shelfState.dismissShelf()
            }
        }
    }
}
