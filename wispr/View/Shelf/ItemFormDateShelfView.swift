//
//  ItemFormDateShelfView.swift
//  wispr
//
//  Created by Faisal Alalaiwat on 29.03.25.
//
import SwiftUI

struct ItemFormDateShelfView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(ThemeStateService.self) private var theme: ThemeStateService
    @Binding var eventFormData: EventData.FormData?
    @Binding var timestamp: Date

    @State var start: Date
    @State var duration: TimeInterval
    @State var end: Date

    var isEvent: Bool {
        eventFormData != nil
    }

    @State var editingDate: EditingDate = .start
    enum EditingDate {
        case start, end

        var label: String {
            switch self {
                case .start:
                    "Start:"
                case .end:
                    "End:"
            }
        }
    }

    init(
        _ eventFormData: Binding<EventData.FormData?>,
        _ timestamp: Binding<Date>
    ) {
        _eventFormData = eventFormData
        _timestamp = timestamp
        let st = timestamp.wrappedValue
        let en = st.advanced(by: 3600)
        start = st
        end = en
        duration = 3600
    }

    func formattedDate(_ date: Date) -> String {
        date
            .formatted(
                .dateTime.day(.twoDigits)
                    .month(.twoDigits).year(.twoDigits)
                    .hour()
                    .minute()
            )
    }

    var body: some View {
        VStack {
            DatePicker(
                "",
                selection: editingDate == .start ? $start : $end,
                displayedComponents: isEvent ? [.date, .hourAndMinute] : [.date]
            )
            .tint(theme.activeTheme.backgroundMaterialOverlay)
            .frame(width: 340, height: 380)
            .datePickerStyle(.graphical)
            .onChange(of: start) {
                timestamp = start
                end = start.advanced(by: duration)
            }.onChange(of: end) {
                if end < start {
                    start = end.advanced(by: -duration)
                }
                duration = end.timeIntervalSince(start)
            }

            HStack {
                if !isEvent {
                    Spacer()
                }

                ToolbarButton {
                    if eventFormData == nil {
                        eventFormData = EventData.FormData(
                            startDate: start,
                            endDate: end
                        )
                    } else {
                        eventFormData = nil
                    }
                } label: {
                    Image(
                        systemName: isEvent ? "clock.badge.xmark.fill" :
                            "clock"
                    )
                }

                if isEvent {
                    Picker("", selection: $editingDate) {
                        ToolbarButton {
                            Text(formattedDate(start))
                        }.tag(EditingDate.start)

                        ToolbarButton {
                            Text(formattedDate(end))
                        }.tag(EditingDate.end)
                    }.pickerStyle(.segmented)
                        .labelsHidden()
                }
            }
        }
        .padding(Spacing.m).frame(height: 420)
        .onAppear {
            if let eventFormData {
                start = eventFormData.startDate
                end = eventFormData.endDate
                duration = end.timeIntervalSince(start)
            }
        }
        .onDisappear {
            if var e = eventFormData {
                e.startDate = start
                e.endDate = end
                eventFormData = e
            }
        }
    }
}

struct ItemFormDateShelfLabelView: View {
    @Environment(ThemeStateService.self) private var theme: ThemeStateService
    @Environment(
        NavigationStateService
            .self
    ) var navigationStateService: NavigationStateService

    @Binding var date: Date

    var showActiveDayButton: Bool {
        !Calendar.current.isDate(
            navigationStateService.activeDate,
            inSameDayAs:
            date
        )
    }

    var dateShelfShown: Bool {
        navigationStateService.shelfState.isDatePicker()
    }

    var body: some View {
        HStack {
            if showActiveDayButton {
                ToolbarButton(
                    toggledOn: dateShelfShown
                ) {
                    date = navigationStateService.activeDate
                } label: {
                    Image(systemName: "dot.square")
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.white, .clear)
                        .buttonFontStyle()
                }
            }

            ToolbarButton(
                toggledOn: dateShelfShown,
                clipShape: Capsule()
            ) {
                navigationStateService.toggleDatePickerShelf()
            } label: {
                Text(
                    date
                        .formatted(
                            .dateTime.day().month(.twoDigits)
                                .year(.twoDigits)
                        )
                )
            }
            .onChange(of: navigationStateService.activePath) {
                withAnimation {
                    navigationStateService.closeShelf()
                }
            }
            .onChange(of: date) {
                withAnimation {
                    navigationStateService.closeShelf()
                }
            }
        }
        .background {
            if !dateShelfShown {
                Capsule().fill(theme.activeTheme.backgroundMaterialOverlay)
                    .blur(radius: dateShelfShown ? 50 : 0)
                    .blendMode(.luminosity)
            }
        }
    }
}
