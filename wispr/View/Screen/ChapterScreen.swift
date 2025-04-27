import SwiftData
import SwiftUI

struct ChapterScreen: View {
    var animation: Namespace.ID
    var name: String
    var items: [Item]

    var backgroundOpacity: CGFloat = 0.5
    var parentItems: [Item] {
        items.filter { $0.isParent && !$0.archived }
    }

    var body: some View {
        Screen(
            .dayScreen,
            loaded: true,
            title: {
                Text(name)
            },
            trailingTitle: {
                Text(parentItems.count.description)
            },
            backgroundOpacity: backgroundOpacity
        ) {
            VStack {
                ItemList(
                    animation: animation,
                    dayEvents: [],
                    noAllDayEvents: parentItems
                )
            }
        }
    }
}
