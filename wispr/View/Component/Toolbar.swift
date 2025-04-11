//
//  Toolbar.swift
//  wispr
//
//  Created by Faisal Alalaiwat on 21.03.25.
//

import SwiftData
import SwiftUI

struct Toolbar: View {
    @Environment(
        \.modelContext
    ) private var modelContext: ModelContext
    @Environment(
        NavigationStateService
            .self
    ) private var navigationStateService: NavigationStateService
    @Environment(
        DayStateService
            .self
    ) private var dayState: DayStateService

    @Environment(
        BookStateService
            .self
    ) private var bookState: BookStateService

    @Query var books: [Book]

    var showNewItemButton: Bool = true
    var showDateShelfButton: Bool = true
    var showBackground: Bool = true

    var onForm: Bool {
        navigationStateService.pathState.onForm
    }

    var onBookForm: Bool {
        navigationStateService.pathState.onBookForm
    }

    var bookShelfShown: Bool {
        navigationStateService.shelfState.isBook()
    }

    var date: Date {
        dayState.active.date
    }

    var isToday: Bool {
        dayState.isTodayActive()
    }

    var book: Book? {
        navigationStateService.bookState.book
    }

    var chapter: Tag? {
        navigationStateService.bookState.chapter
    }

    var noFilter: Bool {
        book == nil && isToday
    }

    @Namespace var animation

    var body: some View {
        HStack {
            if onForm {
                ToolbarButton {
                    navigationStateService.goBack()
                } label: {
                    Image(
                        systemName: "chevron.left"
                    )
                }
                .matchedGeometryEffect(id: "leftMostButton", in: animation)
                Spacer()
            } else {
                ToolbarButton {
                    navigationStateService.toggleSettingShelf()
                } label: {
                    Logo()
                }
                .matchedGeometryEffect(
                    id: "leftMostButton",
                    in: animation,
                    isSource: true
                )
                .onChange(of: navigationStateService.activePath) {
                    if navigationStateService.onForm {
                        withAnimation {
                            navigationStateService.closeShelf()
                        }
                    }
                }
                .onTapGesture(count: noFilter ? 1 : 2) {
                    withAnimation {
                        if noFilter {
                            navigationStateService.toggleSettingShelf()
                        } else {
                            navigationStateService.bookState.dismissBook()
                            dayState.setTodayActive()
                        }
                    }
                }
            }

            if !onBookForm {
                ToolbarButton {
                    navigationStateService.toggleBookShelf()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "line.diagonal")
                            .opacity(book == nil ? 0.4 : 1)
                            .scaleEffect(book == nil ? 0.6 : 1, anchor: .center)
                        if let book {
                            Text(book.name)
                                .matchedGeometryEffect(
                                    id: "bookButton",
                                    in: animation
                                )
                        } else {
                            Image(systemName: "asterisk")
                                .resizable()
                                .scaledToFit()
                                .contentShape(Rectangle())
                                .frame(width: 16, height: 16)
                                .matchedGeometryEffect(
                                    id: "bookButton",
                                    in: animation,
                                    isSource: true
                                )
                        }
                    }
                }
                .onTapGesture(count: book == nil ? 1 : 2) {
                    withAnimation {
                        if book == nil {
                            navigationStateService.toggleBookShelf()
                        } else {
                            navigationStateService.bookState.dismissBook()
                        }
                    }
                }

                if showDateShelfButton {
                    ToolbarButton {
                        navigationStateService.toggleDatePickerShelf()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "line.diagonal")
                                .opacity(isToday ? 0.4 : 1)
                                .scaleEffect(isToday ? 0.6 : 1, anchor: .center)

                            if !isToday {
                                Text(
                                    date
                                        .formatted(
                                            .dateTime.day(.twoDigits)
                                                .month(.twoDigits)
                                                .year(.twoDigits)
                                        )
                                )
                                .matchedGeometryEffect(
                                    id: "dateButton",
                                    in: animation
                                )
                            } else {
                                Image(systemName: "circle.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .contentShape(Rectangle())
                                    .frame(width: 12, height: 12)
                                    .matchedGeometryEffect(
                                        id: "dateButton",
                                        in: animation,
                                        isSource: true
                                    )
                            }
                        }
                    }
                    .onTapGesture(count: isToday ? 1 : 2) {
                        withAnimation {
                            if isToday {
                                navigationStateService.toggleDatePickerShelf()
                            } else {
                                dayState.setTodayActive()
                            }
                        }
                    }
                }
            }

            if showNewItemButton, !onForm {
                Spacer()
                ToolbarButton(padding: 0) {
                    navigationStateService.goToItemForm()
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .padding(Spacing.m)
        .background {
            if showBackground {
                Rectangle().fill(.ultraThinMaterial)
            }
        }
        .clipShape(Capsule())
    }
}

struct Logo: View {
    var body: some View {
        Image("Logo")
            .resizable()
            .scaledToFit()
            .contentShape(Rectangle())
            .frame(width: 16, height: 16)
            .foregroundStyle(.white)
            .blendMode(.hardLight)
    }
}
