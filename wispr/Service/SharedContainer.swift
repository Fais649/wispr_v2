//
//  SharedContainer.swift
//  wispr
//
//  Created by Faisal Alalaiwat on 10.02.25.
//
import EventKit
import Foundation
import NotificationCenter
import SwiftData
import SwiftUI

@MainActor
enum SharedState {
    static var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
            Tag.self,
            Book.self,
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )

        do {
            let urlApp = FileManager.default.urls(
                for: .applicationSupportDirectory,
                in: .userDomainMask
            ).last
            let url = urlApp!.appendingPathComponent("default.store")
            if FileManager.default.fileExists(atPath: url.path) {
                print("swiftdata db at \(url.absoluteString)")
            }
            return try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
        } catch {
            let urlApp = FileManager.default.urls(
                for: .applicationSupportDirectory,
                in: .userDomainMask
            ).last
            let url = urlApp!.appendingPathComponent("default.store")
            if FileManager.default.fileExists(atPath: url.path) {
                print("swiftdata db at \(url.absoluteString)")
            }

            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    static var widgetConductor: WidgetConductor = .init()

    static var syncedCalendar = false
}

@Observable
@MainActor
class WidgetConductor {
    var date: Date = .init()
    var parentItem: Item?
}
