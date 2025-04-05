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

    var body: some View {
        ScrollViewReader { proxy in
            VStack {
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
                            let allDayEvents =
                                ItemStore.allDayEvents(from: value)
                            let notAllDayItems = ItemStore
                                .filterAllDayEvents(from: value)

                            Section(
                                header: sectionHeader(
                                    key,
                                    notAllDayItems: value,
                                    allDayEvents: allDayEvents
                                )
                                .padding(
                                    .bottom,
                                    Spacing.m
                                )
                            ) {
                                VStack {
                                    ItemDisclosures(items: notAllDayItems)
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
                .defaultScrollAnchor(.center)
                .onAppear {
                    scrollToActiveDate(proxy: proxy)
                }
                .onChange(of: navigationStateService.activeDate) {
                    scrollToActiveDate(proxy: proxy, true)
                }
            }
        }
        .toolbarBackground(.hidden)
    }

    @ViewBuilder
    func sectionHeader(
        _ key: Date,
        notAllDayItems: [Item],
        allDayEvents: [Item]
    ) -> some View {
        AniButton {
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
                        VStack(alignment: .trailing) {
                            ForEach(
                                allDayEvents.sorted { first, second in
                                    first.text.count > second.text
                                        .count
                                }
                            ) { item in
                                Text(item.text)
                                    .childItem()
                                    .fontWeight(.ultraLight)
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                                    .frame(
                                        width: 100,
                                        alignment: .trailing
                                    )
                                    .multilineTextAlignment(
                                        .trailing
                                    )
                            }
                        }
                        .multilineTextAlignment(.trailing)
                        .frame(width: 100)
                    )
                }
            )
        }
        .titleTextStyle()
        .fontWeight(.regular)
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
