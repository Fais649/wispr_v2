import AppIntents
import EventKit
import Foundation
import PhotosUI
import SFSymbolsPicker
import SwiftData
import SwiftUI
import UniformTypeIdentifiers
import UserNotifications
import WidgetKit

enum ItemType: String, Identifiable, Codable, CaseIterable {
    var id: ItemType { self }
    case note, task, event, activity, image, log

    var imageName: String {
        switch self {
        case .note:
            "text.word.spacing"
        case .task:
            "checkmark.circle"
        case .event:
            "clock"
        case .activity:
            "timer"
        default:
            "bell.slash"
        }
    }
}

struct ItemRecord: Codable, Transferable {
    var id: UUID
    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .text)
    }
}

extension UTType {
    static let item = UTType(exportedAs: "punk.systems.item")
}

@Model
final class Tag: Identifiable {
    var id: UUID = UUID()
    var name: String
    var colorHex: String
    var symbol: String = "circle.fill"

    init(name: String, color: UIColor, symbol: String = "circle.fill") {
        self.name = name
        colorHex = color.toHex() ?? ""
        self.symbol = symbol
    }

    var color: Color {
        return Color(uiColor: UIColor(hex: colorHex))
    }
}

struct NoteData: Identifiable, Codable, Hashable {
    var id: UUID = .init()
    var text: String
}

struct TaskData: Identifiable, Codable, Equatable, Hashable {
    var id: UUID = .init()
    var completedAt: Date?
    var subtasks: [SubTaskData] = []
}

struct SubTaskData: Identifiable, Codable, Equatable, Hashable {
    var id: UUID = .init()
    var position: Int = 0
    var completedAt: Date?
    var noteData: NoteData = .init(text: "")
}

struct LocationData: Identifiable, Codable {
    var id: UUID = .init()
    var link: String?
}

struct NotificationData: Identifiable, Codable {
    var id: UUID = .init()
    var date: Date
    var offsetBy: TimeInterval
    var text: String
    var linkedItem: UUID?
}

struct EventData: Identifiable, Codable {
    var id: UUID = .init()
    var eventIdentifier: String?
    var startDate: Date
    var endDate: Date
    var notifyAt: Date?
    var calendarIdentifier: String?
}

struct AudioData: Identifiable, Codable {
    var id: UUID = .init()
    var date: Date
    var url: URL
    var transcript: String

    init(_ date: Date = Date(), url: URL? = nil, transcript: String = "") {
        self.date = date
        if let u = url {
            self.url = u
        } else {
            let documentPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let audioFilename = documentPath.appendingPathComponent(UUID().description + ".m4a")
            self.url = audioFilename
        }

        self.transcript = transcript
    }
}

struct ImageData: Identifiable, Codable {
    var id: UUID = .init()
    var date: Date
    var url: URL?

    var image: Image? {
        if let data = data {
            if let image = UIImage(data: data) {
                return Image(uiImage: image)
            }
        }
        return nil
    }

    var data: Data?

    init(_ date: Date = Date(), url: URL? = nil, data: Data? = nil) {
        self.date = date
        if let u = url {
            self.url = u
        } else {
            let documentPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let audioFilename = documentPath.appendingPathComponent(UUID().description + ".m4a")
            self.url = audioFilename
        }

        if let data = data {
            self.data = data
        }
    }
}

struct ItemQuery: EntityQuery {
    func entities(for identifiers: [Item.ID]) async throws -> [Item] {
        var entities: [Item] = []
        let items = await fetchItemsByIds(identifiers)

        for item in items {
            entities.append(item)
        }

        return entities
    }

    @MainActor
    func fetchItemsByIds(_ ids: [UUID]) async -> [Item] {
        let context = SharedState.sharedModelContainer.mainContext
        let desc = FetchDescriptor<Item>(predicate: #Predicate<Item> { ids.contains($0.id) })
        guard let items = try? context.fetch(desc) else {
            return []
        }

        return items
    }

    @MainActor
    func fetchItemById(_ id: UUID) async -> Item? {
        let context = SharedState.sharedModelContainer.mainContext
        let desc = FetchDescriptor<Item>(predicate: #Predicate<Item> { id == $0.id })
        guard let item = try? context.fetch(desc).first else {
            return nil
        }

        return item
    }
}

@Model
final class Item: Codable, Transferable, AppEntity {
    @Attribute(.unique) var id: UUID

    @Relationship(deleteRule: .noAction) var tags: [Tag] = []

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: LocalizedStringResource(stringLiteral: noteData.text))
    }

    var queryIntentParameter: IntentParameter<Item> {
        IntentParameter<Item>(query: Item.defaultQuery)
    }

    var defaultIntentParameter: IntentParameter<Item> {
        let i = IntentParameter<Item>(title: "Item", default: self)
        i.wrappedValue = self
        return i
    }

    func meshPoints(x: Double) -> [SIMD2<Float>] {
        let two: [SIMD2<Float>] = [
            [Float(x), 0], [1, 1],
        ]

        let four: [SIMD2<Float>] = [
            [0, 0], [0, 1],
            [Float(x), 0], [1, 1],
        ]

        let six: [SIMD2<Float>] = [
            [0, 0], [0, 0.5], [0, 1],
            [1, 0], [1, Float(x)], [1, 1],
        ]

        switch tags.count {
        case ...2:
            return two
        case 2 ... 4:
            return four
        case 6...:
            return six
        default:
            return six
        }
    }

