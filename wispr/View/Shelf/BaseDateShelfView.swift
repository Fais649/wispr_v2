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
    @Environment(CalendarSyncService.self) private var calendarSyncService
    @Environment(ThemeStateService.self) private var theme: ThemeStateService
    @State var showCalendarShelf: Bool = false
    @State var loaded: Bool = false

    @State var eventCalendars: [String: [EventCalendar]] = [:]

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
                selection:
                Bindable(navigationStateService).activeDate,
                displayedComponents: [.date]
            )
            .datePickerStyle(.graphical)
            .tint(theme.activeTheme.backgroundMaterialOverlay)
        }
        .padding(.top, Spacing.m)
        .onChange(of: navigationStateService.activeDate) {
            navigationStateService.shelfState.dismissShelf()
        }
    }
}

struct BaseDateShelfLabelView: View {
    @Environment(ThemeStateService.self) private var theme: ThemeStateService
    @Environment(
        NavigationStateService
            .self
    ) var navigationStateService: NavigationStateService
    @State var showTodayButton: Bool = false

    var dateShelfShown: Bool {
        navigationStateService.shelfState.isDatePicker()
    }

    var body: some View {
        HStack {
            if showTodayButton {
                ToolbarButton(
                    toggledOn: dateShelfShown
                ) {
                    navigationStateService.goToToday()
                } label: {
                    Image(systemName: "asterisk")
                }
            }

            ToolbarButton(
                toggledOn: dateShelfShown
            ) {
                navigationStateService.toggleDatePickerShelf()
            } label: {
                Image(systemName: "calendar")
            }
            .onChange(of: navigationStateService.activePath) {
                if navigationStateService.onForm {
                    withAnimation {
                        navigationStateService.closeShelf()
                    }
                }
            }
            .onChange(of: navigationStateService.activeDate) {
                withAnimation {
                    navigationStateService.closeShelf()
                    showTodayButton = !navigationStateService.isTodayActive
                }
            }
        }.onAppear {
            withAnimation {
                showTodayButton = !navigationStateService.isTodayActive
            }
        }
        .background {
            if !navigationStateService.isTodayActive {
                Capsule().fill(theme.activeTheme.backgroundMaterialOverlay)
                    .blur(radius: dateShelfShown ? 50 : 0)
                    .blendMode(.luminosity)
            }
        }
    }
}
