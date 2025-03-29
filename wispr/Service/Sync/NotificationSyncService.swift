import SwiftData
import SwiftUI

class NotificationSyncService {
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
