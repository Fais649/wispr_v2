//
//  Calendar.swift
//  wispr
//
//  Created by Faisal Alalaiwat on 29.03.25.
//

import SwiftUI

struct CalendarData: Identifiable, Codable {
    var id: String { identifier }
    let name: String
    let identifier: String
    var enabled: Bool
}

//class Calendars: Identifiable {
//    var id: UUID = .init()
//    static let shared = Calendars()
//
//    private let userDefaults = UserDefaults.standard
//    private(set) var enabled: [CalendarData]
//    private(set) var disabled: [CalendarData]
//
//    private init() {
//        enabled = (try? JSONDecoder().decode(
//            [CalendarData].self,
//            from: userDefaults.data(forKey: "enabledCalendars") ?? Data()
//        )) ?? []
//        disabled = (try? JSONDecoder().decode(
//            [CalendarData].self,
//            from: userDefaults.data(forKey: "disabledCalendars") ?? Data()
//        )) ?? []
//    }
//
//    private func save() {
//        if let encodedEnabled = try? JSONEncoder().encode(enabled) {
//            userDefaults.set(encodedEnabled, forKey: "enabledCalendars")
//        }
//        if let encodedDisabled = try? JSONEncoder().encode(disabled) {
//            userDefaults.set(encodedDisabled, forKey: "disabledCalendars")
//        }
//    }
//
//    static func enable(_ calendar: CalendarData) {
//        var c = calendar
//        c.enabled = true
//        shared.enabled.append(c)
//        shared.disabled.removeAll { $0.identifier == calendar.identifier }
//        shared.save()
//    }
//
//    static func disable(_ calendar: CalendarData) {
//        var c = calendar
//        c.enabled = false
//        shared.disabled.append(c)
//        shared.enabled.removeAll { $0.identifier == calendar.identifier }
//        shared.save()
//    }
//
//    static func getAllCalendars() -> [CalendarData] {
//        let sortedEnabled = shared.enabled.sorted { $0.name < $1.name }
//        let sortedDisabled = shared.disabled.sorted { $0.name < $1.name }
//        return sortedEnabled + sortedDisabled
//    }
//}
