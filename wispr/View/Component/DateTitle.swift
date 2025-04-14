import SwiftData
import SwiftUI

struct DateTitle: View {
    @Environment(
        NavigationStateService
            .self
    ) private var navigationStateService: NavigationStateService
    @Environment(ThemeStateService.self) private var theme: ThemeStateService

    var date: Date
    var scrollTransition: Bool = true
    var dateStringLeading: String? = nil

    var body: some View {
        Text(dateStringLeading ?? date.formatted(
            date: .abbreviated,
            time: .omitted
        ))

        .scrollTransition(enabled: scrollTransition)
    }
}

struct DateTrailingTitleLabel: View {
    @Environment(
        NavigationStateService
            .self
    ) private var navigationStateService: NavigationStateService
    var date: Date

    var formattedDate: String {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let targetDay = calendar.startOfDay(for: date)

        let dayDifference = calendar.dateComponents(
            [.day],
            from: today,
            to: targetDay
        ).day ?? 0

        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        formatter.dateTimeStyle = .named

        return formatter
            .localizedString(from: DateComponents(day: dayDifference))
            .localizedCapitalized
    }

    var body: some View {
        Text(formattedDate)
    }
}

struct DateTitleWithDivider: View {
    var date: Date
    var trailing: () -> AnyView = { AnyView(EmptyView()) }
    var subtitle: () -> AnyView = { AnyView(EmptyView()) }

    var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }

    var body: some View {
        VStack(spacing: Spacing.none) {
            HStack(alignment: .firstTextBaseline) {
                DateTitle(date: date, scrollTransition: false)
                Spacer()
                trailing()
            }.multilineTextAlignment(.trailing)

            SimpleDvider()
                .background(.ultraThinMaterial)
                .overlay(alignment: .trailing) {
                    if isToday {
                        Image(systemName: "circle.fill")
                            .toolbarFontStyle()
                            .offset(x: Spacing.l + Spacing.m)
                            .scaleEffect(0.4)
                    }
                }

            HStack {
                subtitle()
                Spacer()
            }
        }
    }
}

struct SimpleDvider: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 1)
            .frame(height: 1)
    }
}

struct FadedDivider: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 0.5)
            .frame(height: 0.5)
            .mask {
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(
                            color: .clear,
                            location: 0
                        ),

                        .init(
                            color: .black,
                            location: 0.5
                        ),
                        .init(
                            color: .clear,
                            location: 1
                        ),
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            }
    }
}