    @ViewBuilder
    var colorMesh: some View {
        let colors = tags.map { tag in
            tag.color
        }
        TimelineView(.animation) { timeline in
            let x = (sin(timeline.date.timeIntervalSince1970) + 1) / 2

            // MeshGradient(width: 2, height: 2, points: self.meshPoints(x: x), colors: colors)
            MeshGradient(width: 3, height: 2, points: [
                [0, 0], [Float(x), 0], [1, 0],
                [0, 1], [0.5, 1], [1, 1],
            ], colors: colors)
                .blur(radius: 15 * (1 - x) + 10)
        }
    }

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Item"
    static var defaultQuery = ItemQuery()

    var parent: Item?
    @Relationship(deleteRule: .cascade, inverse: \Item.parent) var children: [Item] = []
    var position: Int
    var timestamp: Date
    var archived: Bool = false

    var noteData: NoteData = NoteData(text: "")
    var taskData: TaskData?
    var eventData: EventData?

    @Attribute(.externalStorage)
    var imageData: ImageData?
    var audioData: AudioData?
    var notificationData: NotificationData?

    var canSave: Bool {
        return hasNote
    }

    var hasNote: Bool {
        !noteData.text.isEmpty
    }

    var isTask: Bool {
        taskData != nil
    }

    var isEvent: Bool {
        eventData != nil
    }

    var hasTags: Bool {
        !tags.isEmpty
    }

    var hasImage: Bool {
        imageData != nil
    }

    var hasAudio: Bool {
        audioData?.url != nil
    }

    var record: ItemRecord {
        ItemRecord(id: id)
    }

    @ViewBuilder
    func imageView(image: Image? = nil) -> some View {
        if let image = image {
            image.resizable().scaledToFit()
                .aspectRatio(CGSize(width: 4, height: 3), contentMode: .fill)
                .overlay {
                    LinearGradient(gradient: Gradient(colors: [.clear, .black]), startPoint: .top, endPoint: .bottom)
                }
                .clipShape(RoundedRectangle(cornerRadius: 10))
        } else if let image = loadImage() {
            image.resizable().scaledToFit()
                .aspectRatio(CGSize(width: 4, height: 3), contentMode: .fill)
                .overlay {
                    LinearGradient(gradient: Gradient(colors: [.clear, .black]), startPoint: .top, endPoint: .bottom)
                }
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }

    func loadImage() -> Image? {
        if let data = imageData?.data {
            if let image = UIImage(data: data) {
                return Image(uiImage: image)
            }
        }
        return nil
    }

    func deleteEKEvent(from calendarService: CalendarService) {
        if let id = eventData?.eventIdentifier {
            calendarService.deleteEKEvent(id)
            eventData = nil
        }
    }

    init(
        id: UUID = UUID(),
        position: Int = 0,
        timestamp: Date = .init(),
        tags: [Tag] = [],
        noteData: NoteData = .init(text: ""),
        taskData: TaskData? = nil,
        eventData: EventData? = nil,
        imageData: ImageData? = nil,
        audioData: AudioData? = nil
    ) {
        self.id = id
        self.timestamp = timestamp

        self.position = position
        self.tags = tags
        self.noteData = noteData
        self.taskData = taskData
        self.eventData = eventData
        self.imageData = imageData
        self.audioData = audioData
    }

    enum CodingKeys: String, CodingKey {
        case id
        case position
        case timestamp
    }

    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .item)
        ProxyRepresentation(exporting: \.noteData.text)
    }

    required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(UUID.self, forKey: .id)
        position = try values.decode(Int.self, forKey: .position)
        timestamp = try values.decode(Date.self, forKey: .timestamp)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(position, forKey: .position)
        try container.encode(timestamp, forKey: .timestamp)
    }
}

struct ItemForm: View {
    @Environment(DayDetailsConductor.self) private var conductor: DayDetailsConductor
    @Environment(\.modelContext) private var modelContext: ModelContext
    @Environment(CalendarService.self) private var calendarService: CalendarService

    let item: Item?
    @Binding var showItemForm: Bool
    @Binding var timestamp: Date
    @State var position: Int

    @State var assignedTags: [Tag] = []
    @State var noteData: NoteData = .init(text: "")
    @State var taskData: TaskData? = nil
    @State var subtasks: [SubTaskData] = []
    @State var eventData: EventData? = nil
    @State var imageData: ImageData? = nil
    @State var audioData: AudioData? = nil

    @Query var tags: [Tag]

    @State var showTag: Bool = false
    @State var tagSearchTerm: String = ""
    @State private var image: Image?

    var tagSearchResults: [Tag] {
        if tagSearchTerm.isEmpty {
            return tags.filter { !assignedTags.contains($0) }
        } else {
            return tags.filter { $0.name.contains(tagSearchTerm) && !assignedTags.contains($0) }
        }
    }

    @FocusState var noteFocus: Bool
    @FocusState var tagSearchFocus: Bool

    @State var expand: Bool = true
    var hasSubTasks: Bool {
        if let task = taskData { return task.subtasks.isNotEmpty } else { return false }
    }

    @ViewBuilder
    var imageView: some View {
        if let image = image {
            image.resizable().scaledToFit()
                .aspectRatio(CGSize(width: 4, height: 3), contentMode: .fill)
                .overlay {
                    LinearGradient(gradient: Gradient(colors: [.clear, .black]), startPoint: .top, endPoint: .bottom)
                }
                .overlay(alignment: .topTrailing) {
                    Button(action: deleteImage) {
                        Image(systemName: "xmark")
                    }.padding()
                }
        }
    }

