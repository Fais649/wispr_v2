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
        NavigationStateService
            .self
    ) private var navigationStateService: NavigationStateService
    @Environment(
        FlashStateService
            .self
    ) private var flashService: FlashStateService
    @Environment(\.dismiss) private var dismiss
    @Query var items: [Item]

    var bookFilter: Book? {
        navigationStateService.bookState.book
    }

    var chapterFilter: Tag? {
        navigationStateService.bookState.chapter
    }

    @State var filteredItems: [Item] = []
    @State private var loaded = false

    init(activeDate: Date) {
        _items = Query(
            filter: ItemStore.activeItemsPredicated(for: activeDate),
            sort: \.position
        )
    }

    func titleDivider() -> some View {
        SimpleDvider()
    }

    func title() -> some View {
        DateTitle(
            date: navigationStateService.activeDate,
            scrollTransition: false,
            dateStringLeading: navigationStateService.activeDate.formatted(
                date: .long,
                time: .omitted
            )
        )
    }

    func subTitle() -> some View {
        HStack {
            DateSubTitleLabel(date: navigationStateService.activeDate)
            Spacer()
        }
    }

    func trailingTitle() -> some View {
        Text(
            navigationStateService.activeDate
                .formatted(.dateTime.weekday(.wide))
        )
    }

    var body: some View {
        Screen(
            .dayScreen,
            divider: titleDivider,
            title: title,
            trailingTitle: trailingTitle,
            subtitle: subTitle
        ) {
            if loaded {
                Lst {
                    ItemDisclosures(items: filteredItems)
                }.overlay(alignment: .center) {
                    if self.filteredItems.isEmpty {
                        Image(systemName: "plus.circle.dashed")
                            .fontWeight(.ultraLight)
                    }
                }
            } else {
                Spacer()
                ProgressView().progressViewStyle(.circular)
                    .task { await self.loadedFilteredItems() }
                Spacer()
            }
        }
        .onChange(of: navigationStateService.bookState.book) {
            Task {
                await self.loadedFilteredItems()
            }
        }
        .onChange(of: navigationStateService.activeDate) {
            Task {
                await self.loadedFilteredItems()
            }
        }
        .onChange(of: items) {
            Task {
                await self.loadedFilteredItems()
            }
        }
    }

    func loadedFilteredItems() async {
        withAnimation {
            self.loaded = false
        }
        await filterItems()
        withAnimation {
            self.loaded = true
        }
    }

    func filterItems() async {
        if let chapterFilter {
            filteredItems = ItemStore.filterByChapter(
                items: items,
                chapter:
                chapterFilter
            )
        } else {
            filteredItems = ItemStore.filterByBook(
                items: items,
                book: bookFilter
            )
        }
    }
}
