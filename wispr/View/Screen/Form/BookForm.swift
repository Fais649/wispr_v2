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
        // .toolbar {
        //     ToolbarItemGroup(placement: .keyboard) {
        //         HStack {
        //             AniButton {
        //                 focus = nil
        //             } label: {
        //                 Image(systemName: "keyboard")
        //             }
        //
        //             Divider()
        //
        //             Spacer()
        //
        //             if focus == .item(id: book.id) {
        //                 Divider()
        //                 ColorPicker("", selection: $color)
        //             }
        //         }
        //     }
        // }
    }

    func subtitle() -> some View {
        EmptyView()
    }

    @State var colors: [Color] = [.blue, .red, .yellow, .green, .orange, .pink,
                                  .purple, .teal, .cyan, .mint, .indigo, .black]

    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
    ]

    var body: some View {
        Screen(
            .bookForm(book: book),
            title: title,
            subtitle: subtitle,
            backgroundOpacity: 0
        ) {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 20) {
                    AniButton {
                        self.color = .pink
                    } label: {
                        color
                            .overlay {
                                Circle()
                                    .fill(.clear)
                                    .stroke(.white, lineWidth: 4)
                            }
                            .clipShape(Circle())
                    }.frame(width: 100, height: 100)
                        .buttonStyle(.plain)
                        .shadow(color: self.color, radius: 2)

                    ForEach(
                        colors.filter { $0 != self.color },
                        id: \.self
                    ) { color in
                        AniButton {
                            self.color = color
                        } label: {
                            color
                                .clipShape(Circle())
                        }.frame(width: 50, height: 50)
                            .buttonStyle(.plain)
                    }
                }
                .padding()
                .listRowBackground(Color.clear)
            }
            .onChange(of: color) {
                withAnimation {
                    navigationStateService.tempBackground = {
                        AnyView(
                            RandomMeshBackground(color: color)
                        )
                    }
                }
            }
            .onAppear {
                withAnimation {
                    navigationStateService.tempBackground = {
                        AnyView(
                            RandomMeshBackground(color: color)
                        )
                    }
                }
            }.onDisappear {
                withAnimation {
                    navigationStateService.tempBackground = nil
                }
            }
        }.toolbar {
            ToolbarItemGroup(placement: .bottomBar) {
                HStack {
                    ToolbarButton {
                        navigationStateService.goBack()
                    } label: {
                        Image(
                            systemName: "chevron.left"
                        )
                    }
                    Spacer()
                }
            }

            ToolbarItemGroup(placement: .keyboard) {
                HStack {
                    ToolbarButton(padding: 0) {
                        focus = nil
                    } label: {
                        Image(
                            systemName: "keyboard.chevron.compact.down"
                        )
                    }
                    Spacer()
                }
            }
        }
        .onDisappear {
            book.name = name
            book.tags = tags
            if let h = UIColor(color).toHex() {
                book.colorHex = h
            }

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
                        modelContext.delete(tag)
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
            }
        }
    }
}
