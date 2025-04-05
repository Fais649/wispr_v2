//
//  Book.swift
//  wispr
//
//  Created by Faisal Alalaiwat on 04.03.25.
//
import SwiftData
import SwiftUI

class BookStore {
    @MainActor
    static var modelContext: ModelContext {
        SharedState.sharedModelContainer.mainContext
    }

    static func create() -> Book {
        Book(name: "", tags: [])
    }

    @MainActor
    static func loadBook(by chapters: [Tag]) -> Book? {
        let desc = FetchDescriptor<Book>()

        let res = try? modelContext.fetch(desc)
        let books = res ?? []
        return books.filter { $0.tags.contains { chapters.contains($0) } }.first
    }

    @MainActor
    static func loadBook(by chapter: Tag) -> Book? {
        let desc = FetchDescriptor<Book>()

        let res = try? modelContext.fetch(desc)
        let books = res ?? []
        return books.filter { $0.tags.contains(chapter) }.first
    }
}

@Model
final class Book: Identifiable, Equatable, Listable {
    typealias Child = Tag
    var id: UUID = UUID()
    var name: String
    @Relationship(deleteRule: .noAction) var tags: [Tag] = []
    var timestamp: Date = Date()
    var lastClicked: Date?
    var startDate: Date?
    var endDate: Date?

    var parent: Book? = nil
    var children: [Tag] { tags }

    var colorHex: String = UIColor.systemPink.toHex() ?? ""
    var color: Color {
        return Color(uiColor: UIColor(hex: colorHex))
    }

    init(
        name: String,
        tags: [Tag],
        startDate: Date? = nil,
        endDate: Date? = nil,
        color: UIColor = .systemPink
    ) {
        self.name = name
        self.tags = tags
        self.startDate = startDate
        self.endDate = endDate
        colorHex = color.toHex() ?? ""
    }

    var title: some View {
        Text(name)
    }

    var globalBackground: some View {
        Background(book: self)
    }

    struct Background: View {
        var book: Book
        @State var topRight: CGFloat = .random(in: 0 ... 1)
        @State var topLeft: CGFloat = .random(in: 0 ... 1)
        @State var top: CGFloat = .random(in: 0 ... 1)

        @State var centerRight: CGFloat = .random(in: 0 ... 1)
        @State var centerLeft: CGFloat = .random(in: 0 ... 1)
        @State var center: CGFloat = .random(in: 0 ... 1)

        @State var bottomRight: CGFloat = .random(in: 0 ... 1)
        @State var bottomLeft: CGFloat = .random(in: 0 ... 1)

        var body: some View {
            VStack {
                let first = book.color

                MeshGradient(width: 3, height: 3, points: [
                    [0, 0], [0, 0.5], [0, 1],
                    [0.5, 0], [0.5, 0.5], [0.5, 1],
                    [1, 0], [1, 0.5], [1, 1],
                ], colors: [
                    first.opacity(topRight),
                    first.opacity(topLeft),
                    first.opacity(top),
                    first.opacity(centerRight),
                    first.opacity(centerLeft),
                    first, // bottom center
                    first.opacity(bottomRight),
                    first.opacity(bottomLeft),
                    first.opacity(center),
                ])
                .blur(radius: 30)
            }
        }
    }
}
