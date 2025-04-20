//
//  BookForm.swift
//  wispr
//
//  Created by Faisal Alalaiwat on 24.03.25.
//

import SwiftData
import SwiftUI

struct BookForm: View {
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
    @Environment(
        ThemeStateService
            .self
    ) private var theme: ThemeStateService
    @Environment(\.modelContext) private var modelContext: ModelContext
    @FocusState var focus: FocusedField?

    var animation: Namespace.ID
    var book: Book

    @State private var name: String
    @State var color: Color
    @State private var children: [Chapter]

    init(animation: Namespace.ID, book: Book) {
        let b = book
        self.book = b
        self.animation = animation
        name = b.name
        color = b.color
        children = b.children
    }

    @State var appeared = false

    var colors: [String: [Color]] {
        let saturated: [Color] = stride(from: 0.0, to: 1.0, by: 0.1)
            .map { hue in
                Color(
                    hue: hue,
                    saturation: 1,
                    brightness: 1
                )
            }

        let light: [Color] = stride(from: 0.0, to: 1.0, by: 0.1)
            .map { hue in
                Color(
                    hue: hue,
                    saturation: 0.4,
                    brightness: 1
                )
            }

        let dark: [Color] = stride(from: 0.0, to: 1.0, by: 0.1)
            .map { hue in
                Color(
                    hue: hue,
                    saturation: 1,
                    brightness: 0.6
                )
            }

        let pastel: [Color] =
            stride(from: 0.0, to: 1.0, by: 0.1).map { hue in
                Color(
                    hue: hue,
                    saturation: 0.64,
                    brightness: 1
                )
            }

        return [
            "Standard": saturated,
            "Light": light,
            "Pastel": pastel,
            "Dark": dark,
        ]
    }

    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
    ]

    func isSelected(_ color: Color) -> Bool {
        if
            let hex = UIColor(color).toHex(),
            let selectedHex = UIColor(self.color).toHex()
        {
            return hex == selectedHex
        }
        return false
    }

    func title() -> some View {
        TxtField(
            label: "...",
            text: $name,
            focusState: $focus,
            focus: .item(id: book.id)
        ) { isTextEmpty in
            if isTextEmpty {
                focus = .item(id: book.id)
                return
            }

            let newChild = ChapterStore.create(book: book)

            children.append(newChild)

            DispatchQueue.main.async {
                focus = .item(id: newChild.id)
            }
        }
        .onChange(of: focus) {
            if case let .item(id: id) = focus {
                let toDelete = children
                    .filter { $0.name.isEmpty && $0.id != id }
                children
                    .removeAll {
                        toDelete.map { $0.id }.contains($0.id)
                    }
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .bottomBar) {
                HStack {
                    Spacer()
                    ToolbarButton {
                        navigationStateService.goBack()
                    } label: {
                        Image(
                            systemName: "chevron.down"
                        )
                    }
                    Spacer()
                }
            }

            ToolbarItemGroup(placement: .keyboard) {
                ToolbarButton(padding: 0) {
                    focus = nil
                } label: {
                    Image(
                        systemName: "keyboard.chevron.compact.down"
                    )
                }
                Divider()
                Spacer()
                Button {
                    showColor.toggle()
                } label: {
                    Image(systemName: "circle.fill").foregroundStyle(color)
                }
            }
        }
    }

    @State var showColor: Bool = false

    var body: some View {
        Screen(
            .bookForm(book: book),
            title: title,
            backgroundOpacity: 0
        ) {
            ScrollView {
                ForEach(
                    children.sorted(by: { $0.timestamp < $1.timestamp }),
                    id: \.self
                ) { child in
                    Child(
                        book: book,
                        children: $children,
                        child: child,
                        focus: $focus
                    )
                }
            }
            .safeAreaPadding(Spacing.m)
            .safeAreaPadding(.bottom, Spacing.m)
        }.sheet(isPresented: $showColor) {
            BookFormColorShelfView(colors: colors, color: $color)
                // Screen(.bookShelf, backgroundOpacity: 1) {
                //     ScrollView {
                //         ForEach(
                //             Array(colors).sorted { $0.key > $1.key },
                //             id: \.key
                //         ) { name, colors in
                //             Section(
                //                 header: HStack {
                //                     Text(name)
                //                     Spacer()
                //                 }.parentItem()
                //                     .scrollTransition(.animated) { content,
                //                     phase in
                //                         content
                //                             .opacity(phase.isIdentity ? 1 :
                //                             0)
                //                             .scaleEffect(
                //                                 phase.isIdentity || phase
                //                                     .value > 0 ? 1 : 0.8,
                //                                 anchor:
                //                                 .bottom
                //                             )
                //                             .offset(
                //                                 y:
                //                                 phase.isIdentity || phase
                //                                     .value > 0 ? 0 : 20
                //                             )
                //                     }
                //             ) {
                //                 LazyVGrid(columns: columns, spacing: 10) {
                //                     ForEach(
                //                         colors,
                //                         id: \.self
                //                     ) { color in
                //                         Button {
                //                             withAnimation {
                //                                 self.color = color
                //                             }
                //                         } label: {
                //                             Circle().fill(color).stroke(color.mix(
                //                                 with:
                //                                 .white,
                //                                 by:
                //                                 isSelected(color) ?
                //                                     0.6 : 0
                //                             ), lineWidth: 4)
                //                         }
                //                         .scrollTransition(.animated) {
                //                         content, phase
                //                             in
                //                             content
                //                                 .opacity(phase.isIdentity ? 1
                //                                 : 0)
                //                                 .scaleEffect(
                //                                     phase.isIdentity || phase
                //                                         .value > 0 ? 1 : 0.8,
                //                                     anchor:
                //                                     .bottom
                //                                 )
                //                                 .offset(
                //                                     y:
                //                                     phase.isIdentity || phase
                //                                         .value > 0 ? 0 : 20
                //                                 )
                //                         }
                //                         .frame(
                //                             width: 50,
                //                             height: 50
                //                         )
                //                         .scaleEffect(
                //                             isSelected(color)
                //                                 ? 1 : 0.9
                //                         )
                //                         .buttonStyle(.plain)
                //                         .shadow(
                //                             color: isSelected(color) ? self
                //                                 .color : .clear,
                //                             radius: 2
                //                         )
                //                     }
                //                 }
                //             }
                //         }
                //     }
                // }

                .presentationDetents([.fraction(0.6)])
                .presentationCornerRadius(0)
                .presentationBackground {
                    Rectangle().fill(
                        theme.activeTheme
                            .backgroundMaterialOverlay
                    )
                    .fade(
                        from: .bottom,
                        fromOffset: 0.6,
                        to: .top,
                        toOffset: 1
                    )
                }
                .padding(.horizontal, Spacing.m)
                .containerRelativeFrame([
                    .horizontal,
                    .vertical,
                ])
        }
        .safeAreaPadding(Spacing.m)
        .onAppear {
            if name.isEmpty {
                focus = .item(id: book.id)
            }
        }
        .onDisappear {
            Task {
                book.commit(
                    name: name,
                    color: UIColor(color),
                    chapters: children.filter { $0.name.isNotEmpty }
                )
            }
        }.background {
            RandomMeshBackground(color: color)
                .ignoresSafeArea()
        }
    }

    struct Child: View {
        @Environment(\.modelContext) private var modelContext: ModelContext
        var book: Book
        @Binding var children: [Chapter]
        @State var child: Chapter
        @FocusState.Binding var focus: FocusedField?

        var isFocused: Bool {
            focus == .item(id: child.id)
        }

        var body: some View {
            HStack {
                TxtField(
                    label: "",
                    text: $child.name,
                    focusState: $focus,
                    focus: .item(id: child.id)
                ) { textEmpty in
                    if textEmpty {
                        children.removeAll { $0.id == child.id }
                        return
                    }

                    let newChapter = ChapterStore.create(book: book)

                    children.append(newChapter)

                    DispatchQueue.main.async {
                        focus = .item(id: newChapter.id)
                    }
                }
            }
            .childItem()
        }
    }
}
