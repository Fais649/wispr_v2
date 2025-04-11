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
    @Environment(DayStateService.self) private var dayState: DayStateService
    @Environment(
        NavigationStateService
            .self
    ) private var navigationStateService: NavigationStateService

    var days: [Day]

    var todayDate: Date {
        Calendar.current.startOfDay(for: Date())
    }

    @Namespace var animation

    var body: some View {
        ScrollViewReader { _ in
            ScrollView {
                LazyVStack {
                    HStack {
                        Text("Once upon a wispr...")
                            .childItem()
                            .opacity(0.5)
                        Spacer()
                    }

                    ForEach(
                        days.sorted(by: { $0.date < $1.date }),
                        id: \.id
                    ) { day in
                        let allDayEvents =
                            ItemStore.allDayEvents(from: day.items)
                        let notAllDayItems = ItemStore
                            .filterAllDayEvents(from: day.items)

                        VStack {
                            Section(
                                header: sectionHeader(
                                    day.date,
                                    allDayEvents: allDayEvents,
                                    notAllDayItems: day.items
                                )
                                .scrollTransition(Spacing.none)
                            ) {
                                VStack(spacing: 0) {
                                    ItemDisclosures(
                                        animation: animation,
                                        items: notAllDayItems
                                    )
                                    .scrollTransition(Spacing.s)
                                }
                                .padding(.bottom, Spacing.l)
                            }
                        }
                        .safeAreaPadding(.bottom, Spacing.m)
                        .id(day.id)
                    }

                    HStack {
                        Text("...")
                            .childItem()
                            .opacity(0.5)
                        Spacer()
                    }
                }
                .scrollTargetLayout()
                .id("timeline")
            }
            .scrollTargetBehavior(.viewAligned)
            .defaultScrollAnchor(.top)
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

    func isToday(_ date: Date) -> Bool {
        return date == todayDate
    }

    func isFuture(_ date: Date) -> Bool {
        return date >= todayDate
    }
}
