//
//  Board.swift
//  wispr
//
//  Created by Faisal Alalaiwat on 04.03.25.
//
import SwiftData
import SwiftUI

@Model
final class Board: Identifiable, Equatable {
    var id: UUID = UUID()
    var name: String
    @Relationship(deleteRule: .noAction) var tags: [Tag] = []
    var timestamp: Date = Date()
    var lastClicked: Date?
    var startDate: Date?
    var endDate: Date?

    init(name: String, tags: [Tag], startDate: Date? = nil, endDate: Date? = nil) {
        self.name = name
        self.tags = tags
        self.startDate = startDate
        self.endDate = endDate
    }

    var title: some View {
        Text(name)
    }

    var globalBackground: some View {
        VStack {
            let first = tags.map { $0.color }.first ?? Color.clear
            let last = tags.map { $0.color }.last ?? first

            MeshGradient(width: 3, height: 3, points: [
                [0, 0], [0, 0.5], [0, 1],
                [0.5, 0], [0.5, 0.5], [0.5, 1],
                [1, 0], [1, 0.5], [1, 1],
            ], colors: [first, .clear, .clear, first, .clear, last, .clear,
                        .clear, last])
        }
    }
}

struct BoardForm: View {
    @Environment(Navigator.self) private var nav: Navigator
    @Environment(ActiveBoard.self) private var activeBoard: ActiveBoard
    @Environment(\.modelContext) private var modelContext: ModelContext
    @FocusState var focus: FocusedField?

    @State var board: Board

    @State private var name: String
    @State private var tags: [Tag]

    init(board: Board? = nil) {
        let i = board
        self.board = i ?? Board(name: "", tags: [])
        name = i?.name ?? ""
        tags = i?.tags ?? []
    }

    @State var isExpanded = true

    var body: some View {
        List {
            TextField("...", text: $name, axis: .vertical)
                .focused($focus, equals: .item(id: board.id))
                .onAppear {
                    focus = .item(id: board.id)
                }

            TagSelector(selectedItemTags: $tags)
        }
        .defaultScrollAnchor(.top)
        .onDisappear {
            board.name = name
            board.tags = tags

            if board.name.isNotEmpty {
                modelContext.insert(board)
            } else {
                modelContext.delete(board)
            }
            activeBoard.showBoard = true
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .toolbarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(name.isEmpty)
        .toolbar {
            ToolbarItemGroup(placement: .topBarLeading) {
                if name.isEmpty {
                    AniButton {
                        nav.path.removeLast()
                    } label: {
                        Image(systemName: "xmark")
                    }
                }
            }

            ToolbarItemGroup(placement: .bottomBar) {
                HStack(spacing: 10) {
                    AniButton {
                        modelContext.delete(board)
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
