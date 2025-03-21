//
//  Tag.swift
//  wispr
//
//  Created by Faisal Alalaiwat on 04.03.25.
//
import SwiftData
import SwiftUI

@Model
final class Tag: Identifiable, Selectable {
    var id = UUID()
    var name: String
    var colorHex: String
    var symbol = "circle.fill"
    var timestamp = Date()
    var lastClicked: Date?

    init(name: String, color: UIColor, symbol: String = "circle.fill") {
        self.name = name
        colorHex = color.toHex() ?? ""
        if name == "lol" { return }

        self.symbol = symbol
    }

    var color: Color {
        return Color(uiColor: UIColor(hex: colorHex))
    }

    var buttonLabel: some View {
        Text(name)
            .fixedSize()
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(background)
            .tint(.white)
            .buttonStyle(.plain)
            .clipShape(Capsule())
    }

    static func createNew() -> Self {
        return .init(name: "", color: .systemPink)
    }

    func editButtonLabel(isEdit: Bool, minimized: Bool) -> some View {
        HStack {
            Text(self.name)
        }
        // .font(.custom("GohuFont11NFM", size: minimized ? 12 : 16))
        .frame(minWidth: 50, maxWidth: minimized ? 120 : 140)
        .scaleEffect(isEdit ? 1.02 : 1)
        .lineLimit(1)
        .padding(8)
        .background {
            ZStack {
                if isEdit {
                    RoundedRectangle(cornerRadius: 20).stroke(.white)
                }
                self.background
                    .padding(2)
            }
        }
        .tint(.white)
        .buttonStyle(.plain)
        .clipShape(Capsule())
    }

    @ViewBuilder
    var selectedBackground: some View {
        TimelineView(.animation) { timeline in
            let x = 0.25 * sin(timeline.date.timeIntervalSince1970) + 0.5

            MeshGradient(width: 3, height: 3, points: [
                [0, 0], [0.5, 0], [1, 0],
                [0, 0.5], [Float(x), 0.5], [1, 0.5],
                [0, 1], [0.5, 1], [1, 1],
            ], colors: [.clear, .clear, .clear, .clear, self.color])
                .blur(radius: 10 * x)
        }
    }

    @ViewBuilder
    var background: some View {
        let colors = [color, .clear]

        TimelineView(.animation) { timeline in
            let x = (sin(timeline.date.timeIntervalSince1970) + 1) / 4

            LinearGradient(
                colors: colors,
                startPoint: .leading,
                endPoint: .trailing
            )
            .blur(radius: 15 * (1 - x) + 10)
        }
    }

    var searchable: String {
        return name
    }

    @ViewBuilder
    static func composeLinearGradient(for tags: [Tag]) -> some View {
        let colors = tags.map { $0.color } + [.clear]
        LinearGradient(
            colors: colors,
            startPoint: .top,
            endPoint: .bottomTrailing
        )
    }

    @ViewBuilder
    static func composeMeshGradient(for tags: [Tag]) -> some View {
        let colors = tags.map { $0.color }

        MeshGradient(width: 2, height: 2, points: [
            [0, 0], [1, 0],
            [0, 1], [1, 1],
        ], colors: colors)
            .blur(radius: 40)
    }
}

struct InfiniteRotation: ViewModifier {
    @State private var rotation: Angle = .zero
    let duration: Double

    func body(content: Content) -> some View {
        content
            .rotationEffect(rotation)
            .onAppear {
                withAnimation(
                    Animation.linear(duration: self.duration)
                        .repeatForever(autoreverses: false)
                ) {
                    self.rotation = .degrees(360)
                }
            }
    }
}

struct TagSelector: View {
    @Binding var selectedItemTags: [Tag]
    @Query var allTags: [Tag]
    var minimized = false

    var body: some View {
        Selector(
            style: .inlineGrid,
            emptyIcon: "tag",
            selected: $selectedItemTags,
            all: allTags,
            selectLimit: 10,
            editTForm: createView,
            isEditable: true,
            minimized: minimized
        )
    }

    @ViewBuilder
    func createView(
        _ selected: Binding<[Tag]>,
        _ selectAction:
        Binding<SelectAction>,
        _ initialValue: Binding<Tag?>
    ) -> some View {
        TagDetailsForm(
            selected: selected,
            initialValue: initialValue,
            selectAction: selectAction
        )
    }
}

struct TagDetailsForm: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var selected: [Tag]
    @Binding var initialValue: Tag?

    @Binding var selectAction: SelectAction
    @State var name = ""
    @State var color: Color = .pink

    @FocusState var focus: Bool

    var body: some View {
        HStack {
            AniButton {
                self.initialValue = nil
                self.selectAction = .view
            } label: {
                Image(systemName: "chevron.left")
            }.buttonStyle(.plain)

            ColorPicker("Color", selection: self.$color)
                .onAppear {
                    if let initialValue {
                        self.color = initialValue.color
                    }
                }
                .labelsHidden()
                .padding(.horizontal, 5)

            TextField("name...", text: self.$name)
                .limitInputLength(value: self.$name, length: 15)
                .focused(self.$focus)
                .onAppear {
                    self.focus = true
                    if let initialValue {
                        self.name = initialValue.name
                    }
                }.onSubmit {
                    if self.name.isEmpty {
                        initialValue = nil
                        self.selectAction = .view
                    }

                    if let initialValue {
                        initialValue.name = self.name
                        initialValue.colorHex = UIColor(self.color)
                            .toHex() ?? initialValue.colorHex
                        self.modelContext.insert(initialValue)
                        self.initialValue = nil
                    }
                    self.selectAction = .view
                }.submitScope()
                .submitLabel(.done)

            AniButton {
                if let initialValue {
                    self.modelContext.delete(initialValue)
                    self.selected.removeAll { $0 == initialValue }
                    self.initialValue = nil
                }
                self.selectAction = .view
            } label: {
                Image(systemName: "trash")
            }.buttonStyle(.plain)
                .disabled(self.name.isEmpty)

            AniButton {
                if let initialValue {
                    initialValue.name = self.name
                    initialValue.colorHex = UIColor(self.color)
                        .toHex() ?? initialValue.colorHex
                    self.modelContext.insert(initialValue)
                    self.initialValue = nil
                }
                self.selectAction = .view
            } label: {
                Image(systemName: "checkmark")
            }.buttonStyle(.plain)
                .disabled(self.name.isEmpty)
        }
    }
}