    @ViewBuilder
    var subtaskView: some View {
        DisclosureGroup(isExpanded: $expand) {
            HStack {
                RoundedRectangle(cornerRadius: 2).fill(Color.gray).frame(width: 1)
                    .padding(.horizontal, 8)
                VStack {
                    if taskData != nil {
                        ForEach(self.subtasks.sorted(by: { first, second in first.position < second.position }).indices, id: \.self) { subtask in
                            SubTaskDataRow(taskData: $taskData, subtasks: $subtasks, subtask: $subtasks[subtask])
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
        } label: {
            labelView
        }.tint(.white)
    }

    @ViewBuilder
    var labelView: some View {
        VStack {
            HStack {
                if audioData == nil {
                    AudioDataButton(audioData: $audioData, timestamp: $timestamp)
                } else {
                    AudioRecordingView(audioData: $audioData)
                        .foregroundStyle(.white)
                        .background(.black)
                }

                TaskDataRow(taskData: $taskData)
                NoteDataRow(noteData: $noteData, taskData: $taskData, subtasks: $subtasks)
                    .focused($noteFocus)

                Button(action: { withAnimation { submitItem() }}) {
                    Image(systemName: "paperplane.circle.fill")
                        .rotationEffect(.degrees(-45))
                        .font(.system(size: 20))
                }.disabled(noteData.text.isEmpty)
                    .animation(.smooth, value: noteData.text.isNotEmpty)
            }.background {
                imageView
            }
            TagDataRow(availableTags: tags, assignedTags: $assignedTags)
        }
    }

    var body: some View {
        @Bindable var conductor = conductor
        VStack {
            if hasSubTasks {
                subtaskView
            } else {
                labelView
            }
        }
        .listRowBackground(Color.clear)
        .onAppear {
            if let item {
                position = item.position
                timestamp = item.timestamp
                assignedTags = item.tags
                noteData = item.noteData
                taskData = item.taskData
                if let subtasks = item.taskData?.subtasks {
                    self.subtasks = subtasks
                }
                eventData = item.eventData
                imageData = item.imageData
                audioData = item.audioData
            }
            if eventData != nil {
                calendarService.requestAccessToCalendar()
            }
            noteFocus = true
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                HStack {
                    ImageDataButton(imageData: $imageData)
                    TaskDataButton(taskData: $taskData, noteData: $noteData)
                    EventDataButton(eventData: $eventData, timestamp: $timestamp)

                    if eventData != nil {
                        EventDataRow(eventData: $eventData)
                    }
                }.toolbarBackground(.black, for: .bottomBar)
                    .font(.custom("GohuFont11NFM", size: 12))
            }
        }
        .tint(.white)
    }

    fileprivate func submitItem() {
        let item = self.item ?? Item()
        item.position = position
        item.timestamp = timestamp
        item.tags = assignedTags
        item.noteData = noteData

        if var taskData {
            taskData.subtasks.removeAll(where: { $0.noteData.text.isEmpty })
            taskData.subtasks = subtasks
            self.taskData = taskData
        }
        item.taskData = taskData

        item.eventData = eventData
        if let eventData {
            let eventHandler = EventHandler(item, eventData)
            let e = eventHandler.processEventData()
            item.eventData = e
        }

        item.imageData = imageData
        item.audioData = audioData

        if self.item == nil {
            modelContext.insert(item)
        }

        try? modelContext.save()

        withAnimation {
            noteFocus = false
            showItemForm = false
        }
    }

    fileprivate func deleteImage() {
        withAnimation {
            imageData = nil
        }
    }

    private func cancelEdit() {
        noteFocus = false
        conductor.rollback(context: modelContext)
    }
}

struct NoteDataRow: View {
    @Environment(\.modelContext) private var modelContext: ModelContext
    @Environment(DayDetailsConductor.self) private var conductor: DayDetailsConductor
    @Environment(
        CalendarService.self
    ) private var calendarService: CalendarService

    @Binding var noteData: NoteData
    @Binding var taskData: TaskData?
    @Binding var subtasks: [SubTaskData]
    @FocusState var focus: Bool

    var formatter: RelativeDateTimeFormatter {
        let formatter = RelativeDateTimeFormatter()
        return formatter
    }

    func format(_ date: Date, _: Date) -> String {
        return formatter.localizedString(for: date, relativeTo: .now)
    }

    var body: some View {
        TextField("...", text: $noteData.text, axis: .vertical)
            .onSubmit {
                if taskData == nil { return }
                // if !focus || taskData == nil { return }
                withAnimation {
                    let newSubtask = SubTaskData(position: subtasks.count, noteData: NoteData(text: ""))
                    subtasks.append(newSubtask)
                }
            }
            .lineLimit(20)
            .onAppear { focus = noteData.text.isEmpty }
            .focused($focus)
            .multilineTextAlignment(.leading)
    }
}

struct TaskDataRow: View {
    @Environment(\.modelContext) private var modelContext: ModelContext
    @Binding var taskData: TaskData?

    var body: some View {
        if var taskData {
            Button {
                withAnimation {
                    if taskData.completedAt == nil {
                        taskData.completedAt = Date()
                    } else {
                        taskData.completedAt = nil
                    }

                    self.taskData = taskData
                    WidgetCenter.shared.reloadAllTimelines()
                }
            } label: {
                Image(systemName: taskData.completedAt == nil ? "square" : "square.fill")
            }
        }
    }
}

struct SubTaskDataRow: View {
    @Environment(\.modelContext) private var modelContext: ModelContext
    @Binding var taskData: TaskData?
    @Binding var subtasks: [SubTaskData]
    @Binding var subtask: SubTaskData
    @FocusState var focused: Bool

    var body: some View {
        HStack {
            Button {
                withAnimation {
                    if subtask.completedAt == nil {
                        subtask.completedAt = Date()
                    } else {
                        subtask.completedAt = nil
                    }
                }
                WidgetCenter.shared.reloadAllTimelines()
            } label: {
                Image(systemName: subtask.completedAt == nil ? "square" : "square.fill")
            }
            TextField("", text: $subtask.noteData.text)
                .focused($focused)
            Spacer()
        }.ignoresSafeArea()
            .onChange(of: taskData?.completedAt) {
                if let taskData {
                    subtask.completedAt = taskData.completedAt
                }
            }.onSubmit {
                let newSubtask = SubTaskData(position: subtasks.count)
                subtasks.append(newSubtask)
            }
            .onAppear {
                focused = subtask.noteData.text.isEmpty
            }
    }
}

struct ItemList: View {
    @Environment(\.modelContext) private var modelContext: ModelContext
    @Environment(DayDetailsConductor.self) private var conductor: DayDetailsConductor
    @Environment(
        CalendarService.self
    ) private var calendarService: CalendarService

    var items: [Item]

    var start: Date {
        Calendar.current.startOfDay(for: conductor.date)
    }

    var end: Date {
        start.advanced(by: 86400)
    }

    @State var listId: UUID = .init()
    @State var focusedItem: Item?
    @State var flashError: Bool = false
    @State var movedItem: Item?
    @State var movedToItem: Item?

    var body: some View {
        ZStack {
            list
            if flashError {
                errorFlash
            }
        }
    }

    @ViewBuilder
    var list: some View {
        VStack {
            List {
                ForEach(items, id: \.self) { item in
                    ItemListRow(item: item)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .onChange(of: item.eventData?.startDate) {
                            dynamicallyReorderList(item: item)
                        }
                        .onAppear {
                            if !item.hasNote && conductor.editItem == nil {
                                SharedState.deleteItem(item)
                            }
                        }
                }
                .onMove(perform: handleMove)
            }.id(listId)
                .opacity(flashError ? 0.1 : 1)
                .listRowSpacing(4)
        }.padding(0).safeAreaPadding(0)
    }

    @ViewBuilder
    var errorFlash: some View {
        VStack {
            Image(systemName: "xmark")
                .font(.system(size: 128))
            Text("Can't change event order!")
        }
        .frame(alignment: .center)
    }

    fileprivate func triggerFlashError() {
        withAnimation {
            flashError = true
            listId = UUID()
        }
        DispatchQueue.main
            .asyncAfter(deadline: .now() + 2) {
                withAnimation {
                    flashError = false
                }
            }
    }

    func handleMove(_ indexSet: IndexSet, _ newIndex: Int) {
        for index in indexSet {
            let count = items.count
            let movedItem = items[index]
            self.movedItem = movedItem

            if let movedEventData = movedItem.eventData {
                for i in 0 ..< newIndex {
                    let item = items[i]
                    if let itemEventData = item.eventData {
                        if movedEventData.startDate < itemEventData.startDate {
                            triggerFlashError()
                            return
                        }
                    }
                }

                for i in newIndex ..< count {
                    let item = items[i]
                    if let itemEventData = item.eventData {
                        if movedEventData.startDate > itemEventData.startDate {
                            triggerFlashError()
                            return
                        }
                    }
                }
            }
        }

        var itms = items
        itms.move(fromOffsets: indexSet, toOffset: newIndex)

        for (index, item) in itms.enumerated() {
            item.position = index
        }

        try! modelContext.save()
    }

    func dynamicallyReorderList(item: Item) {
        guard let itemEventData = item.eventData else {
            return
        }

        let oldIndex = items.firstIndex(of: item)!
        if let newIndex = items.firstIndex(where: {
            if let eventData = $0.eventData {
                return $0.id != item.id && $0.eventData != nil && eventData.startDate > itemEventData.startDate
            } else {
                return false
            }
        }) {
            var itms = items
            itms.move(fromOffsets: [oldIndex], toOffset: newIndex)
            for (index, itm) in itms.enumerated() {
                itm.position = index
            }
        } else {
            item.position = items.count
        }
    }
}

struct ItemListRow: View {
    @Environment(DayDetailsConductor.self) private var conductor: DayDetailsConductor
    @Environment(\.modelContext) private var modelContext: ModelContext
    @Environment(CalendarService.self) private var calendarService: CalendarService

    var item: Item
    init(item: Item) {
        self.item = item
        let item = item
        taskData = item.taskData
        subtasks = item.taskData?.subtasks ?? []
        noteData = item.noteData
        eventData = item.eventData
        imageData = item.imageData
        audioData = item.audioData
        assignedTags = item.tags
    }

    var assignedTags: [Tag] = []
    var noteData: NoteData = .init(text: "")
    var taskData: TaskData? = nil
    var subtasks: [SubTaskData] = []
    var eventData: EventData? = nil
    var imageData: ImageData? = nil
    var audioData: AudioData? = nil

    @Query var tags: [Tag]

    @State var showTag: Bool = false
    @State var tagSearchTerm: String = ""
    @State private var image: Image?
    @Namespace var namespace

    var tagSearchResults: [Tag] {
        if tagSearchTerm.isEmpty {
            return tags.filter { !assignedTags.contains($0) }
        } else {
            return tags.filter { $0.name.contains(tagSearchTerm) && !assignedTags.contains($0) }
        }
    }

    @FocusState var noteFocus: Bool
    @FocusState var childFocus: Bool
    @FocusState var tagSearchFocus: Bool

    @State var expand: Bool = true
    var hasSubTasks: Bool {
        if let task = taskData { return task.subtasks.isNotEmpty } else { return false }
    }

    var body: some View {
        if hasSubTasks {
            subtaskView
        } else {
            labelView
        }
    }

    @ViewBuilder
    var subtaskView: some View {
        DisclosureGroup(isExpanded: $expand) {
            ForEach(
                subtasks.sorted(by: { first, second in first.position < second.position }).indices,
                id: \.self
            ) { index in
                SubTaskDataListRow(
                    item: item,
                    subtask: subtasks[index]
                ).scrollTargetLayout()
                    .listRowSpacing(0)
                    .fixedSize(horizontal: false, vertical: true)
                    .environment(\.defaultMinListRowHeight, 15)
            }
        } label: {
            labelView
        }
    }

    @ViewBuilder
    var labelView: some View {
        TimelineView(.periodic(from: .now, by: 1)) { time in
            HStack {
                TaskDataListRow(item: item, taskData: taskData)
                    .fixedSize(horizontal: false, vertical: true)

                Button(action: { conductor.editItem = item }) {
                    Text(noteData.text)
                        .fixedSize(horizontal: false, vertical: true)
                }.buttonStyle(.plain)
                Spacer()
                // AudioRecordingView(audioData: $audioData)

                if eventData != nil {
                    VStack {
                        relateiveStartString(time.date)
                        HStack {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(isActiveItem(item, time.date) && item.imageData == nil ? .black : .white)
                                .frame(width: 1, height: 20)
                                .padding(.horizontal, 8)
                            Spacer()
                            VStack {
                                Text(startString)
                                Text(endString)
                            }
                        }
                    }
                    .font(.custom("GohuFont11NFM", size: 12))
                    .frame(width: 58)
                }
            }.background {
                if let imageData = item.imageData {
                    ImageDataListRow(imageData: imageData, namespace: namespace)
                }
            }
            .padding()
            .background {
                if isActiveItem(item, time.date) {
                    RoundedRectangle(cornerRadius: 20).fill(.white)
                }

                if assignedTags.isNotEmpty {
                    item.colorMesh.clipShape(RoundedRectangle(cornerRadius: 20))
                }
            }
            .foregroundStyle(isActiveItem(item, time.date) ? .black : .white)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .listRowBackground(Color.clear)
            .onAppear {
                if eventData != nil {
                    calendarService.requestAccessToCalendar()
                }
            }
            .tint(.white)
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                SharedState.deleteItem(item)
            } label: {
                Image(systemName: "trash")
            }
            .tint(.black)
        }
    }

    @ViewBuilder
    func relateiveStartString(_ time: Date) -> some View {
        if let event = eventData, Calendar.current.isDateInToday(event.startDate) {
            if time < event.startDate {
                HStack {
                    Image(systemName: "clock")
                    Text(formatter.localizedString(for: event.startDate, relativeTo: time))
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                }
            } else if time < event.endDate {
                HStack {
                    Image(systemName: "timer")
                    Text(time, format: .timer(countingDownIn: event.startDate ..< event.endDate))
                }
            }
        }
    }

    var formatter: RelativeDateTimeFormatter {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter
    }

    var startString: String {
        if let event = eventData {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            return formatter.string(from: event.startDate)
        }
        return ""
    }

    var endString: String {
        if let event = eventData {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            return formatter.string(from: event.endDate)
        }
        return ""
    }

    func isActiveItem(_ item: Item, _ date: Date) -> Bool {
        if let eventData = item.eventData {
            return eventData.startDate <= date && date < eventData.endDate && item.taskData?.completedAt == nil
        } else {
            return false
        }
    }

    @ViewBuilder
    var rowBackgroundView: some View {
        if let imageData = item.imageData {
            ImageDataListRow(imageData: imageData, namespace: namespace)
        } else {
            TimelineView(.periodic(from: .now, by: 1)) { time in
                RoundedRectangle(cornerRadius: 20).fill(isActiveItem(item, time.date) ? .white : .clear)
            }
        }
    }
}

struct TaskDataListRow: View {
    @Environment(\.modelContext) private var modelContext: ModelContext
    let item: Item
    var taskData: TaskData?

    var body: some View {
        if var taskData {
            Button {
                withAnimation {
                    if taskData.completedAt == nil {
                        taskData.completedAt = Date()
                    } else {
                        taskData.completedAt = nil
                    }

                    for (index, _) in taskData.subtasks.enumerated() {
                        taskData.subtasks[index].completedAt = taskData.completedAt
                    }

                    item.taskData = taskData
                    try? modelContext.save()
                    WidgetCenter.shared.reloadAllTimelines()
                }
            } label: {
                Image(systemName: taskData.completedAt == nil ? "square" : "square.fill")
            }
        }
    }
}

struct SubTaskDataListRow: View {
    @Environment(\.modelContext) private var modelContext: ModelContext
    let item: Item?
    var subtask: SubTaskData

    var body: some View {
        Button {
            if subtask.completedAt == nil {
                withAnimation {
                    if let item, var taskData = item.taskData, var s = taskData.subtasks.first(where: { $0.id
                            == subtask.id
                    }), let i = taskData.subtasks.firstIndex(of: s) {
                        s.completedAt = Date()
                        taskData.subtasks[i] = s
                        item.taskData = taskData
                    }
                    WidgetCenter.shared.reloadAllTimelines()
                }
            } else {
                withAnimation {
                    if let item, var taskData = item.taskData, var s = taskData.subtasks.first(where: { $0.id
                            == subtask.id
                    }), let i = taskData.subtasks.firstIndex(of: s) {
                        s.completedAt = nil
                        taskData.subtasks[i] = s
                        item.taskData = taskData
                    }
                    WidgetCenter.shared.reloadAllTimelines()
                }
            }
        } label: {
            HStack {
                Spacer().frame(width: 20)
                Image(systemName: subtask.completedAt == nil ? "square" : "square.fill")
                Text(subtask.noteData.text)
                Spacer()
            }
        }.buttonStyle(.plain)
            .environment(\.defaultMinListRowHeight, 15)
    }
}

struct TaskDataButton: View {
    @Environment(\.modelContext) private var modelContext: ModelContext
    @Binding var taskData: TaskData?
    @Binding var noteData: NoteData

    var isTask: Bool {
        return taskData != nil
    }

    var body: some View {
        Button {
            toggleTaskData()
        } label: {
            Image(systemName: isTask ? "square.fill" : "square")
        }
    }

    fileprivate func toggleTaskData() {
        if let task = taskData {
            var string = noteData.text
            for subtask in task.subtasks {
                string += "\n" + subtask.noteData.text
            }

            withAnimation {
                taskData = nil
                noteData.text = string
                WidgetCenter.shared.reloadAllTimelines()
            }
        } else {
            withAnimation {
                var task = TaskData()
                let strings = noteData.text.components(separatedBy: "\n")
                for (index, str) in strings.enumerated() {
                    if index == 0 {
                        noteData.text = str
                    } else {
                        let noteData = NoteData(text: str)
                        let subtaskData = SubTaskData(noteData: noteData)
                        task.subtasks.append(subtaskData)
                    }
                }
                self.taskData = task
                WidgetCenter.shared.reloadAllTimelines()
            }
        }
    }
}

struct EventDataButton: View {
    @Environment(\.modelContext) private var modelContext: ModelContext
    @Environment(CalendarService.self) private var calendarService: CalendarService
    @Binding var eventData: EventData?
    @Binding var timestamp: Date

    var body: some View {
        TimelineView(.everyMinute) { time in
            Button {
                toggleEventData(time: time.date)
            } label: { Image(systemName: eventData != nil ? "clock.fill" : "clock") }
        }
    }

    fileprivate func toggleEventData(time: Date) {
        withAnimation {
            if let event = eventData {
                if let id = event.eventIdentifier, let ekEvent =
                    calendarService.eventStore.event(withIdentifier: id)
                {
                    calendarService.deleteEventInCalendar(event: ekEvent)
                }
                eventData = nil
            } else {
                eventData = .init(
                    startDate: Calendar.current.combineDateAndTime(date: timestamp, time: time),
                    endDate: Calendar.current.combineDateAndTime(date: timestamp, time: time.advanced(by: 3600))
                )
            }
        }
    }
}

struct EventDataRow: View {
    @Environment(\.modelContext) private var modelContext: ModelContext
    @Environment(CalendarService.self) private var calendarService: CalendarService
    @Binding var eventData: EventData?
    @State var deleteEvent: Bool = false
    @State var notify: Bool = false

    @State var startDate: Date = .init()
    @State var interval: TimeInterval = 3600
    @State var endDate: Date = Date().advanced(by: 3600)

    var startString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: startDate)
    }

