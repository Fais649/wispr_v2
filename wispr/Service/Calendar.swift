//
//  Calendar.swift
//  wispr
//
//  Created by Faisal Alalaiwat on 20.03.25.
//
import SwiftUI
import EventKit
import SwiftData

@Observable
class CalendarService {
    var calendarAccess = false
    var synced = false
    
    func createEkEvent(
        title: String,
        start: Date,
        end: Date
    ) -> EKEvent? {
        if authorizeCalendarAccess() {
            return CalendarUtil.create(title, start, end)
        }
        return nil
    }
    
    func updateEKEvent(_ title: String, _ eventData: EventData) {
        if
            authorizeCalendarAccess(),
            let ekEvent = CalendarUtil
                .loadEkEventByIdentifier(eventData.eventIdentifier ?? "")
        {
            CalendarUtil.update(
                ekEvent: ekEvent,
                title,
                eventData.startDate,
                eventData.endDate
            )
        }
    }
    
    func deleteEKEvent(_ ekEvent: EKEvent) {
        if authorizeCalendarAccess() {
            CalendarUtil.delete(ekEvent)
        }
    }
    
    private func authorizeCalendarAccess() -> Bool {
        if !calendarAccess {
            calendarAccess = CalendarUtil.requestAccessToCalendar()
        }
        return calendarAccess
    }
    
    func syncCalendar(modelContext: ModelContext) {
        if synced { return }
        
        Task {
            let es = CalendarUtil.loadAllEKEvents()
            let eDict: [Date: [EKEvent]] = Dictionary(
                grouping: es,
                by: { Calendar.current.startOfDay(for: $0.startDate) }
            )
            
            let desc = FetchDescriptor<Item>()
            guard let evs = try? modelContext.fetch(desc)
            else {
                return
            }
            
            let items = evs.filter { $0.eventData != nil }
            
            let eventsDict: [Date: [Item]] = Dictionary(
                grouping: items,
                by: { if let ed = $0.eventData {
                    return Calendar.current.startOfDay(for: ed.startDate)
                }
                    return Calendar.current.startOfDay(for: Date())
                }
            )
            
            for (date, es) in eDict {
                for e in es {
                    if
                        let item = items
                            .filter({
                                $0.eventData?.eventIdentifier == e
                                    .eventIdentifier
                            })
                            .first,
                        var eventData = item.eventData
                    {
                        eventData.startDate = e.startDate
                        eventData.endDate = e.endDate
                        eventData.calendarIdentifier = e.calendar
                            .calendarIdentifier
                        item.eventData = eventData
                        item.text = e.title
                    } else {
                        let newItem = Item(
                            position: eventsDict[Calendar.current
                                .startOfDay(for: date)]?.count ?? 0,
                            timestamp: date
                        )
                        newItem.text = e.title
                        newItem.eventData = EventData(from: e)
                        modelContext.insert(newItem)
                    }
                }
            }
            
            try? modelContext.save()
            
            synced = true
        }
    }
}

class CalendarUtil {
    private static let eventStore: EKEventStore = .init()
    
    static func requestAccessToCalendar() -> Bool {
        var g = false
        eventStore.requestFullAccessToEvents { granted, error in
            if granted, error == nil {
                g = true
            }
        }
        return g
    }
    
    static func loadEkEventByIdentifier(_ eventIdentifier: String) -> EKEvent? {
        return eventStore.event(withIdentifier: eventIdentifier)
    }
    
    static func loadAllEKEvents() -> [EKEvent] {
        let start = Date().advanced(by: -365 * 24 * 60 * 60)
        let end = Date().advanced(by: 365 * 24 * 60 * 60)
        return loadEKEvents(start: start, end: end)
    }
    
    static func loadEKEvents(
        start: Date,
        end: Date,
        calendars: [EKCalendar]? = nil
    ) -> [EKEvent] {
        return eventStore.events(matching: loadEKEventsPredicate(
            start,
            end,
            calendars
        ))
    }
    
    static func loadEKEventsPredicate(
        _ start: Date,
        _ end: Date,
        _ calendars: [EKCalendar]?
    ) -> NSPredicate {
        eventStore
            .predicateForEvents(
                withStart: start,
                end: end,
                calendars: calendars
            )
    }
    
    static func create(_ title: String, _ start: Date, _ end: Date) -> EKEvent {
        let ekEvent = EKEvent(eventStore: eventStore)
        ekEvent.title = title
        ekEvent.startDate = start
        ekEvent.endDate = end
        ekEvent.calendar = eventStore.defaultCalendarForNewEvents
        commit(ekEvent)
        return ekEvent
    }
    
    static func update(
        ekEvent: EKEvent,
        _ title: String,
        _ start: Date,
        _ end: Date
    ) {
        ekEvent.startDate = start
        ekEvent.endDate = end
        ekEvent.title = title
        commit(ekEvent)
    }
    
    static func deleteByIdentifier(_ eventIdentifier: String) {
        Task {
            if
                let ekEvent = eventStore
                    .event(withIdentifier: eventIdentifier)
            {
                delete(ekEvent)
            }
        }
    }
    
    static func delete(_ ekEvent: EKEvent) {
        Task {
            do {
                try eventStore.remove(ekEvent, span: .thisEvent)
            } catch {
                print("Error deleting event: \(error.localizedDescription)")
            }
        }
    }
    
    static func commit(_ ekEvent: EKEvent) {
        Task {
            try? eventStore.save(ekEvent, span: .thisEvent)
        }
    }
}

class NotificationUtil {
    static func create(
        identifier: String,
        title: String,
        body: String,
        dateMatching: DateComponents,
        repeats _: Bool
    ) {
        Task {
            delete(identifier)
            let content = UNMutableNotificationContent()
            content.title = title
            content.body = body
            
            let trigger = UNCalendarNotificationTrigger(
                dateMatching: dateMatching,
                repeats: false
            )
            
            let request = UNNotificationRequest(
                identifier: identifier,
                content: content,
                trigger: trigger
            )
            let notificationCenter = UNUserNotificationCenter.current()
            try? await notificationCenter.add(request)
        }
    }
    
    static func delete(_ identifier: String) {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(
                withIdentifiers: [identifier]
            )
    }
}
