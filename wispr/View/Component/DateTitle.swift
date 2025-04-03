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
        AniButton(padding: Spacing.none) {
            navigationStateService.activeDate = date
            navigationStateService.goToDayScreen()
        } label: {
            HStack {
                Text(dateStringLeading ?? date.formatted(
                    date: .abbreviated,
                    time: .omitted
                ))

                Spacer()
            }
        }
        .allowsHitTesting(!navigationStateService.onDayScreen)
        .scrollTransition(enabled: scrollTransition)
    }
}

struct DateSubTitleLabel: View {
    @Environment(
        NavigationStateService
            .self
    ) private var navigationStateService: NavigationStateService
    var date: Date

    var formattedDate: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today"
        }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        formatter.dateTimeStyle = .named
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    var body: some View {
        Text(formattedDate)
    }
}

struct DateTitleWithDivider: View {
    var date: Date

    var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }

    var body: some View {
        VStack {
            SimpleDvider()
                .frame(height: isToday ? 1 : 0.5)
                .mask {
                    if isToday {
                        LinearGradient(
                            gradient: Gradient(stops: [
                                .init(
                                    color: .black,
                                    location: 0
                                ),
                                .init(
                                    color: .black,
                                    location: 0.8
                                ),
                                .init(
                                    color: .clear,
                                    location: 1.0
                                ),
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    } else {
                        LinearGradient(
                            gradient: Gradient(stops: [
                                .init(
                                    color: .black,
                                    location: 0
                                ),

                                .init(
                                    color: .black,
                                    location: 0.5
                                ),
                                .init(
                                    color: .clear,
                                    location: 0.7
                                ),
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    }
                }
                .overlay(alignment: .leading) {
                    if isToday {
                        Image(systemName: "asterisk")
                            .decorationFontStyle()
                            .offset(x: -Spacing.m)
                    }
                }
            DateTitle(date: date, scrollTransition: false)
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