    var endString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: endDate)
    }

    var body: some View {
        Text(startString)
            .frame(width: 50)
            .overlay {
                DatePicker("start:", selection: $startDate, displayedComponents: [.hourAndMinute])
                    .datePickerStyle(.compact)
                    .colorMultiply(.clear)
                    .labelsHidden()
                    .onChange(of: startDate) {
                        updateEndDate()
                    }
            }

        RoundedRectangle(cornerRadius: 2).background(.white).frame(width: 2, height: 15)

        Text(endString)
            .frame(width: 50)
            .overlay {
                DatePicker("end:", selection: $endDate, displayedComponents: [.hourAndMinute])
                    .datePickerStyle(.compact)
                    .colorMultiply(.clear)
                    .labelsHidden()
                    .onChange(of: endDate) {
                        updateStartDate()
                    }
            }
            .onAppear {
                if !calendarService.accessToCalendar {
                    calendarService.requestAccessToCalendar()
                }
                if let eventData {
                    notify = eventData.notifyAt != nil
                    startDate = eventData.startDate
                    interval = eventData.endDate.timeIntervalSince(startDate)
                    endDate = eventData.endDate
                }
            }.onChange(of: [startDate, endDate]) {
                if var eventData {
                    eventData.startDate = startDate
                    eventData.endDate = endDate
                    self.eventData = eventData
                }
            }

        Button {
            Task {
                await toggleNotification()
            }
        } label: {
            Image(systemName: notify ? "bell.and.waves.left.and.right.fill" : "bell")
        }
    }

    fileprivate func updateEndDate() {
        endDate = startDate.advanced(by: interval)
    }

    fileprivate func updateStartDate() {
        if endDate < startDate {
            startDate = endDate.advanced(by: -interval)
        } else {
            interval = endDate.timeIntervalSince(startDate)
        }
    }

    fileprivate func toggleNotification() async {
        guard let hasAuth = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) else {
            notify = false
            return
        }

        if hasAuth {
            notify.toggle()
        }
    }
}

