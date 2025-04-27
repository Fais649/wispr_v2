
//
//  HorizontalTimelineScreen.swift
//  wispr
//
//  Created by Faisal Alalaiwat on 21.03.25.
//
import SwiftData
import SwiftUI

struct HorizontalTimelineScreen: View {
    @Environment(\.modelContext) private var modelContext: ModelContext
    @Environment(Globals.self) private var globals: Globals
    @Environment(ThemeStateService.self) private var theme: ThemeStateService
    @Environment(DayStateService.self) private var dayState: DayStateService
    @Environment(BookStateService.self) private var bookState: BookStateService
    @Environment(
        NavigationStateService
            .self
    ) private var navigationStateService: NavigationStateService

    // @Environment(\.horizontalSizeClass) var horizontalSizeClass
    //
    // var isLandscape: Bool {
    //     horizontalSizeClass == .regular
    // }

    @Query var days: [Day]

    var animation: Namespace.ID

    @Binding var selectedDate: Date
    @Binding var activeDate: Date?

    let today = Calendar.current.startOfDay(for: Date())

    var book: Book? {
        bookState.book
    }

    var sortedBooks: [Book] {
        books.sorted(by: {
            if
                let firstClick = $0.lastClicked,
                let secondClick = $1.lastClicked
            {
                return firstClick > secondClick
            } else {
                return $0.timestamp < $1.timestamp
            }
        })
    }

    var chapter: Chapter? {
        bookState.chapter
    }

    @Query var books: [Book]
    var body: some View {
        TabView(selection: $activeDate) {
            ForEach(
                days.sorted(by: { $0.date < $1.date }),
                id: \.date
            ) { day in
                DayScreen(
                    animation: animation,
                    day: day,
                    backgroundOpacity: day.date < today ? 0 : 0.5
                )
                .tag(day.date)
                .opacity(day.date < today ? 0.8 : 1)
                // .matchedGeometryEffect(
                //     id: day.date,
                //     in: animation,
                //     isSource: true
                // )
                .padding(Spacing.s)
                .containerRelativeFrame(
                    [.horizontal],
                    count: 1,
                    span: 1,
                    spacing: 0
                )
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .id("timeline")
        .task {
            let d = await DayStore.loadOrCreate(by: activeDate ?? selectedDate)
            activeDate = d.date
        }
        .onChange(of: selectedDate) {
            let d = Calendar.current
                .startOfDay(for: selectedDate)

            if d != activeDate {
                withAnimation {
                    activeDate = d
                }
            }
        }
    }

    @ViewBuilder
    func sectionHeader(
        _ key: Date,
        allDayEvents: [Item],
        notAllDayItems _: [Item]
    ) -> some View {
        AniButton(padding: 0) {
            dayState.setActive(by: key)
        } label: {
            DateTitleWithDivider(
                date: key,
                trailing: {
                    AnyView(
                        DateTrailingTitleLabel(date: key)
                            .childItem()
                            .fontWeight(.light)
                    )
                },
                subtitle: {
                    AnyView(
                        VStack {
                            ForEach(
                                allDayEvents
                                    .sorted { first, second in
                                        first.text.count > second
                                            .text
                                            .count
                                    }
                            ) { item in
                                HStack {
                                    Text(item.text)
                                        .childItem()
                                        .fontWeight(.ultraLight)
                                        .lineLimit(1)
                                        .truncationMode(.tail)
                                        .multilineTextAlignment(
                                            .leading
                                        )
                                    Spacer()
                                }
                            }
                        }
                    )
                }
            )
        }
        .parentItem()
        .fontWeight(.bold)
    }
}

struct VisibleDayPreferenceKey: PreferenceKey {
    static var defaultValue: [Date: CGFloat] = [:]
    static func reduce(
        value: inout [Date: CGFloat],
        nextValue: () -> [Date: CGFloat]
    ) {
        value.merge(nextValue()) { $1 }
    }
}

struct Tool: View {
    @Environment(
        NavigationStateService
            .self
    ) private var navigationStateService: NavigationStateService
    @Environment(
        BookStateService
            .self
    ) private var bookState: BookStateService

    @Environment(
        ThemeStateService
            .self
    ) private var theme: ThemeStateService

    @Query(
        filter: #Predicate<Item> { item in item.archived },
        sort: \Item.timestamp, order: .reverse
    ) var archivedItems: [Item]

    var animation: Namespace.ID

    @Binding var selectedPath: Path?
    @Binding var selectedDate: Date
    @Binding var activeDate: Date?
    var todayDate: Date {
        Calendar.current.startOfDay(for: Date())
    }

    @State var showSettingShelf: Bool = false
    @State var showDateShelf: Bool = false
    @State var showBookShelf: Bool = false
    @State var showArchiveShelf: Bool = false

    var isToday: Bool {
        selectedDate == todayDate
    }

    var onForm: Bool {
        if case .bookForm = selectedPath {
            return true
        }
        if case .itemForm = selectedPath {
            return true
        }
        return false
    }

    var onBookForm: Bool {
        if case .bookForm = selectedPath {
            return true
        }
        return false
    }

    var book: Book? {
        bookState.book
    }

    var chapter: Chapter? {
        bookState.chapter
    }

    @State var showNewItemSheet: Bool = false

    var body: some View {
        HStack {
            ToolbarButton {
                // withAnimation {
                //     selectedPath = Path.none
                // }
                showSettingShelf.toggle()
            } label: {
                Logo()
            }.sheet(isPresented: $showSettingShelf) {
                BaseSettingShelfView()
            }

            if !onBookForm {
                BookShelfButton(
                    book: Bindable(bookState).book,
                    chapter: Bindable(bookState).chapter
                ) {
                    BaseBookShelfView()
                }

                DateShelfButton(date: $selectedDate) {
                    HorizontalTimelineDateShelfView(
                        selectedDate: $selectedDate,
                        show: $showDateShelf
                    )
                }
            }

            Spacer()

            if !onForm {
                ToolbarButton {
                    showArchiveShelf.toggle()
                } label: {
                    Image(
                        systemName: archivedItems
                            .isEmpty ? "archivebox.circle" :
                            "archivebox.circle.fill"
                    )
                    .fontWeight(.black)
                }
                .sheet(isPresented: $showArchiveShelf) {
                    BaseArchiveShelfView(
                        animation: animation,
                        timestamp: activeDate ?? todayDate,
                        book: book,
                        chapter: chapter
                    )
                }
            }

            ToolbarButton {
                navigationStateService.addItem = (
                    true,
                    activeDate ?? selectedDate
                )
            } label: {
                Image(systemName: "plus.circle.fill")
                    .fontWeight(.black)
            }
        }
        .padding(Spacing.m)
        .clipShape(Capsule())
    }
}
