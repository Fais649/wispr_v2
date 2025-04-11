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

    @Namespace var animation
    var body: some View {
        Screen(
            .bookShelf,
            loaded: true,
            title: title,
            trailingTitle: trailingTitle
        ) {
            ScrollView {
                VStack(spacing: 0) {
                    Disclosures(
                        animation: animation,
                        items: books
                            .sorted(by: {
                                if
                                    let firstClick = $0.lastClicked,
                                    let secondClick = $1.lastClicked
                                {
                                    return firstClick > secondClick
                                } else {
                                    return $0.timestamp < $1.timestamp
                                }
                            }),
                        itemRow: { book in
                            AniButton(padding: Spacing.xxs) {
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
                                    VStack(alignment: .leading) {
                                        Text(book.name)
                                            .truncationMode(.tail)
                                            .lineLimit(1)
                                    }
                                }
                            }
                            .parentItem()
                            .padding(Spacing.s)
                            .buttonStyle(.plain)
                            .padding(Spacing.s)
                        },
                        childRow: { _ in EmptyView() }
                    )
                    .scrollTransition(Spacing.s)
                }
                .safeAreaPadding(.vertical, Spacing.m)
            }
        }
    }
}
