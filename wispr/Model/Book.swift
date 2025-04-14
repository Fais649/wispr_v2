//
//  Book.swift
//  wispr
//
//  Created by Faisal Alalaiwat on 04.03.25.
//
import AppIntents
import AudioKit
import AVFoundation
import EventKit
import Foundation
import PhotosUI
import SwiftData
import SwiftUI
import SwiftWhisper
import SwipeActions
import UniformTypeIdentifiers
import UserNotifications
import WidgetKit

class BookStore {
    @MainActor
    static var modelContext: ModelContext {
        SharedState.sharedModelContainer.mainContext
    }

    @MainActor
    static func delete(_ book: Book) {
        modelContext.delete(book)
    }

    static func create() -> Book {
        Book(name: "", chapters: [])
    }

    @MainActor
    static func loadBooks() -> [Book] {
        let desc = FetchDescriptor<Book>()

        let res = try? modelContext.fetch(desc)
        let books = res ?? []
        return books
    }

    @MainActor
    static func loadBook(by chapter: Chapter? = nil) -> Book? {
        let desc = FetchDescriptor<Book>()
        let res = try? modelContext.fetch(desc)
        let books = res ?? []
        if let chapter {
            return books.filter { $0.chapters.contains(chapter) }
                .first
        }
        return nil
    }

    @MainActor
    static func loadBook(by chapter: Chapter) -> Book? {
        let desc = FetchDescriptor<Book>()

        let res = try? modelContext.fetch(desc)
        let books = res ?? []
        return books.filter { $0.chapters.contains(chapter) }.first
    }
}

struct MenuItem: Identifiable {
    var id: UUID = .init()
    var name: String
    var symbol: String
    var action: () -> Void
}

@Model
final class Book: Codable, Transferable, Identifiable, Equatable, Listable {
    typealias Child = Chapter

    var id: UUID = UUID()
    var name: String
    @Relationship(deleteRule: .cascade)
    var chapters: [Chapter] = []
    var timestamp: Date = Date()
    var lastClicked: Date?

    var parent: Book? = nil
    var children: [Chapter] {
        chapters.sorted(by: { $0.timestamp < $1.timestamp })
    }

    var colorHex: String = UIColor.systemPink.toHex() ?? ""
    var color: Color {
        return Color(uiColor: UIColor(hex: colorHex))
    }

    var preview: AnyView {
        AnyView(
            HStack {
                Text(name)
                Spacer()
            }
            .padding(.vertical, Spacing.xs)
            .background {
                RoundedRectangle(cornerRadius: 4).fill(
                    shadowTint
                )
            }
        )
    }

    @MainActor
    func delete() {
        BookStore.delete(self)
    }

    @MainActor
    func commit(name: String, color: UIColor, chapters: [Chapter] = []) {
        self.name = name
        self.chapters = chapters
        if let hex = color.toHex() {
            colorHex = hex
        }
        commit()
    }

    @MainActor
    func commit() {
        if name.isNotEmpty {
            BookStore.modelContext.insert(self)
        } else {
            BookStore.modelContext.delete(self)
        }

        try? BookStore.modelContext.save()
    }

    var menuItems: [MenuItem] {
        [
            .init(name: "Delete " + name, symbol: "trash.fill") {
                Task { @MainActor in
                    self.delete()
                }
            },
        ]
    }

    var shadowTint: AnyShapeStyle {
        AnyShapeStyle(color)
    }

    init(
        name: String,
        chapters: [Chapter],
        color: UIColor = .systemPink
    ) {
        self.name = name
        self.chapters = chapters
        colorHex = color.toHex() ?? ""
    }

    var title: some View {
        Text(name)
    }

    var globalBackground: some View {
        RandomMeshBackground(color: color)
    }

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case colorHex
    }

    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .item)
        ProxyRepresentation(exporting: \.name)
    }

    required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(UUID.self, forKey: .id)
        name = try values.decode(String.self, forKey: .name)
        colorHex = try values.decode(String.self, forKey: .colorHex)
        chapters = []
        timestamp = Date()
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(colorHex, forKey: .colorHex)
    }

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: LocalizedStringResource(
            stringLiteral: name
        ))
    }
}
