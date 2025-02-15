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
                .font(.custom("GohuFont11NFM", size: 16))

        case .systemMedium:
            MediumWidget()
                .font(.custom("GohuFont11NFM", size: 12))

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
    @Environment(WidgetConductor.self) private var widgetConductor: WidgetConductor
    @Query var items: [Item]

    var todaysItems: [Item] {
        let cal = Calendar.current
        let start = cal.startOfDay(for: widgetConductor.date)
        let end = start.advanced(by: 86400)
        return items.filter { start < $0.timestamp && $0.timestamp < end && $0.parent == nil }.sorted(by: { first, second in first.position < second.position })
    }

    var activeDate: Date {
        return Calendar.current.startOfDay(for: widgetConductor.date)
    }

    var todayDate: Date {
        return Calendar.current.startOfDay(for: Date())
    }

    var body: some View {
        Button(intent: OpenOnDateIntent(date: widgetConductor.date.defaultIntentParameter)) {
            VStack {
                VStack {
                    Spacer()
                    if let parent = widgetConductor.parentItem, let itm = items.filter({ $0.id == parent.id }).first {
                        HStack {
                            VStack {
                                WidgetItemRowLabel(item: itm)
                                ForEach(itm.children.prefix(6)) { child in
                                    WidgetItemRowLabel(item: child)
                                        .padding(.leading, 40)
                                }
                            }
                        }
                    } else {
                        HStack {
                            if todaysItems.isEmpty {
                                Spacer()
                                Text(
                                    """
                                    Nothing planned...
                                    (loser)
                                    """)
                                    .foregroundStyle(.white)
                                Spacer()
                            } else {
                                VStack {
                                    ForEach(todaysItems.prefix(6), id: \.self) { item in
                                        if item.children.isEmpty {
                                            WidgetItemRowLabel(item: item)
                                        } else {
                                            Button(intent: ShowItemChildren(item: item.defaultIntentParameter)) {
                                                HStack {
                                                    WidgetItemRowLabel(item: item)
                                                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                                                        .rotationEffect(.degrees(90))
                                                }
                                            }.buttonStyle(.plain).foregroundStyle(.white)
                                        }
                                    }
                                    Spacer()
                                }.padding()
                            }
                        }
                        Spacer()
                    }
                }.overlay(alignment: .topLeading) {
                    HStack {
                        let formatter = RelativeDateTimeFormatter()
                        Button(intent: ShowTodayIntent()) {
                            Image("Logo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 15, height: 15)
                        }.buttonStyle(.plain).foregroundStyle(.white)

                        Spacer()

                        if activeDate < todayDate {
                            Button(intent: OpenOnDateIntent(date: widgetConductor.date.defaultIntentParameter)) {
                                Text(formatter.localizedString(for:
                                    Calendar.current.startOfDay(for:
                                        widgetConductor.date), relativeTo:
                                    Calendar.current.startOfDay(for: Date())) + " ... ")
                            }.buttonStyle(.plain).foregroundStyle(.white)
                                .foregroundStyle(.white)
                                .frame(alignment: .center)
                        }

                        Button(intent: ShowTodayIntent()) {
                            if activeDate == todayDate {
                                Text(Date().formatted(date: .abbreviated, time: .omitted))
                            } else {
                                Image(systemName: "circle.fill")
                            }
                        }.buttonStyle(.plain).foregroundStyle(.white)
                            .foregroundStyle(.white)
                            .frame(alignment: .center)
                            .onAppear {
                                formatter.unitsStyle = .short
                            }

                        if activeDate > todayDate {
                            Button(intent: OpenOnDateIntent(date: widgetConductor.date.defaultIntentParameter)) {
                                Text(" ... " + formatter.localizedString(for:
                                    Calendar.current.startOfDay(for:
                                        widgetConductor.date), relativeTo:
                                    Calendar.current.startOfDay(for: Date())))
                            }.buttonStyle(.plain).foregroundStyle(.white)
                                .foregroundStyle(.white)
                                .frame(alignment: .center)
                        }
                    }
                }

                HStack {
                    Button(intent: ShowYesterdayIntent(date: widgetConductor.date.defaultIntentParameter)) {
                        Spacer()
                        Image(systemName: "chevron.left")
                            .padding()
                        Spacer()
                    }.buttonStyle(.plain).foregroundStyle(.white)
                        .frame(alignment: .center)

                    Button(intent: NewTaskIntent(date: widgetConductor.date.defaultIntentParameter)) {
                        Spacer()
                        Image(systemName: "plus")
                            .padding()
                        Spacer()
                    }.buttonStyle(.plain).foregroundStyle(.white)
                        .widgetURL(URL(string: "wispr//NewTask"))
                        .frame(alignment: .trailing)

                    Button(intent: ShowTomorrowIntent(date: widgetConductor.date.defaultIntentParameter)) {
                        Spacer()
                        Image(systemName: "chevron.right")
                            .padding()
                        Spacer()
                    }.buttonStyle(.plain).foregroundStyle(.white)
                        .frame(alignment: .center)
                }.padding()
            }
        }.buttonStyle(.plain)
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
                    Button(intent: ShowItemChildren(item: item.defaultIntentParameter)) {
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
    @Environment(WidgetConductor.self) private var widgetConductor: WidgetConductor
    @Query var items: [Item]
    @State var date: Date = .init()

    var events: [Item] {
        let cal = Calendar.current
        let start = cal.startOfDay(for: date)
        let end = start.advanced(by: 86400)
        return items.filter { $0.eventData != nil && (start < $0.timestamp && $0.timestamp < end) }
    }

    var tasks: [Item] {
        let cal = Calendar.current
        let start = cal.startOfDay(for: date)
        let end = start.advanced(by: 86400)
        return items.filter { $0.taskData != nil && (start < $0.timestamp && $0.timestamp < end) }
    }

    var notes: [Item] {
        let cal = Calendar.current
        let start = cal.startOfDay(for: date)
        let end = start.advanced(by: 86400)
        return items.filter { $0.taskData == nil && $0.eventData == nil && (start < $0.timestamp && $0.timestamp < end) }
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
                Button(intent: NewTaskIntent(date: widgetConductor.date.defaultIntentParameter)) {
                    Image(systemName: "plus")
                }.buttonStyle(.plain).foregroundStyle(.white)
                    .widgetURL(URL(string: "wispr//NewTask"))
            }
        }.padding(3)
            .padding(.horizontal, 6)
            .overlay(alignment: .topLeading) {
                HStack(alignment: .top) {
                    Image("Logo")
                        .resizable() // Make the image resizable if needed
                        .scaledToFit() // Adjust the content mode
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
            return eventData.startDate <= date && date < eventData.endDate && item.taskData?.completedAt == nil
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
                .foregroundStyle(isActiveItem(item, time.date) ? .black : .white)
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
            Button(intent: ToggleTaskCompletionIntent(task: item.defaultIntentParameter)) {
                Image(systemName: item.taskData?.completedAt == nil ? "square" : "square.fill")
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
                Text(item.noteData.text)
                Spacer()
            }
        }
        .widgetURL(URL(string: "wispr//EditItem"))
        .buttonStyle(.plain)
        .scaleEffect(item.taskData?.completedAt != nil ? 0.8 : 1, anchor: .leading)
    }
}

struct WidgetEventDataRowLabel: View {
    @Binding var item: Item
    let currentTime: Date

    func isActiveItem(_ item: Item, _ date: Date) -> Bool {
        if let eventData = item.eventData {
            return eventData.startDate <= date && date < eventData.endDate && item.taskData?.completedAt == nil
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
                        Text(eventData.startDate.formatted(.dateTime.hour().minute()))
                            .scaleEffect(isActiveItem(item, currentTime) ? 0.8 : 1, anchor: .bottomTrailing)
                    }
                    HStack {
                        Spacer()
                        if isActiveItem(item, currentTime) {
                            Image(systemName: "timer")
                        }
                        Text(eventData.endDate.formatted(.dateTime.hour().minute()))
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
        withAnimation {
            SharedState.widgetConductor.parentItem = nil
            SharedState.dayDetailsConductor.editItem = nil
            SharedState.widgetConductor.date = Calendar.current.startOfDay(for: date)
            SharedState.dayDetailsConductor.date = Calendar.current.startOfDay(for: date)
        }
        return .result()
    }
}

struct ShowTodayIntent: AppIntent {
    static var title: LocalizedStringResource = "Go to tomorrow"

    @MainActor
    func perform() async throws -> some IntentResult {
        withAnimation {
            SharedState.widgetConductor.parentItem = nil
            SharedState.dayDetailsConductor.editItem = nil
            SharedState.widgetConductor.date = Calendar.current.startOfDay(for: Date())
            SharedState.dayDetailsConductor.date = SharedState.widgetConductor.date
        }
        return .result()
    }
}

struct ShowTomorrowIntent: AppIntent {
    static var title: LocalizedStringResource = "Go to tomorrow"

    @Parameter
    var date: Date

    @MainActor
    func perform() async throws -> some IntentResult {
        withAnimation {
            SharedState.widgetConductor.parentItem = nil
            SharedState.dayDetailsConductor.editItem = nil
            SharedState.widgetConductor.date = Calendar.current.startOfDay(for: date.advanced(by: 86400))
            SharedState.dayDetailsConductor.date = Calendar.current.startOfDay(for: date.advanced(by: 86400))
        }
        return .result()
    }
}

struct ShowYesterdayIntent: AppIntent {
    static var title: LocalizedStringResource = "Go to tomorrow"

    @Parameter
    var date: Date

    @MainActor
    func perform() async throws -> some IntentResult {
        withAnimation {
            SharedState.widgetConductor.parentItem = nil
            SharedState.dayDetailsConductor.editItem = nil
            SharedState.widgetConductor.date = Calendar.current.startOfDay(for: date.advanced(by: -86400))
            SharedState.dayDetailsConductor.date = Calendar.current.startOfDay(for: date.advanced(by: -86400))
        }
        return .result()
    }
}

struct ShowItemChildren: AppIntent {
    static var title: LocalizedStringResource = "Go to tomorrow"

    @Parameter(title: "Item")
    var item: Item

    @MainActor
    func perform() async throws -> some IntentResult {
        withAnimation {
            SharedState.widgetConductor.parentItem = item
        }
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
        SharedState.widgetConductor.parentItem = nil
        createNewItem()
        return .result()
    }

    @MainActor
    func createNewItem() {
        let context = SharedState.sharedModelContainer.mainContext
        let items = getItems(context)
        _ = SharedState
            .createNewItem(
                date: date,
                position: items.count
            )
    }

    @MainActor
    func getItems(_ context: ModelContext) -> [Item] {
        let cal = Calendar.current
        let start = cal.startOfDay(for: SharedState.widgetConductor.date)
        let end = start.advanced(by: 86400)
        let desc = FetchDescriptor<Item>(predicate: #Predicate<Item> { start < $0.timestamp && $0.timestamp < end })
        do {
            return try context.fetch(desc)
        } catch {
            return []
        }
    }
}

struct EditItemIntent: AppIntent {
    static var title: LocalizedStringResource = "Edit Item"
    static let openAppWhenRun: Bool = true

    @Parameter(title: "Item")
    var item: Item

    @MainActor
    func perform() async throws -> some IntentResult {
        withAnimation {
            SharedState.dayDetailsConductor.date = Calendar.current.startOfDay(for: item.timestamp)
            SharedState.dayDetailsConductor.editItem = item
        }
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

        for child in task.children {
            if child.taskData?.completedAt == nil {
                child.taskData?.completedAt = Date()
            } else {
                child.taskData?.completedAt = nil
            }
            context.insert(child)
        }

        context.insert(task)
        try context.save()

        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}
