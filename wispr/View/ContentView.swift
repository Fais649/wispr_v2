//
//  ContentView.swift
//  wispr
//
//  Created by Faisal Alalaiwat on 10.01.25.
//
import NavigationTransitions
import SwiftData
import SwiftUI

struct ActiveDay {
    var date: Date = .init()
    var items: [Item] = []
}

@Observable
class Globals {}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext

    @Environment(ThemeStateService.self) private var theme: ThemeStateService
    @State var globals: Globals = .init()
    @State var navigationStateService: NavigationStateService = .init()
    @State var dayState: DayStateService = .init()
    @State var flashService: FlashStateService = .init()
    @State var calendarSyncService: CalendarSyncService = .init()

    @Namespace var animation

    @State var editMode: EditMode = .inactive
    @State var showShelf: Bool = false

    @State var timelineLoaded: Bool = false
    @State var dayLoaded: Bool = false

    @Query() var days: [Day]

    var path: [Path] {
        navigationStateService.pathState.path
    }

    var date: Date {
        dayState.active.date
    }

    var tab: Path {
        navigationStateService.pathState.tab
    }

    var bookFilter: Book? {
        navigationStateService.bookState.book
    }

    func load() {
        withAnimation {
            timelineLoaded = false
        }

        withAnimation {
            timelineLoaded = true
        }
    }

    func deleteEmptyItems(in context: ModelContext) async {
        do {
            let items = ItemStore.loadItems()
            for item in items {
                if item.text.isEmpty {
                    modelContext.delete(item)
                }
            }

            try context.save()
        } catch {
            print("Error deleting empty items: \(error)")
        }
    }

    func consolidateDuplicateDays(in context: ModelContext) async {
        do {
            let calendar = Calendar.current
            let days = DayStore.loadDays()
            let groupedDays = Dictionary(grouping: days) { day in
                calendar.startOfDay(for: day.date)
            }

            for (_, duplicates) in groupedDays {
                guard duplicates.count > 1 else { continue }

                let primary = duplicates.first!
                for duplicate in duplicates.dropFirst() {
                    primary.items.append(contentsOf: duplicate.items)
                    context.delete(duplicate)
                }
            }

            try context.save()
        } catch {
            print("Error consolidating duplicates: \(error)")
        }
    }

    @State var dragOffset: CGFloat = 0
    @State var xdragOffset: CGFloat = 0

    @State var showDateShelf: Bool = false
    @State var showBookShelf: Bool = false
    var showDayOverlay: Bool {
        activeDay != nil
    }

    @State var firstLoad: Bool = true
    @State var showVerticalTimeline: Bool = false
    @State var active: Date? = Calendar.current.startOfDay(for: Date())
    @State var selectedDate: Date = Calendar.current.startOfDay(for: Date())
    @State var activeDay: Day? = nil

    var onForm: Bool {
        navigationStateService.pathState.onForm
    }

    var onBookForm: Bool {
        navigationStateService.pathState.onBookForm
    }

    var bookShelfShown: Bool {
        navigationStateService.shelfState.isBook()
    }

    var isToday: Bool {
        dayState.isTodayActive()
    }

    var book: Book? {
        navigationStateService.bookState.book
    }

    var chapter: Chapter? {
        navigationStateService.bookState.chapter
    }

    var noFilter: Bool {
        book == nil && isToday
    }

    @State var showMonth: Bool = false
    @State var yOffset: CGFloat = 0

    var body: some View {
        NavigationStack(path: $navigationStateService.pathState.path) {
            VStack {
                if timelineLoaded {
                    VStack {
                        HorizontalTimelineScreen(
                            animation: animation,
                            activeDay: $activeDay,
                            selectedDate: $selectedDate,
                            showDateShelf: $showDateShelf,
                            showBookShelf: $showBookShelf,
                            active: $active
                        )
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
            }.overlay {
                flashService.flashMessage
            }
            .navigationDestination(for: Path.self) { path in
                navigationStateService.destination(animation, path)
                    .background(navigationStateService.background)
            }
            .tabViewStyle(.page)
            .background(navigationStateService.background)
        }
        .toolbarBackground(.ultraThinMaterial)
        .toolbarBackgroundVisibility(.visible)
        .scrollIndicators(.hidden)
        .scrollContentBackground(.hidden)
        .environment(globals)
        .environment(navigationStateService)
        .environment(dayState)
        .environment(navigationStateService.bookState)
        .environment(navigationStateService.shelfState)
        .environment(flashService)
        .environment(calendarSyncService)
        .task {
            await calendarSyncService.sync()
            await deleteEmptyItems(in: modelContext)
            await consolidateDuplicateDays(in: modelContext)

            withAnimation {
                timelineLoaded = true
                dayLoaded = true
            }
        }
    }
}

struct VerticalMonthTimelineScreen: View {
    @Environment(\.modelContext) private var modelContext: ModelContext
    @State private var selectedMonth: Date = Calendar.current
        .startOfDay(for: Date())

    var animation: Namespace.ID

    @Binding var shown: Bool
    @Binding var selectedDate: Date

    var monthDates: [Date] {
        guard
            let monthInterval = Calendar.current.dateInterval(
                of: .month,
                for: selectedMonth
            ) else { return [] }
        return Calendar.current.generateDates(inside: monthInterval)
    }

    var body: some View {
        VStack(spacing: 0) {
            let columns = Array(repeating: GridItem(.flexible()), count: 7)
            HStack {
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
            .padding(.horizontal)

            LazyVGrid(columns: columns, spacing: 8) {
                let firstWeekday = Calendar.current.component(
                    .weekday,
                    from: monthDates.first ?? Date()
                ) - 1

                ForEach(0 ..< firstWeekday, id: \.self) { _ in
                    Color.clear.frame(height: 60)
                }

                ForEach(monthDates, id: \.self) { date in
                    let day = DayStore.loadDay(by: date) ?? DayStore
                        .createBlank(date)

                    Button(action: {
                        let d = DayStore.loadDay(by: date) ??
                            DayStore.createBlank(date)

                        selectedDate = d.date
                        withAnimation {
                            shown = false
                        }
                    }) {
                        VStack {
                            Text(Calendar.current.component(
                                .day,
                                from: date
                            ).description)
                                .font(.caption)
                                .frame(maxWidth: .infinity)
                                .padding(4)

                            DayCell(
                                animation: animation,
                                day: day,
                                backgroundOpacity: 0
                            )
                        }
                        .background {
                            if
                                Calendar.current.isDate(
                                    date,
                                    inSameDayAs: selectedDate
                                )
                            {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(.ultraThinMaterial)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .id(date)
                    .aspectRatio(
                        CGSize(width: 1, height: 1),
                        contentMode: .fit
                    )
                }
            }
            .padding(.horizontal)

            HStack {
                Button(action: { shiftMonth(by: -1) }) {
                    Image(systemName: "chevron.left")
                }
                Spacer()
                Text(selectedMonth, formatter: monthYearFormatter)
                    .font(.headline)
                Spacer()
                Button(action: { shiftMonth(by: 1) }) {
                    Image(systemName: "chevron.right")
                }
            }
            .padding()
        }
    }

    private func shiftMonth(by value: Int) {
        if
            let newDate = Calendar.current.date(
                byAdding: .month,
                value: value,
                to: selectedMonth
            )
        {
            selectedMonth = newDate
        }
    }

    private var monthYearFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "LLLL yyyy"
        return formatter
    }
}

struct GlobalBackground: View {
    @Environment(ThemeStateService.self) private var theme: ThemeStateService
    @Environment(
        NavigationStateService
            .self
    ) private var navigationStateService: NavigationStateService
    @Environment(BookStateService.self) private var activeBook: BookStateService

    var body: some View {
        VStack {
            if let bg = navigationStateService.tempBackground {
                bg()
            } else if let book = activeBook.book {
                book.globalBackground
            } else {
                RandomMeshBackground(
                    color: theme.activeTheme
                        .defaultBackgroundColor
                )
            }
        }
        .overlay(theme.activeTheme.backgroundMaterialOverlay)
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

struct RandomMeshBackground: View {
    @State var topRight: CGFloat = .random(in: 0 ... 1)
    @State var topLeft: CGFloat = .random(in: 0 ... 1)
    @State var top: CGFloat = .random(in: 0 ... 1)

    @State var centerRight: CGFloat = .random(in: 0 ... 1)
    @State var centerLeft: CGFloat = .random(in: 0 ... 1)
    @State var center: CGFloat = .random(in: 0 ... 1)

    @State var bottomRight: CGFloat = .random(in: 0 ... 1)
    @State var bottomLeft: CGFloat = .random(in: 0 ... 1)

    var color: Color

    var body: some View {
        MeshGradient(width: 3, height: 3, points: [
            [0, 0], [0, 0.5], [0, 1],
            [0.5, 0], [0.5, 0.5], [0.5, 1],
            [1, 0], [1, 0.5], [1, 1],
        ], colors: [
            color.opacity(topRight),
            color.opacity(topLeft),
            color.opacity(top),
            color.opacity(center),
            color.opacity(centerLeft),
            color,
            color.opacity(centerRight),
            color.opacity(bottomLeft),
            color.opacity(bottomRight),
        ])
        .blur(radius: 30)
    }
}