struct TagDataButton: View {
    @Binding var show: Bool

    var body: some View {
        Button { withAnimation { show.toggle() } } label: {
            Image(systemName: show ?
                "tag.fill" : "tag")
        }
    }
}

struct TagDataRow: View {
    @Environment(\.modelContext) private var modelContext: ModelContext
    @State var showTagSheet: Bool = false
    @State var newTag: Tag = .init(name: "", color: UIColor.red)
    @State private var color = Color(.sRGB, red: 1, green: 0, blue: 0)
    var availableTags: [Tag]
    @Binding var assignedTags: [Tag]

    var body: some View {
        HStack {
            if availableTags.isNotEmpty {
                ScrollView(.horizontal) {
                    HStack {
                        if assignedTags.isNotEmpty {
                            ForEach(assignedTags) { tag in
                                Button {
                                    unassignTag(tag)
                                } label: {
                                    Text(tag.name)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 6)
                                        .font(.custom("GohuFont11NFM", size: 14))
                                }
                                .background {
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(tag.color)
                                        .stroke(.white)
                                }
                                .foregroundStyle(.white)
                                .padding(.vertical, 4)
                                .padding(.horizontal, 2)
                            }
                        }

                        ForEach(availableTags.filter { !assignedTags.contains($0) }) { tag in
                            Button {
                                assignTag(tag)
                            } label: {
                                Text(tag.name)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 6)
                                    .font(.custom("GohuFont11NFM", size: 14))
                            }
                            .background {
                                RoundedRectangle(cornerRadius:
                                    20).fill(tag.color).opacity(0.75)
                            }
                            .foregroundStyle(.white)
                            .padding(.vertical, 4)
                            .padding(.horizontal, 2)
                        }
                    }
                }
            } else {
                Text("No tags created...")
                Spacer()
            }

