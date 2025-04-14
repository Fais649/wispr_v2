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
        Globals
            .self
    ) private var globals: Globals
    @Environment(
        NavigationStateService
            .self
    ) private var navigationStateService:
        NavigationStateService

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
        if let book = navigationStateService.bookState.book {
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
        Globals
            .self
    ) private var globals: Globals
    @Environment(
        NavigationStateService
            .self
    ) private var navigationStateService:
        NavigationStateService

    @Environment(
        DayStateService
            .self
    ) private var dayState: DayStateService

    var animation: Namespace.ID

    var day: Day
    var scrollView: Bool = true
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
        if let book = navigationStateService.bookState.book {
            return items.filter { $0.book == book }
        }
        return items
            .filter { $0.parent == nil && !$0.archived && $0.text.isNotEmpty }
            .sorted(by: { $0.position < $1.position })
    }

    func createGeometryID(date: Date, suffix: String) -> String {
        return date.hashValue.description + suffix
    }

    var body: some View {
        let date = day.date
        Screen(
            .dayScreen,
            loaded: true,
            title: {
                DateTrailingTitleLabel(
                    date: date
                )
            },
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
            backgroundOpacity: backgroundOpacity,
            onTapBackground: {
                navigationStateService
                    .goToItemForm(date: day.date)
            }
        ) {
            VStack {
                if scrollView {
                    ScrollView {
                        if dayEvents.isNotEmpty {
                            ForEach(dayEvents.sorted { first, second in
                                first.text.count > second.text.count
                            }) { item in
                                HStack {
                                    Text(item.text)
                                    Spacer()
                                }
                                .fontWeight(.ultraLight)
                            }
                        }

                        ItemDisclosures(
                            animation: animation,
                            defaultExpanded: true,
                            items: noAllDayEvents
                        )
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .safeAreaPadding(
                        .vertical,
                        Spacing.m
                    )
                } else {
                    if dayEvents.isNotEmpty {
                        ForEach(dayEvents.sorted { first, second in
                            first.text.count > second.text.count
                        }) { item in
                            HStack {
                                Text(item.text)
                                Spacer()
                            }
                            .fontWeight(.ultraLight)
                        }
                    }

                    ItemDisclosures(
                        animation: animation,
                        defaultExpanded: true,
                        items: noAllDayEvents
                    )
                }
            }
            .overlay(alignment: .center) {
                if noAllDayEvents.isEmpty {
                    ToolbarButton(padding: 0) {
                        withAnimation {
                            navigationStateService.goToItemForm()
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
    }
}
