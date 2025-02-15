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

struct ItemList: View {
    @Environment(\.modelContext) private var modelContext: ModelContext
    @Environment(DayDetailsConductor.self) private var conductor: DayDetailsConductor
    @Environment(
        CalendarService.self
    ) private var calendarService: CalendarService

    @Binding var editItem: Item?
    @State var items: [Item]

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
                ForEach(items.indices, id: \.self) { index in
                    ItemListRow(editItem: $editItem, item: $items[index])
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .onChange(of: items[index].eventData?.startDate) {
                            dynamicallyReorderList(item: items[index])
                        }
                        .onAppear {
                            if !items[index].hasNote && conductor.editItem == nil {
                                SharedState.deleteItem(items[index])
                            }
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                SharedState.deleteItem(items[index])
                            } label: {
                                Image(systemName: "trash")
                            }
                            .tint(.black)
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

struct EditItemForm: View {
    @Environment(DayDetailsConductor.self) private var conductor: DayDetailsConductor
    @Environment(\.modelContext) private var modelContext: ModelContext
    @State var editItem: Item
    var position: Int

    var body: some View {
        @Bindable var conductor = conductor
        ItemForm(
            editItem: $editItem,
            timestamp: $conductor.date,
            position: position
        )
    }
}

struct ItemListRow: View {
    @Environment(DayDetailsConductor.self) private var conductor: DayDetailsConductor
    @Environment(\.modelContext) private var modelContext: ModelContext
    @Environment(CalendarService.self) private var calendarService: CalendarService

    @Binding var editItem: Item?
    @Binding var item: Item
    init(editItem: Binding<Item?>, item: Binding<Item>) {
        _editItem = editItem
        _item = item
        let item = item.wrappedValue
        _taskData = State(initialValue: item.taskData)
        _subtasks = State(initialValue: item.taskData?.subtasks ?? [])
        _noteData = State(initialValue: item.noteData)
        _eventData = State(initialValue: item.eventData)
        _imageData = State(initialValue: item.imageData)
        _audioData = State(initialValue: item.audioData)
    }

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
    @FocusState var childFocus: Bool
    @FocusState var tagSearchFocus: Bool

    @State var expand: Bool = true
    var hasSubTasks: Bool {
        if let task = taskData { return task.subtasks.isNotEmpty } else { return false }
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
                SubTasksDataListRow(subtasks: $subtasks)
            }
        } label: {
            HStack {
                TaskDataRow(taskData: $taskData)
                    .fixedSize(horizontal: false, vertical: true)
                Text(noteData.text)
                    .fixedSize(horizontal: false, vertical: true)
                    .focused($noteFocus)

                Spacer()
                Text(startString + "|" + endString)
            }
        }.tint(.white)
    }

    var body: some View {
        @Bindable var conductor = conductor
        Button(action: { conductor.editItem = editItem }) {
            imageView
            if hasSubTasks {
                subtaskView
            } else {
                HStack {
                    TaskDataRow(taskData: $taskData)
                    Text(noteData.text)
                    Spacer()
                    Text(startString + "|" + endString)
                }
            }

            AudioRecordingView(audioData: $audioData)
            TagDataRow(tags: $assignedTags)
        }
        .listRowBackground(Color.clear)
        .onAppear {
            if eventData != nil {
                calendarService.requestAccessToCalendar()
            }
        }
        .tint(.white)
    }

