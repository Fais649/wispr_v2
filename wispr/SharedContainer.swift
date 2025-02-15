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
class EventHandler {
    let calendarService = SharedState.calendarService
    var item: Item
    var event: EventData

    init(_ item: Item, _ event: EventData) {
        self.item = item
        self.event = event
    }

    fileprivate func processEventData() -> EventData? {
        if !item.isEvent {
            return nil
        }

        event.startDate = Calendar.current.combineDateAndTime(date: item.timestamp, time: event.startDate)
        event.endDate = Calendar.current.combineDateAndTime(date: item.timestamp, time: event.endDate)

        if let id = event.eventIdentifier, let ekEvent = calendarService.eventStore.event(withIdentifier: id) {
            calendarService.updateEKEvent(ekEvent: ekEvent, item: item, event: event)
            return event
        }

        if let ek = calendarService.createEventInCalendar(
            title: item.noteData.text,
            start: event.startDate,
            end: event.endDate
        ) {
            var e = event
            e.eventIdentifier = ek.eventIdentifier
            return createNotification(e)
        }

        return nil
    }

    fileprivate func createNotification(_ event: EventData) ->
        EventData
    {
        var e = event
        if e.notifyAt != nil {
            deleteNotification()
            e.notifyAt = nil
        }

        let content = UNMutableNotificationContent()
        content.title = item.noteData.text
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
        SharedState.dayDetailsConductor.editItem = nil
        context.rollback()
        try? context.save()
    }

    func commit(item: Item, _: Bool = false) -> Bool {
        if !item.hasNote {
            _ = DeleteHandler().delete(item)
            return true
        }

        item.timestamp = SharedState.dayDetailsConductor.date

        if let event = item.eventData {
            let eventHandler = EventHandler(item, event)
            let e = eventHandler.processEventData()
            item.eventData = e
        }

        if var i = itemExists(item) {
            context.delete(i)
            context.insert(item)
            try? context.save()
        } else {
            context.insert(item)
            for child in item.children {
                if child.hasNote && itemExists(child) == nil {
                    context.insert(child)
                }
            }
        }
        try? context.save()

        SharedState.dayDetailsConductor.editItem = nil
        SharedState.dayDetailsConductor.rollbackItem = nil
        return true
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
            SharedState.dayDetailsConductor.editItem = nil
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

@Observable
@MainActor
class DayDetailsConductor {
    var showDatePicker: Bool = false
    var editItem: Item?
    var rollbackItem: Item?

    var isEditingItem: Bool {
        editItem != nil
    }

    func rollback(context: ModelContext) {
        withAnimation {
            SharedState.dayDetailsConductor.editItem = nil
            context.rollback()
            try? context.save()
        }
    }

    var date: Date = .init()

    init() {}
}

@MainActor
enum SharedState {
    static var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    static var dayDetailsConductor: DayDetailsConductor = .init()
    static var calendarService: CalendarService = .init()
    static var widgetConductor: WidgetConductor = .init()

    static var syncedCalendar = false

    static func createNewItem(date: Date, position: Int) -> Item {
        let timestamp = Calendar.current.combineDateAndTime(date: date, time: Date())

        let newItem = Item(
            position: position,
            timestamp: timestamp
        )

        withAnimation {
            if CommitHandler().create(newItem) {
                SharedState.dayDetailsConductor.date = Calendar.current.startOfDay(for: newItem.timestamp)
                SharedState.dayDetailsConductor.editItem = newItem
            } else {
                SharedState.dayDetailsConductor.editItem = nil
            }
        }

        return newItem
    }

    static func commitItem(item: Item, _ rollback: Bool = false) {
        _ = CommitHandler().commit(item: item, rollback)
    }

    static func commitEditItem(_ rollback: Bool = false) {
        if let item = SharedState.dayDetailsConductor.editItem {
            _ = CommitHandler().commit(item: item, rollback)
        }
    }

    static func deleteItem(_ item: Item) {
        _ = DeleteHandler().delete(item)
    }

    static func rollbackItem() {
        CommitHandler().rollback()
    }
}
