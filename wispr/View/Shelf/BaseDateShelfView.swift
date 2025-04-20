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

        .presentationDetents([.fraction(0.64)])
        .presentationCornerRadius(0)
        .presentationBackground {
            Rectangle().fill(
                theme.activeTheme
                    .backgroundMaterialOverlay
            )
            .fade(
                from: .bottom,
                fromOffset: 0.6,
                to: .top,
                toOffset: 1
            )
        }
        .padding(.horizontal, Spacing.m)
        .containerRelativeFrame([.horizontal, .vertical])
    }
}

struct GraphicalLikeDatePickerStyle<MultiDateSelector: View>: DatePickerStyle {
    init(
        onChangeComponents: (() -> Void)? = nil,
        timeShown: (() -> Bool)? = nil,
        @ViewBuilder multiDateSelector: @escaping ()
            -> MultiDateSelector = { EmptyView() }
    ) {
        self.onChangeComponents = onChangeComponents
        self.timeShown = timeShown
        self.multiDateSelector = multiDateSelector
    }

    @Namespace var animation
    var onChangeComponents: (() -> Void)? = nil
    var timeShown: (() -> Bool)? = nil

    var multiDateSelector: () -> MultiDateSelector

    @State private var displayDate: Date = Calendar.current.startOfDay(
        for:
        Date()
    )

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
                .task {
                    proxy.scrollTo(
                        Calendar.current.dateComponents(
                            [.month, .year],
                            from: configuration.selection
                        )
                    )
                    displayDate = Calendar.current
                        .startOfDay(for: configuration.selection)
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.viewAligned)
        }

        if configuration.displayedComponents.contains(.hourAndMinute) {
            DatePicker(
                "",
                selection: Binding(
                    get: { configuration.selection },
                    set: { configuration.selection = $0 }
                ),
                displayedComponents: .hourAndMinute
            )
            .datePickerStyle(.wheel)
            .labelsHidden()
            .frame(maxHeight: 80)
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }

        Divider()

        HStack {
            if let onChangeComponents {
                ToolbarButton {
                    onChangeComponents()
                } label: {
                    if let timeShown {
                        Image(
                            systemName: timeShown() ?
                                "clock.badge.xmark.fill" :
                                "clock"
                        )
                    } else {
                        Image(systemName: "clock")
                    }
                }
            }

            if let timeShown, timeShown() {
                multiDateSelector()
                    .matchedGeometryEffect(
                        id: "datePickerBottomRow",
                        in: animation,
                        isSource: false
                    )
            } else {
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
                .matchedGeometryEffect(
                    id: "datePickerBottomRow",
                    in: animation,
                    isSource: true
                )
            }
        }
        .frame(maxHeight: Spacing.l)
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

    @Environment(
        BookStateService
            .self
    ) private var bookState: BookStateService

    @Query var days: [Day]

    let displayDate: Date
    let configuration: DatePickerStyleConfiguration

    @State private var dates: [Date] = []
    @State var daysOfMonth: [Day] = []
    @State var loaded: Bool = false

    func loadDates() async {
        guard
            let monthInterval = Calendar.current.dateInterval(
                of: .month,
                for: displayDate
            )
        else {
            dates = []
            return
        }

        dates = Calendar.current.generateDates(inside: monthInterval)
    }

    func loadDaysOfMonth() async {
        await loadDates()
        daysOfMonth = days.filter {
            dates.contains($0.date)
        }
        .sorted(by: { $0.date < $1.date })
    }

    var body: some View {
        let firstWeekday = Calendar.current.component(
            .weekday,
            from: dates.first ?? Date()
        ) - 1

        VStack {
            if loaded {
                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible()), count: 7),
                    spacing: 4
                ) {
                    ForEach(0 ..< firstWeekday, id: \.self) { _ in
                        Text(" ")
                    }

                    ForEach(daysOfMonth, id: \.self) { day in
                        DateButton(
                            day: day,
                            book: bookState.book,
                            chapter: bookState.chapter,
                            configuration: configuration
                        )
                    }
                }
            } else {
                Spacer()
                HStack {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(.circular)
                        .toolbarBackground(.hidden)
                        .toolbarBackgroundVisibility(.hidden)
                        .toolbarVisibility(.hidden)
                    Spacer()
                }
                Spacer()
            }
        }
        .task {
            await loadDaysOfMonth()
            withAnimation {
                loaded = true
            }
        }
    }

    struct DateButton: View {
        let day: Day
        let book: Book?
        let chapter: Chapter?

        var date: Date {
            day.date
        }

        let configuration: DatePickerStyleConfiguration

        @State var parentItems: [Item] = []
        @State var loaded: Bool = false

        func loadParentItems() async {
            if let book {
                if let chapter {
                    parentItems = day.parentItems
                        .filter { $0.chapter == chapter }
                        .sorted(by: { $0.position < $1.position })
                }

                parentItems = day.parentItems.filter { $0.book == book }
                    .sorted(by: { $0.position < $1.position })
            } else {
                parentItems = day.parentItems
            }
        }

        var body: some View {
            Button(action: {
                configuration.selection = Calendar.current
                    .combineDateAndTime(
                        date: date,
                        time: configuration.selection
                    )
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
                            loaded
                                && parentItems.isEmpty
                                && !Calendar.current.isDate(
                                    date,
                                    inSameDayAs: configuration.selection
                                )
                                ? 0.7 : 1
                        )

                    HStack {
                        Spacer()
                        if loaded {
                            ForEach(parentItems.prefix(3)) { item in
                                Image(systemName: "circle.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 4, height: 4)
                                    .foregroundStyle(item.shadowTint)
                            }
                        } else {
                            EmptyView()
                        }
                        Spacer()
                    }
                    .frame(height: 4)
                }
            }
            .buttonStyle(.plain)
            .task {
                await loadParentItems()
                withAnimation {
                    loaded = true
                }
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
