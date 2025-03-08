//
//  Board.swift
//  wispr
//
//  Created by Faisal Alalaiwat on 04.03.25.
//
import SwiftData
import SwiftUI

@Model
final class Board: Identifiable, Equatable, Selectable {
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

    @ViewBuilder
    var selectedBackground: some View {
        let colors = tags.map { tag in
            tag.color
        }

        TimelineView(.animation) { timeline in
            let x = (sin(timeline.date.timeIntervalSince1970) + 1) / 2

            MeshGradient(width: 3, height: 2, points: [
                [0, 0], [Float(x), 0], [1, 0],
                [0, 1], [0.5, 1], [1, 1],
            ], colors: colors)
                .blur(radius: 15 * (1 - x) + 10)
        }
    }

    @ViewBuilder
    var background: some View {
        let colors = tags.map { tag in
            tag.color
        }

        TimelineView(.animation) { timeline in
            let x = (sin(timeline.date.timeIntervalSince1970) + 1) / 2

            MeshGradient(width: 3, height: 2, points: [
                [0, 0], [Float(x), 0], [1, 0],
                [0, 1], [0.5, 1], [1, 1],
            ], colors: colors)
                .blur(radius: 15 * (1 - x) + 10)
        }
    }

    static func createNew() -> Self {
        return .init(name: "", tags: [])
    }

    func editButtonLabel(isEdit: Bool, minimized: Bool) -> some View {
        HStack {
            Text(name)
        }
        .font(.custom("GohuFont11NFM", size: minimized ? 12 : 16))
        .frame(minWidth: 50, maxWidth: minimized ? 120 : 140)
        .scaleEffect(isEdit ? 1.02 : 1)
        .lineLimit(1)
        .padding(8)
        .background {
            ZStack {
                if isEdit {
                    RoundedRectangle(cornerRadius: 20).stroke(.white)
                }
                background
                    .padding(2)
            }
        }
        .tint(.white)
        .buttonStyle(.plain)
        .clipShape(Capsule())
    }

    var searchable: String {
        return name
    }
}

struct BoardSelector: View {
    @Binding var selectedBoard: [Board]
    @Query var allCollections: [Board]

    var body: some View {
        Selector(
            style: .grid,
            selected: $selectedBoard,
            all: allCollections,
            selectLimit: 1,
            editTForm: singleBoardForm,
            isEditable: true
        )
        .buttonStyle(.plain)
        .background(.black)
        .scrollContentBackground(.hidden)
        .listRowBackground(Color.black)
    }

    @ViewBuilder
    func singleBoardForm(_ selected: Binding<[Board]>, _ selectAction: Binding<SelectAction>, _ initialValue: Binding<Board?>) -> some View {
        BoardDetailsForm(selected: selected, initialValue: initialValue, selectAction: selectAction)
    }
}

struct BoardDetailsForm: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var selected: [Board]
    @Binding var initialValue: Board?

    @Binding var selectAction: SelectAction

    @Query var allTags: [Tag]
    @State var selectedTags: [Tag] = []
    @State var name: String = ""

    @FocusState var focus: Bool

    var body: some View {
        VStack {
            HStack {
                AniButton {
                    initialValue = nil
                    selectAction = .view
                } label: {
                    Image(systemName: "chevron.left")
                }

                TextField("name...", text: $name)
                    .focused($focus)
                    .onAppear {
                        focus = true
                        if let initialValue {
                            name = initialValue.name
                        }
                    }

                AniButton {
                    if let initialValue {
                        modelContext.delete(initialValue)
                        selected.removeAll { $0 == initialValue }
                        self.initialValue = nil
                    }
                    selectAction = .view
                } label: {
                    Image(systemName: "trash")
                }
                .disabled(name.isEmpty)

                if name.isNotEmpty {
                    AniButton {
                        if let initialValue {
                            initialValue.name = name
                            initialValue.tags = selectedTags
                            modelContext.insert(initialValue)
                            self.initialValue = nil
                        }
                        selectAction = .view
                    } label: {
                        Image(systemName: "checkmark")
                    }
                    .disabled(name.isEmpty)
                }
            }

            if let initialValue, initialValue.tags.isNotEmpty || allTags.isNotEmpty {
                Selector(
                    style: .inlineGrid,
                    selected: $selectedTags,
                    all: allTags,
                    selectLimit: 10,
                    isEditable: false,
                    isSearchable: false
                )
                .disabled(name.isEmpty)
                .onAppear { selectedTags = initialValue.tags }
            }
        }
    }
}