            Button {
                showTagSheet = true
            } label: {
                Image(systemName: "plus")
            }.sheet(isPresented: $showTagSheet) {
                GeometryReader { geo in
                    Form {
                        HStack {
                            Button {
                                showTagSheet = false
                            } label: {
                                Image(systemName: "xmark")
                            }.buttonStyle(.plain)

                            Spacer()

                            Button {
                                modelContext.insert(newTag)
                                showTagSheet = false
                            } label: {
                                Image(systemName: "plus")
                            }.buttonStyle(.plain)
                        }
                        TextField("#...", text: $newTag.name)
                        ColorPicker("Color", selection: $color)
                            .onChange(of: color) {
                                newTag.colorHex = UIColor(color).toHex() ?? newTag.colorHex
                            }

                    }.presentationDetents([.height(geo.size.height)])
                        .tint(color)
                }
            }
        }
        .padding(10)
    }

    fileprivate func unassignTag(_ tag: Tag) {
        withAnimation {
            if assignedTags.contains(tag) {
                assignedTags.removeAll(where: { $0.id == tag.id })
            }
        }
    }

    fileprivate func assignTag(_ tag: Tag) {
        withAnimation {
            if !assignedTags.contains(tag) {
                assignedTags.append(tag)
            }
        }
    }

    // fileprivate func deleteTag(_ tag: Tag) {
    //     withAnimation {
    //         tags.removeAll(where: { $0.id == tag.id })
    //     }
    // }
}

