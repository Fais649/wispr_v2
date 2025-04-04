//
//  TimeLineScreen.swift
//  wispr
//
//  Created by Faisal Alalaiwat on 21.03.25.
//
import SwiftData
import SwiftUI

struct TimeLineScreen: View {
    @Environment(\.modelContext) private var modelContext: ModelContext
    @Environment(ThemeStateService.self) private var theme: ThemeStateService
    @Environment(
        NavigationStateService
            .self
    ) private var navigationStateService: NavigationStateService

    @Query(
        filter: ItemStore.allActiveItemsPredicate(),
        sort: \.position
    )
    var items: [Item]

    @State var days: [Date: [Item]] = [:]

    var todayDate: Date {
        Calendar.current.startOfDay(for: Date())
    }

    @State private var loaded = false

    func title() -> some View {
        Text("Timeline")
    }

    fileprivate func load() {
        Task {
            days = await loadFilteredDays()
        }
    }

    var body: some View {
        Screen(
            .timelineScreen,
            title: title
        ) {
            ScrollViewReader { proxy in
                VStack {
                    if loaded {
                        ScrollView {
                            LazyVStack(pinnedViews: [.sectionHeaders]) {
                                VStack {
                                    HStack {
                                        Text("Once upon a wispr...")
                                            .childItem()
                                            .opacity(0.5)
                                        Spacer()
                                    }
                                    Spacer()
                                }
                                .frame(height: Spacing.l)

                                ForEach(
                                    days.sorted(by: { $0.key < $1.key }),
                                    id: \.key
                                ) { key, value in
                                    Section(
                                        header: sectionHeader(
                                            key,
                                            value.filter {
                                                if
                                                    let e =
                                                    $0.eventData
                                                {
                                                    return e.allDay
                                                } else {
                                                    return false
                                                }
                                            }
                                        )
                                        .padding(
                                            .bottom,
                                            Spacing.m
                                        )
                                    ) {
                                        VStack {
                                            ItemDisclosures(
                                                items:
                                                value
                                                    .filter {
                                                        if
                                                            let e =
                                                            $0.eventData
                                                        {
                                                            return !e.allDay
                                                        } else {
                                                            return true
                                                        }
                                                    }
                                            )
                                            .scrollTransition(Spacing.l)
                                            Spacer()
                                                .frame(height: Spacing.l)
                                        }.padding(Spacing.m)
                                    }.id(key)
                                        .opacity(
                                            key < navigationStateService
                                                .activeDate ? 0.65 : 1
                                        )
                                }

                                VStack {
                                    HStack {
                                        Text("...")
                                            .childItem()
                                            .opacity(0.5)
                                        Spacer()
                                    }
                                    Spacer()
                                }
                                .frame(height: Spacing.l)
                            }
                            .id("timeline")
                        }
                        .defaultScrollAnchor(.top)
                        .onAppear {
                            scrollToActiveDate(true, proxy: proxy)
                        }
                        .onChange(of: navigationStateService.activeDate) {
                            scrollToActiveDate(proxy: proxy, true)
                        }
                        .onChange(of: items) {
                            load()
                        }
                        .onChange(
                            of: navigationStateService.bookState
                                .chapter
                        ) {
                            load()
                            scrollToActiveDate(proxy: proxy, true)
                        }
                        .onChange(of: navigationStateService.bookState.book) {
                            load()
                            scrollToActiveDate(proxy: proxy, true)
                        }
                    } else {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .task {
                                days = await loadFilteredDays()
                            }
                    }
                }
            }
        }
        .task {
            days = await loadFilteredDays()
        }
    }

    @ViewBuilder
    func sectionHeader(_ key: Date, _ allDay: [Item]) -> some View {
        HStack(alignment: .firstTextBaseline) {
            DateTitleWithDivider(date: key, trailing: {
                AnyView(
                    VStack(alignment: .trailing) {
                        ForEach(allDay.sorted { first, second in
                            first.text.count > second.text.count
                        }) { item in
                            Text(item.text)
                                .childItem()
                                .fontWeight(.ultraLight)
                                .lineLimit(1)
                                .truncationMode(.tail)
                                .frame(width: 100, alignment: .trailing)
                                .multilineTextAlignment(.trailing)
                        }
                    }
                    .multilineTextAlignment(.trailing)
                    .frame(width: 100)
                )
            })
            .titleTextStyle()
            .fontWeight(.regular)
            .scrollTransition(Spacing.none)
        }
    }

    @ViewBuilder
    func sub(_ allDay: [Item]) -> some View {
        Disclosure(
            item: AllDay(children: allDay),
            itemRow: { _ in
                Text("All Day")
                    .parentItem().fontWeight(.ultraLight)
            },
            childRow: { child in
                HStack {
                    Text(child.text)
                    Spacer()
                }
                .childItem().fontWeight(.ultraLight)
            }
        )
    }

    func scrollToActiveDate(
        _ onAppear: Bool = false,
        proxy: ScrollViewProxy,
        _ animated: Bool = false
    ) {
        Task {
            if days[navigationStateService.activeDate] == nil {
                let sortedKeys = days.keys.sorted()
                if
                    let next = sortedKeys.first(where: { $0 >
                            navigationStateService.activeDate
                    })
                {
                    withAnimation(animated ? .smooth() : nil) {
                        proxy.scrollTo(next, anchor: .top)
                    }
                }

                if navigationStateService.onTimeline, !onAppear {
                    withAnimation(animated ? .smooth : nil) {
                        navigationStateService.goToDayScreen()
                    }
                }
            } else {
                withAnimation(animated ? .smooth : nil) {
                    proxy.scrollTo(
                        navigationStateService.activeDate,
                        anchor: .top
                    )
                }
            }
        }
    }

    func loadFilteredDays() async -> [Date: [Item]] {
        withAnimation {
            loaded = false
        }

        let d = await filterDays()

        withAnimation {
            loaded = true
        }
        return d
    }

    func filterDays() async -> [Date: [Item]] {
        let i = items.filter {
            guard let book = navigationStateService.bookState.book
            else { return true }

            if let chapter = navigationStateService.bookState.chapter {
                return $0.tags.contains(chapter)
            }

            return $0.tags.contains(where: book.tags.contains)
        }
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

    func isToday(_ date: Date) -> Bool {
        return date == todayDate
    }

    func isFuture(_ date: Date) -> Bool {
        return date >= todayDate
    }

    @ViewBuilder
    func archiveButton(_ item: Item) -> some View {
        AniButton {
            item.archive()
        } label: {
            Image(systemName: "archivebox.fill")
        }
    }

    @ViewBuilder
    func deleteButton(_ item: Item) -> some View {
        AniButton {
            item.delete()
        } label: {
            Image(systemName: "trash.fill")
        }
    }
}
