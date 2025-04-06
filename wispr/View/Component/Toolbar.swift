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
        BookStateService
            .self
    ) private var bookState: BookStateService

    @Query var books: [Book]

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
        navigationStateService.activeDate
    }

    var isToday: Bool {
        navigationStateService.isTodayActive
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
                Spacer()
            } else {
                ToolbarButton(
                    toggledOn: bookShelfShown
                ) {
                    navigationStateService.toggleSettingShelf()
                } label: {
                    Logo()
                }
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
                            navigationStateService.goToToday()
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
                        } else {
                            Image(systemName: "asterisk")
                                .resizable()
                                .scaledToFit()
                                .contentShape(Rectangle())
                                .frame(width: 16, height: 16)
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
                        } else {
                            Image(systemName: "circle.fill")
                                .resizable()
                                .scaledToFit()
                                .contentShape(Rectangle())
                                .frame(width: 12, height: 12)
                        }
                    }
                }
                .onTapGesture(count: isToday ? 1 : 2) {
                    withAnimation {
                        if isToday {
                            navigationStateService.toggleDatePickerShelf()
                        } else {
                            navigationStateService.goToToday()
                        }
                    }
                }
            }

            if !onForm {
                Spacer()
                ToolbarButton(padding: 0) {
                    navigationStateService.goToItemForm()
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .padding(Spacing.m)
        .background(.ultraThinMaterial)
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