    fileprivate func submitItem() {
        noteFocus = false
        if var t = taskData {
            t.subtasks.removeAll()
            t.subtasks.append(contentsOf: subtasks)
            taskData = t
        }

        if let editItem = editItem {
            editItem.tags = tags
            editItem.noteData = noteData
            editItem.taskData = taskData
            editItem.eventData = eventData
            editItem.imageData = imageData
            editItem.audioData = audioData
            self.editItem = editItem
            try? modelContext.save()
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

struct ItemForm: View {
    @Environment(DayDetailsConductor.self) private var conductor: DayDetailsConductor
    @Environment(\.modelContext) private var modelContext: ModelContext
    @Environment(CalendarService.self) private var calendarService: CalendarService

    @Binding var editItem: Item
    @Binding var timestamp: Date
    @State var position: Int

    init(editItem: Binding<Item>, timestamp: Binding<Date>, position: Int) {
        _editItem = editItem
        _timestamp = timestamp
        self.position = position
         let i = editItem.wrappedValue
            _taskData = State(initialValue: i.taskData)
            _subtasks = State(initialValue: i.taskData?.subtasks ?? [])
            _noteData = State(initialValue: i.noteData)
            _eventData = State(initialValue: i.eventData)
            _imageData = State(initialValue: i.imageData)
            _audioData = State(initialValue: i.audioData)
    }

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
    @FocusState var childFocus: Bool
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
    var subtaskView: some View { DisclosureGroup(isExpanded: $expand) {
        HStack {
            RoundedRectangle(cornerRadius: 2).fill(Color.gray).frame(width: 1)
                .padding(.horizontal, 8)
            VStack {
                SubTasksDataRow(subtasks: $subtasks)
            }
        }
    } label: {
        HStack {
            TaskDataRow(taskData: $taskData).fixedSize(horizontal: false, vertical: true)
            NoteDataRow(noteData: $noteData, subtasks: $subtasks)
                .fixedSize(horizontal: false, vertical: true)
                .focused($noteFocus)

            Button(action: submitItem) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 20))
            }.disabled(noteData.text.isEmpty)
                .animation(.smooth, value: noteData.text.isNotEmpty)
        }
    }.tint(.white) }

    var body: some View {
        @Bindable var conductor = conductor
        VStack {
            imageView

            HStack {
                if hasSubTasks {
                    subtaskView

                } else {
                    TaskDataRow(taskData: $taskData)
                    NoteDataRow(noteData: $noteData, subtasks: $subtasks)
                        .focused($noteFocus)

                    Button(action: submitItem) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20))
                    }.disabled(noteData.text.isEmpty)
                        .animation(.smooth, value: noteData.text.isNotEmpty)
                }
            }
            .listRowBackground(Color.clear)

            AudioRecordingView(audioData: $audioData)
            TagDataRow(tags: $assignedTags)
        }
        .overlay {
            if noteData.text.isNotEmpty {
                VStack {
                    // Button(action: cancelEdit) {
                    //     Color.clear
                    // }

                    HStack {}.padding().background(.clear)
                }.offset(y: -50)
            }
        }
        .onAppear {
            if eventData != nil {
                calendarService.requestAccessToCalendar()
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                HStack {
                    ImageDataButton(imageData: $imageData)
                    AudioDataButton(audioData: $audioData, timestamp: $timestamp)
                    TagDataButton(show: $showTag)
                    TaskDataButton(taskData: $taskData, subtasks: $subtasks, noteData: $noteData)
                    EventDataButton(eventData: $eventData, timestamp: $timestamp)

                    if let e = eventData {
                        EventDataRow(editItem: $conductor.editItem, eventData: e)
                    }
                }
            }
        }
        .tint(.white)
    }

    fileprivate func submitItem() {
        noteFocus = false
        if var t = taskData {
            t.subtasks.removeAll()
            t.subtasks.append(contentsOf: subtasks)
            taskData = t
        }

    let item = editItem
            item.position = position
            item.timestamp = timestamp
            item.tags = tags
            item.noteData = noteData
            item.taskData = taskData
            item.eventData = eventData
            item.imageData = imageData
            item.audioData = audioData
            SharedState.commitItem(item: item)
        try? modelContext.save()
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
    @Binding var subtasks: [SubTaskData]
    @FocusState var focus: Bool

    var formatter: RelativeDateTimeFormatter {
        let formatter =
            RelativeDateTimeFormatter()
        return formatter
    }

    func format(_ date: Date, _: Date) -> String {
        return formatter.localizedString(for: date, relativeTo: .now)
    }

    var body: some View {
        TextField("...", text: $noteData.text, axis: .vertical)
            .onSubmit {
                withAnimation {
                    let subtask = SubTaskData()
                    subtasks.append(subtask)
                }
            }
            .lineLimit(20)
            .onAppear { focus = noteData.text.isEmpty }
            .focused($focus)
            .multilineTextAlignment(.leading)
    }
}

