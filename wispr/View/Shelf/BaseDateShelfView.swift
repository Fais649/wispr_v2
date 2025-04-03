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
        Text(showCalendarShelf ? "Calendars" : "Date")
    }

    func calendarButton() -> some View {
        AniButton {
            showCalendarShelf.toggle()
        } label: {
            Image(
                systemName: showCalendarShelf ? "calendar.circle.fill" :
                    "calendar"
            )
        }
    }

    var body: some View {
        Screen(.dateShelf, title: title, trailingTitle: calendarButton) {
            ScrollView {
                LazyVStack(pinnedViews: [.sectionHeaders]) {
                    if showCalendarShelf {
                        if loaded {
                            ForEach(
                                eventCalendars
                                    .sorted(by: { $0.key < $1.key }),
                                id: \.key
                            ) { key, calendars in
                                Section(
                                    header:
                                    HStack {
                                        Text(key)
                                        Spacer()
                                    }
                                    .childItem()
                                    .scrollTransition(Spacing.none)
                                ) {
                                    ForEach(calendars) { calendar in
                                        AniButton {
                                            calendar.enabled.toggle()
                                            Task {
                                                if calendar.enabled {
                                                    await calendarSyncService.sync(for: calendar)
                                                } else {
                                                    await EventCalendarStore.deleteAllItems(for: calendar)
                                                }
                                            }
                                        } label: {
                                            HStack {
                                                Image(
                                                    systemName: calendar
                                                        .enabled ?
                                                        "circle.fill" :
                                                        "circle.dotted"
                                                )
                                                Text(calendar.name)
                                                Spacer()
                                            }
                                        }
                                        .contentShape(Rectangle())
                                        .parentItem()
                                        .scrollTransition(Spacing.m)
                                    }
                                }
                            }
                        } else {
                            ProgressView().progressViewStyle(.circular)
                                .task {
                                    await self.load()
                                }
                        }
                    } else {
                        DatePicker(
                            "",
                            selection: Bindable(navigationStateService)
                                .activeDate,
                            displayedComponents: [.date]
                        ).datePickerStyle(.graphical)
                            .tint(theme.activeTheme.backgroundMaterialOverlay)
                    }
                }
            }.scrollDisabled(!showCalendarShelf)
        }
    }

    func load() async {
        withAnimation {
            self.loaded = false
        }
        await loadCalendars()
        withAnimation {
            self.loaded = true
        }
    }

    func loadCalendars() async {
        await CalendarSyncService.syncCalendars()
        eventCalendars = EventCalendarStore.loadGroupedCalendars()
        loaded = true
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
