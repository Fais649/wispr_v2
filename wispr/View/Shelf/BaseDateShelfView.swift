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
            .datePickerStyle(GraphicalLikeDatePickerStyle())
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

struct GraphicalLikeDatePickerStyle: DatePickerStyle {
    @State private var displayDate: Date = Calendar.current.startOfDay(
        for:
        Date()
    )

    @State var hasScrolled: Bool = false

    private let months: [Date] = {
        let calendar = Calendar.current
        let startComponents = DateComponents(
            year: Calendar.current.component(.year, from: Date()) - 1,
            month: 1
        )
        let endComponents = DateComponents(
            year: Calendar.current.component(.year, from: Date()) + 1,
            month: 12
        )

        let startDate = calendar.date(from: startComponents)!
        let endDate = calendar.date(from: endComponents)!

        var dates: [Date] = []
        var current = startDate

        while current <= endDate {
            dates.append(current)
            current = calendar.date(byAdding: .month, value: 1, to: current)!
        }

        return dates
    }()

    func makeBody(configuration: Configuration) -> some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack {
                    ForEach(months, id: \.self) { month in
                        VStack {
                            Text(month, formatter: monthYearFormatter)
                                .font(.headline)
                                .padding(.vertical)

                            VStack {
                                HStack(alignment: .firstTextBaseline) {
                                    ForEach(
                                        Calendar.current.shortWeekdaySymbols,
                                        id: \.self
                                    ) { symbol in
                                        Text(symbol)
                                            .frame(maxWidth: .infinity)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }

                                CalendarView(
                                    displayDate: month,
                                    configuration: configuration
                                )
                            }

                            Spacer()
                        }
                        .id(
                            Calendar.current.dateComponents(
                                [.month, .year],
                                from: month
                            )
                        )
                        .containerRelativeFrame([.horizontal])
                    }
                }
                .scrollTargetLayout()
                .onAppear {
                    DispatchQueue.main.async {
                        proxy.scrollTo(
                            Calendar.current.dateComponents(
                                [.month, .year],
                                from: configuration.selection
                            )
                        )
                        displayDate = Calendar.current
                            .startOfDay(for: configuration.selection)
                    }
                }
            }
            .scrollTargetBehavior(.viewAligned)
        }

        Divider()

        HStack {
            ToolbarButton {
                configuration.selection = Date()
            } label: {
                HStack {
                    Spacer()
                    Text("Today")
                    Spacer()
                }
            }.contentShape(Rectangle())

            Divider()

            ToolbarButton {
                configuration.selection = Calendar.current
                    .date(
                        byAdding: .day,
                        value: 1,
                        to: Calendar.current.startOfDay(for: Date())
                    )!
            } label: {
                HStack {
                    Spacer()
                    Text("Tomorrow")
                    Spacer()
                }
            }.contentShape(Rectangle())

            Divider()

            ToolbarButton {
                configuration.selection = Calendar.current
                    .date(
                        byAdding: .day,
                        value: 7,
                        to:
                        Calendar.current.startOfDay(for: Date())
                    )!
            } label: {
                HStack {
                    Spacer()
                    Text("Next Week")
                    Spacer()
                }
            }
            .contentShape(Rectangle())
        }
        .frame(height: Spacing.l)
    }

    private func shiftDisplayMonth(by value: Int) {
        if
            let newDate = Calendar.current.date(
                byAdding: .month,
                value: value,
                to: displayDate
            )
        {
            withAnimation {
                displayDate = newDate
            }
        }
    }

    private func shiftMonth(configuration: Configuration, by value: Int) {
        if
            let newDate = Calendar.current.date(
                byAdding: .month,
                value: value,
                to: configuration.selection
            )
        {
            configuration.selection = newDate
        }
    }

    private var monthYearFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "LLLL yyyy"
        return formatter
    }
}

struct CalendarView: View {
    @Environment(
        NavigationStateService
            .self
    ) private var navigationStateService: NavigationStateService

    @Query var days: [Day]

    let displayDate: Date
    let configuration: DatePickerStyleConfiguration

    private var dates: [Date] {
        guard
            let monthInterval = Calendar.current.dateInterval(
                of: .month,
                for: displayDate
            )
        else {
            return []
        }
        return Calendar.current.generateDates(inside: monthInterval)
    }

    var filteredDays: [Day] {
        days
            .filter { day in
                if let book = navigationStateService.bookState.book {
                    if let chapter = navigationStateService.bookState.chapter {
                        return
                            day.items
                                .filter {
                                    $0.parent == nil && !$0.archived && $0.text
                                        .isNotEmpty
                                }
                                .contains { $0.chapter == chapter }
                    }

                    return
                        day.items
                            .filter {
                                $0.parent == nil && !$0.archived && $0.text
                                    .isNotEmpty
                            }
                            .contains { $0.book == book }
                } else {
                    return day.items
                        .filter {
                            $0.parent == nil && !$0.archived && $0.text
                                .isNotEmpty
                        }
                        .isNotEmpty
                }
            }
            .sorted(by: { $0.date < $1.date })
    }

    func parentItems(for date: Date) -> [Item] {
        if let d = DayStore.loadDay(from: filteredDays, by: date) {
            return d.parentItems
        }
        return []
    }

    var body: some View {
        let firstWeekday = Calendar.current.component(
            .weekday,
            from: dates.first ?? Date()
        ) - 1

        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible()), count: 7),
            spacing: 4
        ) {
            ForEach(0 ..< firstWeekday, id: \.self) { _ in
                Text(" ")
            }

            ForEach(dates, id: \.self) { date in
                Button(action: {
                    configuration.selection = date
                }) {
                    VStack {
                        Text("\(Calendar.current.component(.day, from: date))")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .padding(8)
                            .background {
                                if
                                    Calendar.current.isDate(
                                        date,
                                        inSameDayAs: configuration.selection
                                    )
                                {
                                    Circle()
                                        .fill(.white)
                                }
                            }

                            .foregroundStyle(
                                Calendar.current.isDate(
                                    date,
                                    inSameDayAs: configuration.selection
                                )
                                    ? AnyShapeStyle(.ultraThickMaterial) :
                                    AnyShapeStyle(.white)
                            )
                            .opacity(
                                parentItems(for: date).isEmpty
                                    && !Calendar.current.isDate(
                                        date,
                                        inSameDayAs: configuration.selection
                                    )
                                    ? 0.7 : 1
                            )

                        HStack {
                            Spacer()
                            ForEach(parentItems(for: date).prefix(3)) { item in
                                Image(systemName: "circle.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 4, height: 4)
                                    .foregroundStyle(item.shadowTint)
                            }
                            Spacer()
                        }
                        .frame(height: 4)
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }
}

extension Calendar {
    func generateDates(inside interval: DateInterval) -> [Date] {
        var dates: [Date] = []
        var current = interval.start
        while current < interval.end {
            dates.append(current)
            guard let next = date(byAdding: .day, value: 1, to: current)
            else { break }
            current = next
        }
        return dates
    }
}