struct NoteDataRowLabel: View {
    @Environment(\.modelContext) private var modelContext: ModelContext
    @Environment(DayDetailsConductor.self) private var conductor: DayDetailsConductor
    @Binding var item: Item

    var body: some View {
        Button(action: setEditItem) {
            HStack {
                Text(item.noteData.text)
                Spacer()
            }
        }
        .disabled(conductor.isEditingItem)
        .buttonStyle(.plain)
        .scaleEffect(item.taskData?.completedAt != nil ? 0.8 : 1, anchor: .leading)
    }

    fileprivate func setEditItem() {
        withAnimation {
            conductor.editItem = item
        }
    }
}

struct TaskDataButton: View {
    @Environment(\.modelContext) private var modelContext: ModelContext
    @Binding var taskData: TaskData?
    @Binding var subtasks: [SubTaskData]
    @Binding var noteData: NoteData

    var isTask: Bool {
        return taskData != nil
    }

    var body: some View {
        Button {
            toggleTaskData()
        } label: {
            Image(systemName: isTask ? "checkmark.circle.fill" : "checkmark.circle")
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
                        subtasks.append(subtaskData)
                    }
                }
                task.subtasks.removeAll()
                task.subtasks.append(contentsOf: subtasks)
                self.taskData = task
                WidgetCenter.shared.reloadAllTimelines()
            }
        }
    }
}

struct TaskDataRow: View {
    @Environment(\.modelContext) private var modelContext: ModelContext
    @Binding var taskData: TaskData?

    var body: some View {
        if var task = taskData {
            Button {
                if task.completedAt == nil {
                    withAnimation {
                        task.completedAt = Date()
                        taskData = task
                        WidgetCenter.shared.reloadAllTimelines()
                    }
                } else {
                    withAnimation {
                        task.completedAt = nil
                        taskData = task
                        WidgetCenter.shared.reloadAllTimelines()
                    }
                }
            } label: {
                Image(systemName: task.completedAt == nil ? "square" : "square.fill")
            }
        }
    }
}

struct SubTasksDataListRow: View {
    @Binding var subtasks: [SubTaskData]

    var body: some View {
        if subtasks.isNotEmpty {
            ScrollView {
                ForEach(
                    subtasks.sorted(by: { first, second in first.position < second.position }).indices,
                    id: \.self
                ) { index in
                    SubTaskDataListRow(
                        subtask: $subtasks[index]
                    ).scrollTargetLayout()
                        .fixedSize(horizontal: false, vertical: true)
                        .scrollClipDisabled(subtasks.count > 0)
                }
            }
        }
    }
}

struct SubTasksDataRow: View {
    @Binding var subtasks: [SubTaskData]

    var body: some View {
        if subtasks.isNotEmpty {
            ScrollViewReader { proxy in
                ScrollView {
                    ForEach(
                        subtasks.sorted(by: { first, second in first.position < second.position }).indices,
                        id: \.self
                    ) { index in
                        SubTaskDataRow(
                            subtask: $subtasks[index],
                            subtasks: $subtasks,
                            position: index
                        ).scrollTargetLayout()
                            .fixedSize(horizontal: false, vertical: true)
                            .scrollClipDisabled(subtasks.count > 0)
                    }
                    .onSubmit {
                        if let last = subtasks.last {
                            proxy.scrollTo(last)
                        }
                    }
                }
            }
        }
    }
}

