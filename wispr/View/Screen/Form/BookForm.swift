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
    @Environment(
        NavigationStateService
            .self
    ) private var navigationStateService: NavigationStateService
    @FocusState var focus: FocusedField?

    @State var book: Book

    @State private var name: String
    @State private var tags: [Tag]

    init(book: Book) {
        self.book = book
        name = book.name
        tags = book.tags
    }

    @State var isExpanded = true
    @State var color: Color = .pink

    fileprivate func title() -> some View {
        TxtField(
            label: "...",
            text: $name,
            focusState: $focus,
            focus: .item(
                id:
                book.id
            )
        ) { isTextEmpty in
            if isTextEmpty {
                focus = .item(id: book.id)
                return
            }

            let newChapter = ChapterStore.create(
                name: "",
                color: .systemPink
            )

            tags.append(newChapter)

            DispatchQueue.main.async {
                focus = .item(id: newChapter.id)
            }
        }
        .onAppear {
            if name.isEmpty {
                focus = .item(id: book.id)
            }
        }
        .toolbar {
            if focus == .item(id: book.id) {
                ToolbarItemGroup(placement: .keyboard) {
                    HStack {
                        AniButton {
                            focus = nil
                        } label: {
                            Image(systemName: "keyboard")
                        }

                        Divider()

                        Spacer()

                        Divider()
                        ColorPicker("", selection: $color)
                        // .onChange(of: color) {
                        //     if let hex = UIColor(color).toHex() {
                        //         tag.colorHex = hex
                        //     }
                        // } // ColorPicker
                    }
                }
            }
        }
    }

    var body: some View {
        Screen(.bookForm(book: book), title: title) {
            Lst {
                ForEach(tags) { tag in
                    Child(tags: $tags, tag: tag, focus: $focus)
                }
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
    }

    struct Child: View {
        @Environment(\.modelContext) private var modelContext: ModelContext
        @Binding var tags: [Tag]
        @State var tag: Tag
        @State var color: Color = .pink
        @FocusState.Binding var focus: FocusedField?

        func isFocused() -> Bool {
            focus == .item(id: tag.id)
        }

        var body: some View {
            HStack {
                TxtField(
                    label: "",
                    text: $tag.name,
                    focusState: $focus,
                    focus: .item(id: tag.id)
                ) { textEmpty in
                    if textEmpty {
                        tags.removeAll { $0.id == tag.id }
                        return
                    }

                    guard let i = tags.firstIndex(of: tag) else {
                        return
                    }

                    let index = i + 1 <= tags.endIndex
                        ? i + 1
                        : tags.count

                    let newChapter = ChapterStore.create(
                        name: "",
                        color: .systemPink
                    )

                    tags.insert(newChapter, at: index)

                    DispatchQueue.main.async {
                        focus = .item(id: newChapter.id)
                    }
                }
                .childItem()
            }.background(tag.selectedBackground)
                .toolbar {
                    if isFocused() {
                        ToolbarItemGroup(placement: .keyboard) {
                            HStack {
                                AniButton {
                                    focus = nil
                                } label: {
                                    Image(systemName: "keyboard")
                                }

                                Divider()

                                Spacer()
                                Divider()
                                ColorPicker("", selection: $color)
                                    .onChange(of: color) {
                                        if let hex = UIColor(color).toHex() {
                                            tag.colorHex = hex
                                        }
                                    } // ColorPicker
                            }
                        }
                    }
                }
        }
    }
}
