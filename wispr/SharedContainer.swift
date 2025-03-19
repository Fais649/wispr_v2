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
            Board.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            let urlApp = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).last
            let url = urlApp!.appendingPathComponent("default.store")
            if FileManager.default.fileExists(atPath: url.path) {
                print("swiftdata db at \(url.absoluteString)")
            }
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            let urlApp = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).last
            let url = urlApp!.appendingPathComponent("default.store")
            if FileManager.default.fileExists(atPath: url.path) {
                print("swiftdata db at \(url.absoluteString)")
            }

            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    static var calendarService: CalendarService = .init()
    static var widgetConductor: WidgetConductor = .init()

    static var syncedCalendar = false

    static func deleteItem(_ item: Item) {
        _ = DeleteHandler().delete(item)
    }

    static func rollbackItem() {
        CommitHandler().rollback()
    }
}

@MainActor
class EventHandler {
    let calendarService = SharedState.calendarService
    var item: Item
    var event: EventData

    init(_ item: Item, _ event: EventData) {
        self.item = item
        self.event = event
    }

    static func handleItem(_ item: Item, _ eventData: EventData) -> Item {
        let eventHandler = EventHandler(item, eventData)
        let e = eventHandler.processEventData()
        item.eventData = e
        return item
    }

    public func processEventData() -> EventData? {
        if !item.isEvent {
            deleteEventNotification()
            deleteEKEvent()
            return nil
        }

        event.startDate = Calendar.current.combineDateAndTime(date: item.timestamp, time: event.startDate)
        event.endDate = Calendar.current.combineDateAndTime(date: item.timestamp, time: event.endDate)

        if let id = event.eventIdentifier, let ekEvent = calendarService.eventStore.event(withIdentifier: id) {
            calendarService.updateEKEvent(ekEvent: ekEvent, item: item, event: event)
            return createNotification(event)
        }

        if let ek = calendarService.createEventInCalendar(
            title: item.text,
            start: event.startDate,
            end: event.endDate
        ) {
            var e = event
            e.eventIdentifier = ek.eventIdentifier
            return createNotification(e)
        }

        return nil
    }

    public func deleteEventNotification() {
        var e = event
        if e.notifyAt != nil {
            deleteNotification()
            e.notifyAt = nil
        }
    }

    fileprivate func createNotification(_ event: EventData) ->
        EventData
    {
        deleteEventNotification()
        var e = event
        let content = UNMutableNotificationContent()
        content.title = item.text
        content.body = event.startDate.formatted(date: .omitted, time: .shortened)
        let notifyAt = event.startDate.advanced(by: -1800)
        e.notifyAt = notifyAt

        let comps = Calendar.current.dateComponents([.day, .month, .year, .hour, .minute], from: notifyAt)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        let request = UNNotificationRequest(identifier: event.id.uuidString, content: content, trigger: trigger)
        let notificationCenter = UNUserNotificationCenter.current()

        Task {
            try? await notificationCenter.add(request)
        }
        return e
    }

    fileprivate func deleteNotification() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [item.eventData?.id.uuidString ?? event.id.uuidString])
    }

    fileprivate func deleteEKEvent() {
        if let id = event.eventIdentifier {
            calendarService.deleteEKEvent(id)
        }
    }
}

@MainActor
class CommitHandler {
    let context = SharedState.sharedModelContainer.mainContext
    let calendarService = SharedState.calendarService

    init() {}

    func create(_ item: Item) -> Bool {
        context.insert(item)
        try? context.save()
        return true
    }

    func rollback() {
        context.rollback()
        try? context.save()
    }

    func itemExists(_ item: Item) -> Item? {
        let desc = FetchDescriptor<Item>(predicate: #Predicate { $0.id ==
                item.id
        })

        return try? context.fetch(desc).first
    }
}

@MainActor
class DeleteHandler {
    let context = SharedState.sharedModelContainer.mainContext
    let calendarService = SharedState.calendarService

    init() {}

    func delete(_ item: Item) -> Bool {
        if let event = item.eventData {
            let eh = EventHandler(item, event)
            eh.deleteNotification()
            eh.deleteEKEvent()
        }

        withAnimation {
            context.delete(item)
            try? context.save()
        }
        return true
    }
}

@Observable
@MainActor
class WidgetConductor {
    var date: Date = .init()
    var parentItem: Item?
}
