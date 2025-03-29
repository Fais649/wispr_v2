//
//  Widget.swift
//  wispr
//
//  Created by Faisal Alalaiwat on 11.02.25.
//

import AppIntents
import SwiftData
import SwiftUI
import WidgetKit

struct WidgetView: View {
    @Environment(\.modelContext) private var modelContext: ModelContext
    @Environment(\.widgetFamily) var family
    var entry: Provider.Entry

    var body: some View {
        switch family {
            case .systemLarge:
                LargeWidget()

            case .systemMedium:
                MediumWidget()

            default:
                SmallWidget()
        }
    }
}

struct SmallWidget: View {
    var body: some View {
        Text("smol")
    }
}

struct LargeWidget: View {
    @Query var items: [Item]

    var todaysItems: [Item] {
        let cal = Calendar.current
        let start = cal.startOfDay(for: Date())
        let end = start.advanced(by: 86400)
        return items
            .filter {
                start < $0.timestamp && $0.timestamp < end && $0.parent == nil
            }
            .sorted(by: { first, second in first.position < second.position })
    }

    var activeDate: Date {
        return Calendar.current.startOfDay(for: Date())
    }

    var todayDate: Date {
        return Calendar.current.startOfDay(for: Date())
    }

    var body: some View {
        Text("lol")
    }
}

struct WidgetItemList: View {
    @Environment(\.modelContext) private var modelContext: ModelContext
    var items: [Item]

    var body: some View {
        VStack {
            ForEach(items.prefix(6), id: \.self) { item in
                if item.children.isEmpty {
                    itemRow(item)
                } else {
                    Button(intent: ShowItemChildren(
                        item: item
                            .defaultIntentParameter
                    )) {
                        HStack {
                            itemRow(item)
                            Image(systemName: "chevron.right")
                        }
                    }
                }
            }
            Spacer()
        }.padding()
    }

    @ViewBuilder
    func itemRow(_ item: Item) -> some View {
        WidgetItemRowLabel(item: item)
    }
}

struct MediumWidget: View {
    @Query var items: [Item]
    @State var date: Date = .init()

    var events: [Item] {
        let cal = Calendar.current
        let start = cal.startOfDay(for: date)
        let end = start.advanced(by: 86400)
        return items
            .filter {
                $0
                    .eventData != nil &&
                    (start < $0.timestamp && $0.timestamp < end)
            }
    }

    var tasks: [Item] {
        let cal = Calendar.current
        let start = cal.startOfDay(for: date)
        let end = start.advanced(by: 86400)
        return items
            .filter {
                $0
                    .taskData != nil &&
                    (start < $0.timestamp && $0.timestamp < end)
            }
    }

    var notes: [Item] {
        let cal = Calendar.current
        let start = cal.startOfDay(for: date)
        let end = start.advanced(by: 86400)
        return items
            .filter {
                $0.taskData == nil && $0
                    .eventData == nil &&
                    (start < $0.timestamp && $0.timestamp < end)
            }
    }

    var body: some View {
        VStack {
            Spacer()
            GeometryReader { geo in
                HStack {
                    VStack(spacing: 4) {
                        if tasks.isEmpty {
                            HStack {
                                Text("No Tasks")
                                    .foregroundStyle(.gray)
                            }
                        }
                        ForEach(tasks) { item in
                            WidgetItemRowLabel(item: item)
                        }
                        Spacer()
                    }.frame(width: geo.size.width * 0.32)

                    VStack(spacing: 4) {
                        if events.isEmpty {
                            Text("No Events")
                                .frame(alignment: .center)
                                .foregroundStyle(.gray)
                        }
                        ForEach(events) { item in
                            WidgetItemRowLabel(item: item)
                        }
                    }.frame(width: geo.size.width * 0.667)
                }
            }
            Spacer()

            HStack {
                Spacer()
            }
        }.padding(3)
            .padding(.horizontal, 6)
            .overlay(alignment: .topLeading) {
                HStack(alignment: .top) {
                    Image("Logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 8, height: 8) // Set desired frame
                    Text(date.formatted(date: .abbreviated, time: .omitted))
                        .frame(alignment: .top)
                        .foregroundStyle(.white)
                    Spacer()
                }
            }
    }
}

struct WidgetItemRowLabel: View {
    @Environment(\.modelContext) private var modelContext: ModelContext
    @State var item: Item

    func isActiveItem(_ item: Item, _ date: Date) -> Bool {
        if let eventData = item.eventData {
            return eventData.startDate <= date && date < eventData
                .endDate && item.taskData?.completedAt == nil
        } else {
            return false
        }
    }

    func isEventPast(_ item: Item, _ date: Date) -> Bool {
        if let eventData = item.eventData {
            return date > eventData.endDate
        } else {
            return false
        }
    }