struct SubTaskDataRow: View {
    @Binding var subtask: SubTaskData
    @Binding var subtasks: [SubTaskData]
    let position: Int

    @FocusState var focused: Bool

    var body: some View {
        HStack {
            ToggleCompletedAt(completedAt: $subtask.completedAt)
            TextField("", text: $subtask.noteData.text)
                .focused($focused)
                .onAppear { focused = subtask.noteData.text.isEmpty }
            Spacer()
        }.ignoresSafeArea()
            .onChange(of: focused) {
                if !focused && subtask.noteData.text.isEmpty {
                    subtasks.removeAll(where: { $0.id == subtask.id })
                }
            }
            .onSubmit {
                if focused && subtask.noteData.text.isNotEmpty {
                    withAnimation {
                        let newSubtask = SubTaskData(position: subtask.position + 1, noteData: NoteData(text: ""))
                        subtasks.append(newSubtask)
                    }
                } else {
                    focused = false
                }
            }.environment(\.defaultMinListRowHeight, 15)
    }
}

struct SubTaskDataListRow: View {
    @Binding var subtask: SubTaskData

    var body: some View {
        HStack {
            ToggleCompletedAt(completedAt: $subtask.completedAt)
            Text(subtask.noteData.text)
            Spacer()
        }.ignoresSafeArea()
            .environment(\.defaultMinListRowHeight, 15)
    }
}

struct ToggleCompletedAt: View {
    @Environment(\.modelContext) private var modelContext: ModelContext
    @Binding var completedAt: Date?

    var body: some View {
        Button {
            if completedAt == nil {
                withAnimation {
                    completedAt = Date()
                    WidgetCenter.shared.reloadAllTimelines()
                }
            } else {
                withAnimation {
                    completedAt = nil
                    WidgetCenter.shared.reloadAllTimelines()
                }
            }
        } label: {
            Image(systemName: completedAt == nil ? "square" : "square.fill")
        }
    }
}

struct EventDataButton: View {
    @Environment(\.modelContext) private var modelContext: ModelContext
    @Environment(CalendarService.self) private var calendarService: CalendarService
    @Binding var eventData: EventData?
    @Binding var timestamp: Date

    var body: some View {
        Button {
            toggleEventData()
        } label: { Image(systemName: eventData != nil ? "clock.fill" : "clock") }
    }

    fileprivate func toggleEventData() {
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
                    startDate: timestamp,
                    endDate: timestamp.advanced(by: 3600)
                )
            }
        }
    }
}

struct EventDataRow: View {
    @Environment(\.modelContext) private var modelContext: ModelContext
    @Environment(CalendarService.self) private var calendarService: CalendarService
    @Binding var editItem: Item?
    @State var event: EventData
    @State var interval: TimeInterval = 3600
    @State var deleteEvent: Bool = false
    @State var notify: Bool = false

    init(editItem: Binding<Item?>, eventData: EventData) {
        if let i = editItem.wrappedValue {
            let e = i.eventData ?? eventData
            _event = State(initialValue: e)
            interval = e.endDate.timeIntervalSince(e.startDate)
        } else {
            _event = State(initialValue: eventData)
        }
        _editItem = editItem
    }

