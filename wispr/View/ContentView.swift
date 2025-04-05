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

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(ThemeStateService.self) private var theme: ThemeStateService

    @State var navigationStateService: NavigationStateService = .init()
    @State var flashService: FlashStateService = .init()
    @State var calendarSyncService: CalendarSyncService = .init()
    @Namespace var namespace

    @State var editMode: EditMode = .inactive
    @State var showShelf: Bool = false

    @Query(
        filter: ItemStore.allActiveItemsPredicate(),
        sort: \.position
    )
    var items: [Item]

    @State var dayItems: [Item] = []

    var dayEvents: [Item] {
        dItems.filter {
            if
                let e =
                $0.eventData
            {
                return e.allDay
            } else {
                return false
            }
        }
    }

    @State var timelineLoaded: Bool = false
    @State var dayLoaded: Bool = false

    var path: [Path] {
        navigationStateService.pathState.path
    }

    var date: Date {
        navigationStateService.activeDate
    }

    var tab: Path {
        navigationStateService.pathState.tab
    }

    var bookFilter: Book? {
        navigationStateService.bookState.book
    }

    var chapterFilter: Tag? {
        navigationStateService.bookState.chapter
    }

    var dItems: [Item] {
        let i = try? items.filter(
            ItemStore
                .activeItemsPredicated(
                    for: navigationStateService
                        .activeDate
                )
        )

        return i ?? []
    }

    func loadTimeline() async {
        withAnimation {
            timelineLoaded = false
            dayLoaded = false
        }

        navigationStateService.setDays(await filterTimelineDays())
        withAnimation {
            timelineLoaded = true
        }
    }

    func filterTimelineDays() async -> [Date: [Item]] {
        let i = ItemStore.filterByBook(
            items: items,
            book: bookFilter
        )
        .sorted(by: {
            $0.timestamp < $1.timestamp && $0.position < $1.position
        })

        return Dictionary(
            grouping: i,
            by: {
                Calendar.current.startOfDay(for: $0.timestamp)
            }
        )
    }

    func loadDay() {
        withAnimation {
            dayLoaded = false
        }

        navigationStateService.setActiveDay(
            activeDay: loadActiveDay()
        )

        withAnimation {
            dayLoaded = true
        }
    }

    func loadActiveDay() -> ActiveDay {
        return .init(date: date, items: days[date] ?? [])
    }

    func load() {
        Task {
            await loadTimeline()
            loadDay()
        }
    }

    var activeDay: ActiveDay { navigationStateService.activeDay }
    var activeItems: [Item] { navigationStateService.activeDay.items }
    var days: [Date: [Item]] { navigationStateService.days }

    var body: some View {
        NavigationStack(path: $navigationStateService.pathState.path) {
            TabView(selection: $navigationStateService.pathState.tab) {
                Screen(
                    .timelineScreen,
                    loaded: timelineLoaded,
                    title: { Text("Timeline") }
                ) {
                    TimeLineScreen(days: days)
                }
                .tabItem {
                    Image(systemName: "text.line.magnify")
                }
                .tag(Path.timelineScreen)
                .toolbarBackground(.hidden)
                .animation(.smooth, value: timelineLoaded)

                Screen(
                    .dayScreen,
                    loaded: dayLoaded,
                    title: {
                        DateTitle(
                            date: date,
                            scrollTransition: false,
                            dateStringLeading: date
                                .formatted(
                                    date: .long,
                                    time: .omitted
                                )
                        )
                    },
                    trailingTitle: {
                        Text(
                            date.formatted(.dateTime.weekday(.wide))
                        )
                    },
                    subtitle: {
                        HStack(alignment: .firstTextBaseline) {
                            DateSubTitleLabel(
                                date: date
                            )
                            Spacer()

                            if dayEvents.isNotEmpty {
                                VStack(alignment: .trailing) {
                                    ForEach(dayEvents.sorted { first, second in
                                        first.text.count > second.text.count
                                    }) { item in
                                        Text(item.text)
                                    }
                                }
                            }
                        }
                    }
                ) {
                    DayScreen(items: activeDay.items, editMode: $editMode)
                }
                .tag(Path.dayScreen)
                .animation(.smooth, value: dayLoaded)
            }
            .animation(.smooth, value: tab)
            .animation(.smooth, value: date)
            .onChange(of: path.isEmpty) {
                if path.isEmpty {
                    load()
                }
            }
            .onChange(of: date) {
                loadDay()
            }
            .onChange(of: items) {
                load()
            }
            .onChange(of: bookFilter) {
                load()
                navigationStateService.shelfState.dismissShelf()
            }
            .navigationDestination(for: Path.self) { path in
                navigationStateService.destination(path)
                    .background(navigationStateService.background)
                    .toolbarBackground(.hidden)
            }
            .tabViewStyle(.page)
            .background(navigationStateService.background)
            .toolbar {
                ToolbarItemGroup(
                    placement: .bottomBar
                ) {
                    HStack {
                        Toolbar()
                    }
                }
            }
            .toolbarBackground(.hidden)
        }
        .toolbarBackground(.hidden)
        .scrollIndicators(.hidden)
        .scrollContentBackground(.hidden)
        .environment(navigationStateService)
        .environment(navigationStateService.bookState)
        .environment(navigationStateService.shelfState)
        .environment(flashService)
        .environment(calendarSyncService)
        .task {
            await calendarSyncService.sync()
            await loadTimeline()
            loadDay()
        }
    }
}

struct GlobalBackground: View {
    @Environment(ThemeStateService.self) private var theme: ThemeStateService
    @Environment(BookStateService.self) private var activeBook: BookStateService

    @State var topRight: CGFloat = .random(in: 0 ... 1)
    @State var topLeft: CGFloat = .random(in: 0 ... 1)
    @State var top: CGFloat = .random(in: 0 ... 1)

    @State var centerRight: CGFloat = .random(in: 0 ... 1)
    @State var centerLeft: CGFloat = .random(in: 0 ... 1)
    @State var center: CGFloat = .random(in: 0 ... 1)

    @State var bottomRight: CGFloat = .random(in: 0 ... 1)
    @State var bottomLeft: CGFloat = .random(in: 0 ... 1)

    var body: some View {
        VStack {
            if let book = activeBook.book {
                book.globalBackground
            } else {
                MeshGradient(width: 3, height: 3, points: [
                    [0, 0], [0, 0.5], [0, 1],
                    [0.5, 0], [0.5, 0.5], [0.5, 1],
                    [1, 0], [1, 0.5], [1, 1],
                ], colors: [
                    theme.activeTheme.defaultBackgroundColor
                        .opacity(topRight),
                    theme.activeTheme.defaultBackgroundColor
                        .opacity(topLeft),
                    theme.activeTheme.defaultBackgroundColor
                        .opacity(top),
                    theme.activeTheme.defaultBackgroundColor
                        .opacity(center),
                    theme.activeTheme.defaultBackgroundColor
                        .opacity(centerLeft),
                    theme.activeTheme.defaultBackgroundColor,
                    theme.activeTheme.defaultBackgroundColor
                        .opacity(centerRight),
                    theme.activeTheme.defaultBackgroundColor
                        .opacity(bottomLeft),
                    theme.activeTheme.defaultBackgroundColor
                        .opacity(bottomRight),
                ])
                .blur(radius: 30)
            }
        }
        .overlay(theme.activeTheme.backgroundMaterialOverlay)
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}