struct ImageDataButton: View {
    @State private var imageItem: PhotosPickerItem?
    @Binding var imageData: ImageData?

    var body: some View {
        PhotosPicker(selection: $imageItem, matching: .images) {
            Image(systemName: imageData?.data == nil ? "photo" : "photo.fill")
        }.onChange(of: imageItem) {
            saveImage()
        }
    }

    fileprivate func saveImage() {
        Task {
            if let image = try await imageItem?.loadTransferable(type: Data.self) {
                withAnimation {
                    if var i = imageData {
                        i.data = image
                        self.imageData = i
                    } else {
                        imageData = ImageData(data: image)
                    }
                }
            }
        }
    }
}

struct ImageDataListRow: View {
    var imageData: ImageData
    var namespace: Namespace.ID

    @ViewBuilder
    var imageView: some View {
        if let image = imageData.image {
            image.resizable().scaledToFill()
                .aspectRatio(CGSize(width: 4, height: 3), contentMode: .fill)
                .overlay {
                    LinearGradient(gradient: Gradient(colors: [.clear, .black]), startPoint: .top, endPoint: .bottom)
                }
        }
    }

    var body: some View {
        NavigationLink {
            VStack {
                imageView
            }.padding()
                .navigationBarBackButtonHidden()
                .navigationTransition(.zoom(sourceID: imageData.id, in: namespace))
        } label: {
            imageView
                .matchedTransitionSource(id: imageData.id, in: namespace)
        }
    }
}

struct ImageDataRowLabel: View {
    var imageData: ImageData
    var namespace: Namespace.ID
    var disabled: Bool = false
    @State var showImage: Bool = false

    @ViewBuilder
    var imageView: some View {
        if let image = imageData.image {
            image.resizable().scaledToFill()
                .aspectRatio(CGSize(width: 4, height: 3), contentMode: .fill)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay {
                    LinearGradient(gradient: Gradient(colors: [.clear, .black]), startPoint: .top, endPoint: .bottom)
                }
        }
    }

    var body: some View {
        Button {
            showImage = true
        } label: {
            imageView
                .padding(2)
                .padding(.horizontal, 12)
                .matchedTransitionSource(id: imageData.id, in: namespace)
        }
        .disabled(disabled)
        .sheet(isPresented: $showImage) {
            VStack {
                imageView
            }.padding()
                .presentationBackground(.black)
                .navigationTransition(.zoom(sourceID: imageData.id, in: namespace))
        }.buttonStyle(.plain)
    }
}

struct AudioDataButton: View {
    @Binding var audioData: AudioData?
    @Binding var timestamp: Date

    var hasAudio: Bool {
        return audioData != nil
    }

    var body: some View {
        Button {
            toggleAudioData()
        } label: {
            Image(systemName: hasAudio ? "microphone.fill" : "microphone")
        }
    }

