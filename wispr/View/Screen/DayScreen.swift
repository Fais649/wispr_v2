//
//  DayScreen.swift
//  wispr
//
//  Created by Faisal Alalaiwat on 21.03.25.
//
import SwiftData
import SwiftUI

struct DayCell: View {
    @Environment(\.modelContext) private var modelContext: ModelContext
    @Environment(
        NavigationStateService
            .self
    ) private var navigationStateService:
        NavigationStateService

    @Environment(
        BookStateService
            .self
    ) private var bookState: BookStateService

    @Environment(
        DayStateService
            .self
    ) private var dayState: DayStateService

    var animation: Namespace.ID

    var day: Day
    var backgroundOpacity: CGFloat = 0.5

    var parentItems: [Item] {
        day.items
            .filter { $0.parent == nil && !$0.archived && $0.text.isNotEmpty }
    }

    var dayEvents: [Item] {
        ItemStore.allDayEvents(from: parentItems)
    }

    var noAllDayEvents: [Item] {
        let items = ItemStore.filterAllDayEvents(from: parentItems)
        if let book = bookState.book {
            return items.filter { $0.book == book }
        }
        return items.sorted(by: { $0.position < $1.position })
    }

    func createGeometryID(date: Date, suffix: String) -> String {
        return date.hashValue.description + suffix
    }

    var bgRect: some Shape {
        RoundedRectangle(cornerRadius: 4)
    }

    @ViewBuilder
    func bg(_ item: Item) -> some View {
        bgRect
            .fill(.ultraThinMaterial)
            .overlay(
                bgRect
                    .fill(item.shadowTint)
                    .opacity(0.4)
                    .overlay {
                        HStack {
                            bgRect
                                .stroke(item.shadowTint.opacity(0.3))
                        }
                        .padding(Spacing.xs)
                        .blur(radius: 5)
                    }
            )
            .ignoresSafeArea()
    }

    var body: some View {
        VStack(alignment: .leading) {
            ForEach(noAllDayEvents) { item in
                HStack {
                    Text(item.text)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .font(.system(size: 10))
                    Spacer()
                }
                .background {
                    bg(item)
                }
            }
            Spacer()
        }
    }
}

struct DayScreen: View {
    @Environment(\.modelContext) private var modelContext: ModelContext
    @Environment(
        NavigationStateService
            .self
    ) private var navigationStateService:
        NavigationStateService

    @Environment(
        BookStateService
            .self
    ) private var bookState: BookStateService

    @Environment(
        DayStateService
            .self
    ) private var dayState: DayStateService

    var animation: Namespace.ID

    var date: Date
    var items: [Item]
    var scrollView: Bool = true
    var titleStyle: TitleStyle = .regular
    var backgroundOpacity: CGFloat = 0.5

    var book: Book? {
        bookState.book
    }

    var chapter: Chapter? {
        bookState.chapter
    }

    @State var allDayEvents: [Item] = []
    @State var parentItems: [Item] = []
    @State var loaded: Bool = false

    var body: some View {
        Screen(
            .dayScreen,
            loaded: true,
            title: {
                DateTrailingTitleLabel(
                    date: date
                )
            },
            titleStyle: titleStyle,
            trailingTitle: {
                Text(
                    date
                        .formatted(
                            .dateTime
                                .weekday(.wide)
                        )
                )
            },
            subtitle: {
                HStack {
                    DateTitle(
                        date: date,
                        scrollTransition: false,
                        dateStringLeading: date
                            .formatted(
                                date: .long,
                                time: .omitted
                            )
                    )
                    Spacer()
                }

            },
            backgroundOpacity: backgroundOpacity
        ) {
            VStack {
                if loaded {
                    if scrollView {
                        ScrollingItemList(
                            animation: animation,
                            dayEvents: allDayEvents,
                            noAllDayEvents: parentItems.filter {
                                if let book {
                                    if let chapter {
                                        return $0.chapter == chapter
                                    }

                                    return $0.book == book
                                }
                                return true
                            }
                        )
                    } else {
                        ItemList(
                            animation: animation,
                            dayEvents: allDayEvents,
                            noAllDayEvents: parentItems.filter {
                                if let book {
                                    if let chapter {
                                        return $0.chapter == chapter
                                    }

                                    return $0.book == book
                                }
                                return true
                            }
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
            }
            .onChange(of: items) {
                loaded = false
                Task {
                    (parentItems, allDayEvents) = await ItemStore
                        .loadSeperatedItems(by: date)
                }

                withAnimation {
                    loaded = true
                }
            }
            .task {
                await (parentItems, allDayEvents) = ItemStore
                    .loadSeperatedItems(by: date)
                withAnimation {
                    loaded = true
                }
            }
        }
    }
}
