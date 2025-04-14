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
        do {
            let urlApp = FileManager.default.urls(
                for: .applicationSupportDirectory,
                in: .userDomainMask
            ).last!
            let url = urlApp.appendingPathComponent("default.store")

            let config = ModelConfiguration(url: url)

            return try ModelContainer(
                for: Schema([
                    Item.self, Book.self, Chapter.self,
                    DaysSchemaV2.Day.self, EventCalendar.self,
                ]),
                configurations: config
            )
        } catch {
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