    fileprivate func toggleAudioData() {
        if let audioData = audioData {
            try? FileManager.default.removeItem(at: audioData.url)
            self.audioData = nil
        } else {
            withAnimation {
                audioData = AudioData(timestamp)
            }
        }
    }
}

struct AudioPlayerView: View {
    @Binding var audioData: AudioData?
    @State private var player: AVPlayer?
    @State private var isPlaying = false
    @State private var audioSession: AVAudioSession?
    @State private var transcript: String = ""

    var body: some View {
        if let data = audioData {
            HStack {
                Button(action: togglePlayback) {
                    Image(systemName: isPlaying ? "stop.circle.fill" : "play.circle.fill")
                        .resizable()
                        .frame(width: 30, height: 30)
                }

                if !data.transcript.isEmpty {
                    HStack {
                        TextField("[transcript]", text: $transcript, axis: .vertical)
                            .padding()
                            .fixedSize(horizontal: false, vertical: true)
                            .onChange(of: audioData?.transcript) {
                                guard let d = audioData else { return }
                                if d.transcript.isNotEmpty &&
                                    d.transcript != transcript
                                {
                                    transcript = d.transcript
                                }
                            }

                        if transcript != data.transcript {
                            Button {
                                transcript = data.transcript
                            } label: {
                                Image(systemName: "xmark")
                            }.padding().buttonStyle(.plain)

                            Button {
                                var d = data
                                d.transcript = transcript
                                audioData = d
                            } label: {
                                Image(systemName: "checkmark")
                            }.padding().buttonStyle(.plain)
                        }
                    }.onAppear {
                        transcript = data.transcript
                    }
                } else {
                    Spacer()
                }
            }.padding()
                .onAppear(perform: setupAudioPlayer)
        }
    }

    private func setupAudioPlayer() {
        guard let data = audioData else {
            return
        }

        if !FileManager.default.fileExists(atPath: data.url.path()) {
            withAnimation {
                audioData = nil
            }
        }

        let audioSession = AVAudioSession.sharedInstance()
        try? audioSession.setCategory(.playback, mode: .spokenAudio)
        try? audioSession.overrideOutputAudioPort(AVAudioSession.PortOverride.speaker)
        try? audioSession.setActive(true)
        self.audioSession = audioSession

        player = AVPlayer(url: data.url)

        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime,
                                               object: player?.currentItem,
                                               queue: .main)
        { _ in
            isPlaying = false
            player?.seek(to: .zero)
        }
    }

    private func togglePlayback() {
        if let audioData, !FileManager.default.fileExists(atPath: audioData.url.path()) {
            withAnimation {
                self.audioData = nil
            }
        }
        guard let player = player else { return }
        if isPlaying {
            player.seek(to: .zero)
            player.pause()
        } else {
            print("play")
            player.play()
        }
        isPlaying.toggle()
    }
}

struct AudioRecordingView: View {
    @Environment(AudioService.self) private var audioService: AudioService
    @Environment(\.modelContext) private var modelContext: ModelContext
    @Binding var audioData: AudioData?

    @State private var currentTime: TimeInterval = 0
    @State private var transcript: String = ""
    @State private var hasPermission: Bool = false
    @State private var doneLoading: Bool = false

    @State var count: Int = 0

    @State var startDate: Date?

    var showPlay: Bool {
        if let url = audioData?.url {
            return FileManager.default.fileExists(atPath: url.path()) && !audioService.isRecording
        }
        return false
    }

    var body: some View {
        HStack {
            if audioData != nil {
                if showPlay {
                    AudioPlayerView(audioData: $audioData)
                        .opacity(!doneLoading ? 0.5 : 1)
                        .onAppear {
                            if let url = audioData?.url {
                                doneLoading = FileManager.default.fileExists(atPath: url.path()) && !audioService.isRecording
                            }
                        }
                        .disabled(!doneLoading)
                } else {
                    Button(action: toggleRecording) {
                        Image(systemName: audioService.isRecording ?
                            "circle.fill" : "microphone.circle.fill")
                            .resizable()
                            .foregroundColor(audioService.isRecording ? .red : .white)
                    }.disabled(!audioService.hasPermission)
                        .frame(width: 30, height: 30)
                    Spacer()
                        .onAppear {
                            setupAudioRecorder()
                        }
                }
            }
        }.padding()
    }

    private func setupAudioRecorder() {
        if !audioService.hasPermission {
            Task {
                await audioService.requestRecordPermission()
            }
        }
    }

    func toggleRecording() {
        if audioService.isRecording {
            audioService.stopRecording()
            if let url = audioService.recordedURL {
                Task {
                    audioService.extractTextFromAudio(url) { result in
                        switch result {
                        case let .success(string):
                            if var audio = audioData {
                                audio.transcript = string
                                audioData = audio
                            } else {
                                transcript = string
                                let newAudio = AudioData(url: url, transcript: transcript)
                                audioData = newAudio
                            }
                            doneLoading = true
                        case let .failure(error):
                            print(error.localizedDescription)
                        }
                    }
                }
            }
        } else {
            Task {
                if let audio = audioData, FileManager.default.fileExists(atPath: audio.url.path()) {
                    try? await audioService.setupRecorder(audioFilename: audio.url)
                    startDate = Date()
                    audioService.startRecording()
                } else {
                    let documentPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                    let audioFilename = documentPath.appendingPathComponent(UUID().description + ".m4a")
                    let newAudio = AudioData(url: audioFilename)
                    audioData = newAudio
                    try? await audioService.setupRecorder(audioFilename: audioFilename)
                    startDate = Date()
                    audioService.startRecording()
                }
            }
        }
    }
}
