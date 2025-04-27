import SwiftUI

struct ItemList: View {
    var animation: Namespace.ID
    var dayEvents: [Item]
    var noAllDayEvents: [Item]
    var body: some View {
        if dayEvents.isNotEmpty {
            ForEach(dayEvents, id: \.id) { item in
                HStack {
                    Text(item.text)
                    Spacer()
                }
                .fontWeight(.ultraLight)
            }
        }

        ItemDisclosures(
            animation: animation,
            defaultExpanded: false,
            items: noAllDayEvents
        )
    }
}
