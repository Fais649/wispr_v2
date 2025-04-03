
import EventKit
import SwiftData
import SwiftUI

@Observable
class CalendarSyncService {
    private static let eventStore: EKEventStore = .init()
    private var synced: Bool = false

    static func create(_ title: String, _ start: Date, _ end: Date) -> EKEvent {
        let ekEvent = EKEvent(eventStore: eventStore)
        ekEvent.title = title
        ekEvent.startDate = start
        ekEvent.endDate = end
        ekEvent.calendar = eventStore.defaultCalendarForNewEvents
        return ekEvent
    }

    static func update(
        ekEvent: EKEvent,
        _ title: String,
        _ start: Date,
        _ end: Date
    ) {
        ekEvent.title = title
        ekEvent.startDate = start
        ekEvent.endDate = end
        Task {
            commit(ekEvent)
        }
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

    static func commit(_ ekEvent: EKEvent) -> EKEvent {
        try? eventStore.save(ekEvent, span: .thisEvent)
        return ekEvent
    }

    func requestAccessToCalendar() async {
        CalendarSyncService.eventStore.requestFullAccessToEvents { granted, error in
            if granted, error == nil {
                self.synced = true
            }
        }
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

    static func loadAllEKEvents() -> [EKEvent] {
        let start = Date().advanced(by: -365 * 24 * 60 * 60)
        let end = Date().advanced(by: 365 * 24 * 60 * 60)
        return loadEKEvents(start: start, end: end)
    }

    static func loadAllEKEvents(for eventCalendars: [EventCalendar])
        -> [EKEvent]
    {
        let start = Date().advanced(by: -365 * 24 * 60 * 60)
        let end = Date().advanced(by: 365 * 24 * 60 * 60)
        let ekCalendars = loadEKCalendars(for: eventCalendars)
        return loadEKEvents(start: start, end: end, calendars: ekCalendars)
    }

    static func loadAllEKEvents(for eventCalendar: EventCalendar)
        -> [EKEvent]
    {
        let start = Date().advanced(by: -365 * 24 * 60 * 60)
        let end = Date().advanced(by: 365 * 24 * 60 * 60)
        let ekCalendar = loadEKCalendar(for: eventCalendar)
        if let ekCalendar {
            return loadEKEvents(start: start, end: end, calendars: [ekCalendar])
        } else {
            return []
        }
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

    static func loadEKCalendars(for eventCalendars: [EventCalendar])
        -> [EKCalendar]
    {
        return eventStore.calendars(for: .event).filter { ekCalendar in
            eventCalendars.map { $0.identifier }
                .contains(ekCalendar.calendarIdentifier)
        }
    }

    static func loadEKCalendar(for eventCalendar: EventCalendar)
        -> EKCalendar?
    {
        return eventStore.calendars(for: .event).filter { ekCalendar in
            eventCalendar.identifier == ekCalendar.calendarIdentifier
        }.first
    }

    static func loadEkEventByIdentifier(_ eventIdentifier: String) -> EKEvent? {
        return eventStore.event(withIdentifier: eventIdentifier)
    }

    static func ekEventExists(for eventIdentifier: String) -> Bool {
        return loadEkEventByIdentifier(eventIdentifier) != nil
    }

    static func loadAllEKCalendars() -> [EKCalendar] {
        eventStore.calendars(for: .event).sorted(using: SortDescriptor(\.title))
    }

    static func syncCalendars() async {
        let ekCalendars = loadAllEKCalendars()
        let eventCalendars = await EventCalendarStore.loadCalendars()
        let eventCalendarIdentifiers = eventCalendars.map { $0.identifier }

        let newCalendars =
            ekCalendars.filter {
                !eventCalendarIdentifiers.contains($0.calendarIdentifier)
            }

        for new in newCalendars {
            let newCal = EventCalendarStore.create(from: new)
            await EventCalendarStore.insert(newCal)
        }
    }

    @MainActor
    func sync() async {
        await requestAccessToCalendar()
        if !synced {
            return
        }

        await CalendarSyncService.syncCalendars()
            let eventCalendars = EventCalendarStore.loadEnabledCalendars()
            let ekEvents = CalendarSyncService
                .loadAllEKEvents(for: eventCalendars)

            let ekEventsDict: [Date: [EKEvent]] = Dictionary(
                grouping: ekEvents,
                by: { Calendar.current.startOfDay(for: $0.startDate) }
            )

            let items = ItemStore.loadEventItems()
            for (date, ekEvents) in ekEventsDict {
                for e in ekEvents {
                    let item = items
                        .filter {
                            $0.eventData?.eventIdentifier == e
                                .eventIdentifier
                        }
                        .first ?? Item()

                    let eventData = EventData(from: e)
                    item.commit(
                        timestamp: date,
                        text: e.title,
                        taskData: nil,
                        eventFormData: eventData.formData(),
                        tags: [],
                        children: [],
                        syncEkEvent: false
                    )
                }
        }
    }

     func sync(for eventCalendar: EventCalendar) async {
        await requestAccessToCalendar()
        if !synced {
            return
        }

        let ekEvents = CalendarSyncService
            .loadAllEKEvents(for: eventCalendar)

        let ekEventsDict: [Date: [EKEvent]] = Dictionary(
            grouping: ekEvents,
            by: { Calendar.current.startOfDay(for: $0.startDate) }
        )

        let items = await ItemStore.loadEventItems()
        for (date, ekEvents) in ekEventsDict {
            for e in ekEvents {
                let item = items
                    .filter {
                        $0.eventData?.eventIdentifier == e
                            .eventIdentifier
                    }
                    .first ?? Item()

                let eventData = EventData(from: e)
                await item.commit(
                    timestamp: date,
                    text: e.title,
                    taskData: nil,
                    eventFormData: eventData.formData(),
                    tags: [],
                    children: [],
                    syncEkEvent: false
                )
            }
        }
    }
}

// class CalendarService {
//
//    func createEkEvent(
//        title: String,
//        start: Date,
//        end: Date
//    ) -> EKEvent? {
//        if authorizeCalendarAccess() {
//            return CalendarSyncService.create(title, start, end)
//        }
//        return nil
//    }
//
//    func updateEKEvent(_ title: String, _ eventData: EventData) {
//        if
//            authorizeCalendarAccess(),
//            let ekEvent = CalendarSyncService
//                .loadEkEventByIdentifier(eventData.eventIdentifier ?? "")
//        {
//            CalendarSyncService.update(
//                ekEvent: ekEvent,
//                title,
//                eventData.startDate,
//                eventData.endDate
//            )
//        }
//    }
//
//    func deleteEKEvent(_ ekEvent: EKEvent) {
//        if authorizeCalendarAccess() {
//            CalendarSyncService.delete(ekEvent)
//        }
//    }
//
//    private func authorizeCalendarAccess() -> Bool {
//        if !calendarAccess {
//            calendarAccess = CalendarSyncService.requestAccessToCalendar()
//        }
//        return calendarAccess
//    }
//
//    func syncCalendar(modelContext: ModelContext) {
//        if synced { return }
//
//        Task {
//            let es = CalendarSyncService.loadAllEKEvents()
//            let eDict: [Date: [EKEvent]] = Dictionary(
//                grouping: es,
//                by: { Calendar.current.startOfDay(for: $0.startDate) }
//            )
//
//            let desc = FetchDescriptor<Item>()
//            guard let evs = try? modelContext.fetch(desc)
//            else {
//                return
//            }
//
//            let items = evs.filter { $0.eventData != nil }
//
//            let eventsDict: [Date: [Item]] = Dictionary(
//                grouping: items,
//                by: { if let ed = $0.eventData {
//                    return Calendar.current.startOfDay(for: ed.startDate)
//                }
//                    return Calendar.current.startOfDay(for: Date())
//                }
//            )
//
//            for (date, es) in eDict {
//                for e in es {
//                    if
//                        let item = items
//                            .filter({
//                                $0.eventData?.eventIdentifier == e
//                                    .eventIdentifier
//                            })
//                            .first,
//                        var eventData = item.eventData
//                    {
//                        eventData.startDate = e.startDate
//                        eventData.endDate = e.endDate
//                        eventData.calendarIdentifier = e.calendar
//                            .calendarIdentifier
//                        item.eventData = eventData
//                        item.text = e.title
//                    } else {
//                        let newItem = Item(
//                            position: eventsDict[Calendar.current
//                                .startOfDay(for: date)]?.count ?? 0,
//                            timestamp: date
//                        )
//                        newItem.text = e.title
//                        newItem.eventData = EventData(from: e)
//                        modelContext.insert(newItem)
//                    }
//                }
//            }
//
//            try? modelContext.save()
//
//            synced = true
//        }
//    }
// }
