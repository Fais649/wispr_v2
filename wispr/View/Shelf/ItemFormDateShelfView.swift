//
//  ItemFormDateShelfView.swift
//  wispr
//
//  Created by Faisal Alalaiwat on 29.03.25.
//
import SwiftUI

struct ItemFormDateShelfView: ItemDateShelfView {
    @Environment(\.modelContext) private var modelContext
    @Binding var eventFormData: EventData.FormData?

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

    init(_ eventFormData: Binding<EventData.FormData?>, _ timestamp: Date) {
        _eventFormData = eventFormData
        let st = timestamp
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
            .frame(width: 340, height: 380)
            .datePickerStyle(.graphical)
            .onChange(of: start) {
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

    var label: some View {
        Text(start.formatted(date: .abbreviated, time: .omitted))
    }
}
