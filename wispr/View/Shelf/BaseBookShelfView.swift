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
        Screen(.bookShelf, title: title, trailingTitle: trailingTitle) {
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
                    Disclosure(
                        item: book,
                        itemRow: { book in
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
                        },
                        childRow: { chapter in
                            AniButton {
                                if editBooks {
                                    navigationStateService.pathState
                                        .setActive(
                                            .bookForm(book: book)
                                        )
                                } else {
                                    navigationStateService.bookState
                                        .book = book
                                    navigationStateService.bookState
                                        .chapter = chapter
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
                                    Text(chapter.name)
                                }
                            }
                        }
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
    var book: Book? {
        navigationStateService.bookState.book
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
        HStack {
            ToolbarButton(
                padding: Spacing.s + Spacing.xxs,
                toggledOn: bookShelfShown,
                clipShape: clipShape
            ) {
                navigationStateService.toggleBookShelf()
            } label: {
                LogoBookButton()
            }
            .onChange(of: navigationStateService.activePath) {
                if navigationStateService.onForm {
                    withAnimation {
                        navigationStateService.closeShelf()
                    }
                }
            }
        }
    }
}
