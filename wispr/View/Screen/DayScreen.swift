//
//  DayScreen.swift
//  wispr
//
//  Created by Faisal Alalaiwat on 21.03.25.
//
import SwiftData
import SwiftUI

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
    var backgroundOpacity: CGFloat = 0.5

    var parentItems: [Item] {
        day.items.filter { $0.parent == nil && $0.text.isNotEmpty }
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

    var body: some View {
        let date = day.date
        Screen(
            .dayScreen,
            loaded: true,
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
                DateTrailingTitleLabel(
                    date: date
                )
            },
            subtitle: {
                HStack {
                    Text(
                        date
                            .formatted(
                                .dateTime
                                    .weekday(.wide)
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
                Lst {
                    if dayEvents.isNotEmpty {
                        ForEach(dayEvents.sorted { first, second in
                            first.text.count > second.text.count
                        }) { item in
                            Text(item.text)
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
                if day.items.isEmpty {
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
