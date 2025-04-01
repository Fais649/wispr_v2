//
//  Tag.swift
//  wispr
//
//  Created by Faisal Alalaiwat on 04.03.25.
//
import SwiftData
import SwiftUI

protocol Store {
    static var modelContext: ModelContext { get }
}

extension Store {
    @MainActor
    static var modelContext: ModelContext {
        SharedState.sharedModelContainer.mainContext
    }
}

class ChapterStore: Store {
    @MainActor
    static func create(
        name: String,
        color: UIColor,
        symbol: String = "circle.fill"
    ) -> Tag {
        let tag = Tag(name: name, color: color, symbol: symbol)
        modelContext.insert(tag)
        return tag
    }
}

@Model
final class Tag: Identifiable {
    var id = UUID()
    var name: String
    var colorHex: String
    var symbol = "circle.fill"
    var timestamp = Date()
    var lastClicked: Date?

    init(name: String, color: UIColor, symbol: String = "circle.fill") {
        self.name = name
        colorHex = color.toHex() ?? ""
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
