//
//  BookForm.swift
//  wispr
//
//  Created by Faisal Alalaiwat on 24.03.25.
//

import SwiftData
import SwiftUI

struct BookForm: View {
    @Environment(\.modelContext) private var modelContext: ModelContext
    @Environment(NavigationStateService.self) private var navigationStateService: NavigationStateService
    @FocusState var focus: FocusedField?

    @State var book: Book

    @State private var name: String
    @State private var tags: [Tag]

    init(book: Book? = nil) {
        let i = book
        self.book = i ?? Book(name: "", tags: [])
        name = i?.name ?? ""
        tags = i?.tags ?? []
    }

    @State var isExpanded = true

    fileprivate func title() -> some View {
        return TextField("...", text: $name, axis: .vertical)
            .focused($focus, equals: .item(id: book.id))
            .onAppear {
                focus = .item(id: book.id)
            }
    }

    var body: some View {
        Screen(title: title) {
            List {
                title()
            }
        }
        .onDisappear {
            book.name = name
            book.tags = tags

            if book.name.isNotEmpty {
                modelContext.insert(book)
            } else {
                modelContext.delete(book)
            }
            navigationStateService.openBookShelf()
        }
        .defaultScrollAnchor(.top)
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .toolbarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarLeading) {
                if name.isEmpty {
                    AniButton {
                        navigationStateService.pathState.goBack()
                    } label: {
                        Image(systemName: "xmark")
                    }
                }
            }

            ToolbarItemGroup(placement: .bottomBar) {
                HStack(spacing: 10) {
                    AniButton {
                        modelContext.delete(book)
                    } label: {
                        Image(systemName: "trash")
                    }

                    Spacer()
                }
            }

            ToolbarItemGroup(placement: .keyboard) {
                HStack {
                    AniButton {
                        focus = nil
                    } label: {
                        Image(systemName: "keyboard")
                    }

                    Divider()

                    Spacer()
                }
            }
        }
    }
}
