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

    static func create() -> Book {
        Book(name: "", tags: [])
    }

    @MainActor
    static func loadBooks() -> [Book] {
        let desc = FetchDescriptor<Book>()

        let res = try? modelContext.fetch(desc)
        let books = res ?? []
        return books
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
final class Book: Codable, Transferable, Identifiable, Equatable, Listable {
    typealias Child = Tag
    var id: UUID = UUID()
    var name: String
    @Relationship(deleteRule: .noAction) var tags: [Tag] = []
    var timestamp: Date = Date()
    var lastClicked: Date?

    var parent: Book? = nil
    var children: [Tag] { [] }

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
                .opacity(0.2)
            }
        )
    }

    var shadowTint: Color {
        color
    }

    init(
        name: String,
        tags: [Tag],
        color: UIColor = .systemPink
    ) {
        self.name = name
        self.tags = tags
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
        tags = []
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