    var body: some View {
        HStack {
            TimelineView(.everyMinute) { time in
                HStack {
                    WidgetTaskDataRowLabel(item: $item)
                    WidgetNoteDataRowLabel(item: $item)
                    WidgetEventDataRowLabel(item: $item, currentTime: time.date)
                }
                .padding(4)
                .frame(alignment: .bottom)
                .foregroundStyle(
                    isActiveItem(item, time.date) ? .black :
                        .white
                )
                .foregroundStyle(isEventPast(item, time.date) ? .gray : .white)
                .background(isActiveItem(item, time.date) ? .white : .black)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
    }
}

struct WidgetTaskDataRowLabel: View {
    @Environment(\.modelContext) private var modelContext: ModelContext
    @Binding var item: Item

    var body: some View {
        if item.isTask {
            Button(intent: ToggleTaskCompletionIntent(
                task: item
                    .defaultIntentParameter
            )) {
                Image(
                    systemName: item.taskData?
                        .completedAt == nil ? "circle.dotted" : "circle.fill"
                )
            }.background(.clear).buttonStyle(.plain)
                .onChange(of: item.taskData?.completedAt) {
                    WidgetCenter.shared.reloadAllTimelines()
                }
        }
    }
}

struct WidgetNoteDataRowLabel: View {
    @Binding var item: Item

    var body: some View {
        Button(intent: EditItemIntent(item: item.defaultIntentParameter)) {
            HStack {
                Text(item.text)
                Spacer()
            }
        }
        .widgetURL(URL(string: "wispr//EditItem"))
        .buttonStyle(.plain)
        .scaleEffect(
            item.taskData?.completedAt != nil ? 0.8 : 1,
            anchor: .leading
        )
    }
}

struct WidgetEventDataRowLabel: View {
    @Binding var item: Item
    let currentTime: Date

    func isActiveItem(_ item: Item, _ date: Date) -> Bool {
        if let eventData = item.eventData {
            return eventData.startDate <= date && date < eventData
                .endDate && item.taskData?.completedAt == nil
        } else {
            return false
        }
    }

    var formatter: RelativeDateTimeFormatter {
        let formatter =
            RelativeDateTimeFormatter()
        return formatter
    }

    func format(_ date: Date, _: Date) -> String {
        return formatter.localizedString(for: date, relativeTo: .now)
    }

    var body: some View {
        if let eventData = item.eventData {
            Button(intent: EditItemIntent(item: item.defaultIntentParameter)) {
                VStack {
                    HStack {
                        Spacer()
                        Text(
                            eventData.startDate
                                .formatted(.dateTime.hour().minute())
                        )
                        .scaleEffect(
                            isActiveItem(item, currentTime) ? 0.8 : 1,
                            anchor: .bottomTrailing
                        )
                    }
                    HStack {
                        Spacer()
                        if isActiveItem(item, currentTime) {
                            Image(systemName: "timer")
                        }
                        Text(
                            eventData.endDate
                                .formatted(.dateTime.hour().minute())
                        )
                    }
                }
            }
            .widgetURL(URL(string: "wispr//EditItem"))
            .buttonStyle(.plain)
        }
    }
}

struct OpenAppIntent: AppIntent {
    static var title: LocalizedStringResource = "Launch App"
    static let openAppWhenRun: Bool = true

    init() {}

    func perform() async throws -> some IntentResult {
        return .result()
    }
}

struct OpenOnDateIntent: AppIntent {
    static var title: LocalizedStringResource = "Open on Date"
    static let openAppWhenRun: Bool = true

    @Parameter
    var date: Date

    @MainActor
    func perform() async throws -> some IntentResult {
        return .result()
    }
}

struct ShowTodayIntent: AppIntent {
    static var title: LocalizedStringResource = "Go to tomorrow"

    @MainActor
    func perform() async throws -> some IntentResult {
        return .result()
    }
}

struct ShowTomorrowIntent: AppIntent {
    static var title: LocalizedStringResource = "Go to tomorrow"

    @Parameter
    var date: Date

    @MainActor
    func perform() async throws -> some IntentResult {
        return .result()
    }
}

struct ShowYesterdayIntent: AppIntent {
    static var title: LocalizedStringResource = "Go to tomorrow"

    @Parameter
    var date: Date

    @MainActor
    func perform() async throws -> some IntentResult {
        return .result()
    }
}

struct ShowItemChildren: AppIntent {
    static var title: LocalizedStringResource = "Go to tomorrow"

    @Parameter(title: "Item")
    var item: Item

    @MainActor
    func perform() async throws -> some IntentResult {
        return .result()
    }
}

struct NewTaskIntent: AppIntent {
    static var title: LocalizedStringResource = "New Task"
    static let openAppWhenRun: Bool = true

    @Parameter
    var date: Date

    @MainActor
    func perform() async throws -> some IntentResult {
        return .result()
    }

    @MainActor
    func createNewItem() {
        let context = SharedState.sharedModelContainer.mainContext
        let items = getItems(context)
    }

    @MainActor
    func getItems(_: ModelContext) -> [Item] {
        return ItemStore.byDay(date: date) ?? []
    }
}

struct EditItemIntent: AppIntent {
    static var title: LocalizedStringResource = "Edit Item"
    static let openAppWhenRun: Bool = true

    @Parameter(title: "Item")
    var item: Item

    @MainActor
    func perform() async throws -> some IntentResult {
        return .result()
    }
}

struct ToggleTaskCompletionIntent: AppIntent {
    static var title: LocalizedStringResource = "Toggle Task Completion"

    @Parameter(title: "Item")
    var task: Item

    @MainActor
    func perform() async throws -> some IntentResult {
        let context = SharedState.sharedModelContainer.mainContext
        if task.taskData?.completedAt == nil {
            task.taskData?.completedAt = Date()
        } else {
            task.taskData?.completedAt = nil
        }

        context.insert(task)
        try context.save()

        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}
