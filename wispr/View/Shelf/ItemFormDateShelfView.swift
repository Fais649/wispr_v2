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
        let calendar = Calendar.current
        if calendar.isDate(date, inSameDayAs: start) {
            return date.formatted(.dateTime.hour().minute())
        } else {
            let daysDifference = calendar.dateComponents(
                [.day],
                from: calendar.startOfDay(for: start),
                to: calendar.startOfDay(for: date)
            ).day ?? 0
            return date
                .formatted(.dateTime.hour().minute()) + "+\(daysDifference)"
        }
    }

    func title() -> some View {
        Text("Date & Time")
    }

    var todayDate: Date {
        Calendar.current.roundToNearestHalfHour(Date())
    }

    var body: some View {
        Screen(
            .dateShelf,
            loaded: true,
            title: title
        ) {
            DatePicker(
                "",
                selection: editingDate == .start ? $start : $end,
                displayedComponents: isEvent ? [.date, .hourAndMinute] : [.date]
            )
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
            .tint(theme.activeTheme.backgroundMaterialOverlay)

            HStack(spacing: Spacing.l) {
                ToolbarButton {
                    if eventFormData == nil {
                        start = Calendar.current.roundToNearestHalfHour(start)
                        end = start.advanced(by: duration)

                        withAnimation {
                            eventFormData = EventData.FormData(
                                startDate: start,
                                endDate: end
                            )
                        }
                    } else {
                        withAnimation {
                            eventFormData = nil
                        }
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
            }.padding(Spacing.m)

            HStack(spacing: Spacing.l) {
                ToolbarButton {
                    withAnimation {
                        start = Calendar.current
                            .previousDay(for: todayDate)
                    }
                } label: {
                    Text("Yesterday")
                }

                ToolbarButton {
                    withAnimation {
                        start = todayDate
                    }
                } label: {
                    Text("Today")
                }

                ToolbarButton {
                    withAnimation {
                        start = Calendar.current
                            .nextDay(for: todayDate)
                    }
                } label: {
                    Text("Tomorrow")
                }
            }.padding(Spacing.m)
                .padding(.bottom, Spacing.m)
        }
        .padding(.top, Spacing.m)
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
