import SwiftUI

struct ItemRowLabel: View {
    @Environment(NavigationStateService.self) var navigationState
    var item: Item
    var editOnClick: Bool = true

    func formattedDate(from d: Date, _ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDate(date, inSameDayAs: d) {
            return date.formatted(.dateTime.hour().minute())
        } else {
            let daysDifference = calendar.dateComponents(
                [.day],
                from: calendar.startOfDay(for: d),
                to: calendar.startOfDay(for: date)
            ).day ?? 0
            return date
                .formatted(.dateTime.hour().minute()) + "+\(daysDifference)"
        }
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                HStack(alignment: .firstTextBaseline) {
                    if item.isTask {
                        Image(
                            systemName: item
                                .isTaskCompleted ? "square.fill" :
                                "square.dotted"
                        )
                        .buttonFontStyle()
                        .scaleEffect(0.9, anchor: .bottom)
                    }

                    if item.isParent {
                        Text(item.text)
                            .truncationMode(.tail)
                            .lineLimit(1)
                            .onTapGesture {
                                navigationState.goToItemForm(item)
                            }.allowsHitTesting(editOnClick)
                    } else {
                        Text(item.text)
                            .multilineTextAlignment(.leading)
                    }
                }

                if item.isParent {
                    if let e = item.eventData, !e.allDay {
                        HStack(spacing: 0) {
                            Text(formattedDate(from: e.startDate, e.startDate))
                                .eventTimeFontStyle()
                            Text("-")
                                .eventTimeFontStyle()
                            Text(formattedDate(from: e.startDate, e.endDate))
                                .eventTimeFontStyle()
                        }
                        .onTapGesture {
                            navigationState.goToItemForm(item)
                        }.allowsHitTesting(editOnClick)
                    }
                }
            }
            Spacer()
        }
        .contentShape(Rectangle())
    }
}