    var startString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: event.startDate)
    }

    var endString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: event.endDate)
    }

    var body: some View {
        Text(startString)
            .frame(width: 50)
            .overlay {
                DatePicker("start:", selection: $event.startDate, displayedComponents: [.hourAndMinute])
                    .datePickerStyle(.compact)
                    .colorMultiply(.clear)
                    .labelsHidden()
                    .onChange(of: event.startDate) {
                        updateEndDate()
                    }
            }

        RoundedRectangle(cornerRadius: 2).background(.white).frame(width: 2, height: 15)

        Text(endString)
            .frame(width: 50)
            .overlay {
                DatePicker("end:", selection: $event.endDate, displayedComponents: [.hourAndMinute])
                    .datePickerStyle(.compact)
                    .colorMultiply(.clear)
                    .labelsHidden()
                    .onChange(of: event.endDate) {
                        updateStartDate()
                    }
            }
            .onAppear {
                if !calendarService.accessToCalendar {
                    calendarService.requestAccessToCalendar()
                }
                notify = event.notifyAt != nil
                if let i = editItem {
                    i.eventData = event
                    editItem = i
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
        event.endDate = event.startDate.advanced(by: interval)
        if let i = editItem {
            i.eventData = event
            editItem = i
        }
    }

    fileprivate func updateStartDate() {
        if event.endDate < event.startDate {
            event.startDate = event.endDate.advanced(by: -interval)
        } else {
            interval = event.endDate.timeIntervalSince(event.startDate)
        }

        if let i = editItem {
            i.eventData = event
            editItem = i
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
    @Binding var tags: [Tag]

    var body: some View {
        if tags.isNotEmpty {
            HStack {
                ScrollView(.horizontal) {
                    HStack {
                        ForEach(tags) { tag in
                            Button {
                                deleteTag(tag)
                            } label: {
                                Text(tag.name)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 6)
                                    .font(.custom("GohuFont11NFM", size: 14))
                            }
                            .background {
                                RoundedRectangle(cornerRadius:
                                    20).fill(Color(uiColor: UIColor(hex:
                                    tag.colorHex))).stroke(.white).opacity(0.75)
                            }
                            .tint(.white)
                            .padding(.vertical, 4)
                            .padding(.horizontal, 2)
                        }
                    }
                }
            }
            .padding(10)
        }
    }

    fileprivate func deleteTag(_ tag: Tag) {
        withAnimation {
            tags.removeAll(where: { $0.id == tag.id })
        }
    }
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

struct ImageDataRowLabel: View {
    var imageData: ImageData
    var namespace: Namespace.ID

    @ViewBuilder
    var imageView: some View {
        if let image = imageData.image {
            image.resizable().scaledToFit()
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
                .navigationTransition(.zoom(sourceID: imageData.id, in: namespace))
        } label: {
            imageView
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding(2)
                .padding(.horizontal, 12)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .matchedTransitionSource(id: imageData.id, in: namespace)
        }
    }
}

struct AudioDataButton: View {
    @Binding var audioData: AudioData?
    @Binding var timestamp: Date

    var hasAudio: Bool {
        return audioData?.url != nil
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

    var body: some View {
        if let data = audioData {
            HStack {
                Button(action: togglePlayback) {
                    Image(systemName: isPlaying ? "square.circle.fill" : "play.circle.fill")
                        .resizable()
                        .frame(width: 30, height: 30)
                }

                if !data.transcript.isEmpty {
                    Text(data.transcript)
                }
            }
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
    @State private var showPlay: Bool = false

    @State var count: Int = 0

    @State var startDate: Date?

    var body: some View {
        if audioData != nil {
            if showPlay {
                HStack {
                    AudioPlayerView(audioData: $audioData)
                        .disabled(audioData == nil)

                    Image(systemName: "play.circle.fill")
                        .resizable()
                        .frame(width: 30, height: 30)
                }
            } else {
                HStack {
                    Button(action: toggleRecording) {
                        Image(systemName: audioService.isRecording ?
                            "circle.fill" : "microphone.circle.fill")
                            .resizable()
                            .foregroundColor(audioService.isRecording ? .red : .white)
                    }.disabled(!audioService.hasPermission)
                        .frame(width: 30, height: 30)
                    Spacer()
                }
                .onAppear {
                    setupAudioRecorder()
                }
            }
        }
    }

    private func setupAudioRecorder() {
        if !audioService.hasPermission {
            Task {
                await audioService.requestRecordPermission()
            }
        }

        showPlay = audioData != nil
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
                if let audio = audioData {
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
