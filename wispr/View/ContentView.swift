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

struct Logo: View {
    var body: some View {
        Image("Logo")
            .resizable()
            .scaledToFit()
            .frame(width: 18, height: 18)
    }
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(ThemeStateService.self) private var theme: ThemeStateService
    @State var globals: Globals = .init()
    @State var navigationStateService: NavigationStateService = .init()
    @State var bookState: BookStateService = .init()
    @State var dayState: DayStateService = .init()
    @State var flashService: FlashStateService = .init()
    @State var calendarSyncService: CalendarSyncService = .init()

    @Namespace var animation

    @State var timelineLoaded: Bool = false
    @State var selectedDate: Date = Calendar.current.startOfDay(for: Date())

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

    func consolidateAndFillDays(in context: ModelContext) async {
        do {
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            let allDays = DayStore.loadDays()

            let grouped = Dictionary(grouping: allDays) {
                calendar.startOfDay(for: $0.date)
            }
            var uniqueDays: [Date: Day] = [:]

            for (date, duplicates) in grouped {
                let primary = duplicates.first!
                for dup in duplicates.dropFirst() {
                    primary.items.append(contentsOf: dup.items)
                    context.delete(dup)
                }
                uniqueDays[date] = primary
            }

            for offset in -365 ... 365 {
                let date = calendar.date(
                    byAdding: .day,
                    value: offset,
                    to: today
                )!
                let startOfDay = calendar.startOfDay(for: date)
                if uniqueDays[startOfDay] == nil {
                    let newDay = DayStore.createBlank(startOfDay)
                    context.insert(newDay)
                    uniqueDays[startOfDay] = newDay
                }
            }

            try context.save()
        } catch {
            print("Error consolidating and filling days: \(error)")
        }
    }

    @Query var books: [Book]
    @State var activeDate: Date? = Calendar.current.startOfDay(for: Date())

    @State var showSheet: Bool = true
    @State var showArchive: Bool = false

    @Query(filter: #Predicate<Item> { $0.parent != nil }) var children: [Item]
    @Query() var allItems: [Item]

    @State var mainID: UUID = .init()

    @State var selectedPath: Path? = .timelineScreen
    @State var mainPath: Path = .timelineScreen

    var body: some View {
        NavigationStack {
            VStack {
                if let book = bookState.book {
                    TestBookScreen(book: book)
                } else {
                    if timelineLoaded {
                        HorizontalTimelineScreen(
                            animation: animation,
                            selectedDate: $selectedDate,
                            activeDate: $activeDate
                        )
                        .tag(Path.timelineScreen)
                    } else {
                        Spacer()
                        HStack {
                            Spacer()
                            ProgressView()
                                .progressViewStyle(.circular)
                            Spacer()
                        }
                        Spacer()
                    }
                }
            }
            .overlay {
                flashService.flashMessage
            }
            .tabViewStyle(.page)
            .background(RandomMeshBackground(color: .white))
            .id(Path.timelineScreen)
            .toolbar {
                ToolbarItemGroup(
                    placement: .bottomBar
                ) {
                    Tool(
                        animation: animation,
                        selectedPath: $selectedPath,
                        selectedDate: $selectedDate,
                        activeDate: $activeDate,
                    )
                }
            }
        }
        .scrollIndicators(.hidden)
        .scrollContentBackground(.hidden)
        .environment(globals)
        .environment(navigationStateService)
        .environment(dayState)
        .environment(bookState)
        .environment(navigationStateService.shelfState)
        .environment(flashService)
        .environment(calendarSyncService)
        .task {
            await calendarSyncService.sync()
            await deleteEmptyItems(in: modelContext)
            await consolidateAndFillDays(in: modelContext)

            withAnimation {
                timelineLoaded = true
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
            RandomMeshBackground(
                color: theme.activeTheme
                    .defaultBackgroundColor
            )
        }
        .allowsHitTesting(false)
    }
}

struct RandomMeshBackground: View {
    @Environment(ThemeStateService.self) private var theme: ThemeStateService
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
        .overlay(theme.activeTheme.backgroundMaterialOverlay)
        .ignoresSafeArea()
    }
}
