//
//  BookShelf.swift
//  wispr
//
//  Created by Faisal Alalaiwat on 21.03.25.
//

import SwiftData
import SwiftUI

struct BaseBookShelfView: BookShelfView {
    @Environment(NavigationStateService.self) private var navigationStateService: NavigationStateService
    @Query var books: [Book]
    @State var editBooks = false

    var label: some View {
        Text(navigationStateService.activeDate.formatted())
    }
    
    var body: some View {
        Shelf {
            Lst {
                AniButton {
                    navigationStateService.bookState.book = nil
                    if navigationStateService.shelfState.isShown() {
                        navigationStateService.shelfState.dismissShelf()
                    }
                } label: {
                    Text("All")
                }
                .listRowBackground(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Material.ultraThinMaterial.opacity(0.6))
                        .opacity(0.6)
                        .fade(.top, .bottom)
                )

                Section(
                    header:
                    HStack {
                        Text("Books")
                        Spacer()

                        AniButton {
                            editBooks.toggle()
                        } label: {
                            Image(
                                systemName: self
                                    .editBooks ? "checkmark" : "pencil"
                            )
                        }

                        AniButton {
                            let book = Book(name: "", tags: [])
                            navigationStateService.pathState.setActive(.bookForm(book: book))
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                ) {
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
                                navigationStateService.pathState.setActive(.bookForm(book: book))
                            } else {
                                navigationStateService.bookState.book = book
                            }

                            if navigationStateService.shelfState.isShown() {
                                navigationStateService.shelfState.dismissShelf()
                            }
                        } label: {
                            HStack {
                                Text(book.name)
                            }
                        }
                        .listRowBackground(
                            book.globalBackground
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .blur(radius: 30)
                                .fade(.topLeading, .bottomTrailing)
                        )
                    }
                }
            }.parentItem()
        }
    }
}
