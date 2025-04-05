//
//  BaseBookShelfView.swift
//  wispr
//
//  Created by Faisal Alalaiwat on 21.03.25.
//

import SwiftData
import SwiftUI

struct BaseBookShelfView: View {
    @Environment(
        NavigationStateService
            .self
    ) private var navigationStateService: NavigationStateService
    @Query var books: [Book]
    @State var editBooks = false

    @ViewBuilder
    func title() -> some View {
        if navigationStateService.bookState.book != nil {
            ToolbarButton(padding: Spacing.none) {
                navigationStateService.bookState.book = nil
                navigationStateService.bookState.chapter = nil

                navigationStateService.shelfState.dismissShelf()
            } label: {
                Image(systemName: "xmark")
            }
        }
        Text("Books")
    }

    @ViewBuilder
    func trailingTitle() -> some View {
        AniButton {
            editBooks.toggle()
        } label: {
            Image(
                systemName: self
                    .editBooks ? "checkmark" : "pencil"
            )
        }

        AniButton {
            navigationStateService.goToBookForm()
        } label: {
            Image(systemName: "plus")
        }
    }

    var body: some View {
        Screen(
            .bookShelf,
            loaded: true,
            title: title,
            trailingTitle: trailingTitle
        ) {
            Lst {
                ForEach(self.books.sorted(by: {
                    if
                        let firstClick = $0.lastClicked,
                        let secondClick = $1.lastClicked
                    {
                        return firstClick > secondClick
                    } else {
                        return $0.timestamp < $1.timestamp
                    }
                })) { book in

                    AniButton {
                        if editBooks {
                            navigationStateService.goToBookForm(book)
                        } else {
                            navigationStateService.bookState
                                .book = book
                            navigationStateService.bookState
                                .chapter = nil
                        }

                        if
                            navigationStateService
                                .shelfState
                                .isShown()
                        {
                            navigationStateService
                                .shelfState
                                .dismissShelf()
                        }
                    } label: {
                        HStack {
                            Text(book.name)
                        }
                    }
                    .buttonStyle(.plain)
                    .background(
                        book.globalBackground
                            .clipShape(
                                RoundedRectangle(cornerRadius: 10)
                            )
                    )
                }
            }
        }
    }
}

struct BaseBookShelfLabelView: View {
    @Environment(
        NavigationStateService
            .self
    ) private var navigationStateService: NavigationStateService

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

    var clipShape: AnyShape {
        if book != nil {
            return AnyShape(Capsule())
        } else {
            return AnyShape(Circle())
        }
    }

    var bookShelfShown: Bool {
        navigationStateService.shelfState.isBook()
    }

    var body: some View {
        ToolbarButton(
            padding: -8,
            toggledOn: bookShelfShown,
            clipShape: clipShape
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

        ToolbarButton(padding: -16) {
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
                        .scaleEffect(0.8)
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

        ToolbarButton(padding: -16) {
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
                                .dateTime.day(.twoDigits).month(.twoDigits)
                                    .year(.twoDigits)
                            )
                    )
                } else {
                    Image(systemName: "circle.fill")
                        .scaleEffect(0.6)
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

        Spacer()
    }
}
