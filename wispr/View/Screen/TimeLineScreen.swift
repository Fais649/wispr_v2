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

    var days: [Date: [Item]]

    var todayDate: Date {
        Calendar.current.startOfDay(for: Date())
    }

    @Binding var scrollToActiveDate: Bool

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack {
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
                        let allDayEvents =
                            ItemStore.allDayEvents(from: value)
                        let notAllDayItems = ItemStore
                            .filterAllDayEvents(from: value)

                        VStack {
                            Section(
                                header: sectionHeader(
                                    key,
                                    allDayEvents: allDayEvents,
                                    notAllDayItems: value
                                )
                                .scrollTransition(Spacing.none)
                            ) {
                                VStack(spacing: 0) {
                                    ItemDisclosures(items: notAllDayItems)
                                        .scrollTransition(Spacing.s)
                                }
                                .padding(.bottom, Spacing.l)
                            }
                        }.safeAreaPadding(.bottom, Spacing.m)
                            .opacity(
                                key < navigationStateService
                                    .activeDate ? 0.65 : 1
                            ).id(key)
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
                .scrollTargetLayout()
                .id("timeline")
            }
            .scrollTargetBehavior(.viewAligned)
            .defaultScrollAnchor(.top)
            .onAppear {
                scrollToActiveDate(proxy: proxy)
            }
            .onChange(of: scrollToActiveDate) {
                if scrollToActiveDate {
                    scrollToActiveDate(proxy: proxy, true)
                    scrollToActiveDate = false
                }
            }
            .onChange(of: navigationStateService.activeDate) {
                scrollToActiveDate(proxy: proxy, true)
            }
        }
    }

    @ViewBuilder
    func sectionHeader(
        _ key: Date,
        allDayEvents: [Item],
        notAllDayItems: [Item]
    ) -> some View {
        AniButton(padding: 0) {
            navigationStateService.goToActiveDay(
                activeDay:
                ActiveDay(
                    date: key,
                    items: notAllDayItems
                )
            )
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

    func scrollToActiveDate(
        proxy: ScrollViewProxy,
        _ animated: Bool = false
    ) {
        // DispatchQueue.main.asyncAfter(
        //     deadline: .now() +
        //         1
        // ) {
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
        } else {
            withAnimation(animated ? .smooth : nil) {
                proxy.scrollTo(
                    navigationStateService.activeDate,
                    anchor: .top
                )
            }
        }
        // }
    }

    func isToday(_ date: Date) -> Bool {
        return date == todayDate
    }

    func isFuture(_ date: Date) -> Bool {
        return date >= todayDate
    }
}
