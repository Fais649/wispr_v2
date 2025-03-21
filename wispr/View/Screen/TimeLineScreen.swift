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
    @Environment(ActiveTheme.self) private var activeTheme: ActiveTheme
    @Environment(NavigatorService.self) private var nav: NavigatorService

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

    var body: some View {
        ScrollViewReader { proxy in
            VStack {
                if self.loaded {
                    ScrollView {
                        LazyVStack(pinnedViews: [.sectionHeaders]) {
                            ForEach(
                                self.days.sorted(by: { $0.key < $1.key }),
                                id: \.key
                            ) { key, value in
                                Section(header: self.sectionHeader(key)) {
                                    DGroups(items: value)
                                        .padding(.leading, 20)
                                        .scrollTransition(
                                            .interactive
                                                .threshold(
                                                    .visible
                                                        .inset(by: 75)
                                                )
                                        ) { content, phase in
                                            content
                                                .opacity(
                                                    phase
                                                        .isIdentity ? 1 : 0
                                                )
                                                .blur(
                                                    radius: phase
                                                        .isIdentity ? 0 : 40
                                                )
                                                .scaleEffect(
                                                    x: 1,
                                                    y: phase
                                                        .isIdentity ?
                                                        1 :
                                                        0,
                                                    anchor: .bottom
                                                )
                                        }
                                }
                            }
                            Spacer().frame(height: 80)
                        }
                        .id(self.nav.activeBoard.board?.id.description ?? "all")
                    }
                    .onAppear {
                        scrollToActiveDate(true, proxy: proxy)
                    }
                    .onChange(of: self.nav.activeDate) {
                        scrollToActiveDate(proxy: proxy, true)
                    }
                    .defaultScrollAnchor(.top)
                } else {
                    ProgressView().progressViewStyle(.circular)
                        .task {
                            days = await self.loadFilteredDays()
                        }
                }
            }
        }
        .hideSystemBackground()
        .onChange(of: items) {
            Task {
                days = await self.loadFilteredDays()
            }
        }.onChange(of: nav.activeBoard.board) {
            Task {
                days = await self.loadFilteredDays()
            }
        }.task {
            for i in self.items.filter({ $0.text.isEmpty }) {
                self.modelContext.delete(i)
            }
            days = await self.loadFilteredDays()
        }
    }

    func scrollToActiveDate(
        _ onAppear: Bool = false,
        proxy: ScrollViewProxy,
        _ animated: Bool = false
    ) {
        Task {
            if days[nav.activeDate] == nil {
                let sortedKeys = days.keys.sorted()
                if
                    let next = sortedKeys.first(where: { $0 >
                            nav.activeDate
                    })
                {
                    withAnimation {
                        proxy.scrollTo(next, anchor: .top)
                    }
                }

                if nav.onTimeline, !onAppear {
                    withAnimation(animated ? .smooth : nil) {
                        self.nav.goToDayScreen()
                    }
                }
            } else {
                withAnimation(animated ? .smooth : nil) {
                    proxy.scrollTo(
                        self.nav.activeDate,
                        anchor: .top
                    )
                }
            }
        }
    }

    func loadFilteredDays() async -> [Date: [Item]] {
        withAnimation {
            self.loaded = false
        }

        let d = await filterDays()

        withAnimation {
            self.loaded = true
        }
        return d
    }

    func filterDays() async -> [Date: [Item]] {
        let days = Dictionary(
            grouping: items,
            by: {
                Calendar.current.startOfDay(for: $0.timestamp)
            }
        )
        return days.filter { _, items in
            guard let board = nav.activeBoard.board else { return true }
            return items.contains { item in
                item.tags.contains(where: board.tags.contains)
            }
        }
    }

    func isToday(_ date: Date) -> Bool {
        return date == todayDate
    }

    func isFuture(_ date: Date) -> Bool {
        return date >= todayDate
    }

    @ViewBuilder
    func sectionHeader(_ key: Date) -> some View {
        AniButton {
            self.nav.activeDate = key
            self.nav.path.append(.dayScreen)
        } label: {
            HStack {
                if key == self.nav.activeDate {
                    Image(systemName: "asterisk")
                        .headerLabelStyler()
                }

                Text(key.formatted(date: .abbreviated, time: .omitted))
                    .headerLabelStyler()

                Spacer()

                Text(key.formatted(.dateTime.weekday()))
                    .headerLabelStyler()
            }
            .padding(.vertical, 30)
        }
        .scrollTransition(.interactive.threshold(.visible)) { content, phase in
            content.opacity(phase.isIdentity ? 1 : 0)
                .blur(radius: phase.isIdentity ? 0 : 40)
                .scaleEffect(
                    x: 1,
                    y: phase.isIdentity ? 1 : 0,
                    anchor:
                    phase.value > 0 ? .top : .bottom
                )
        }
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
