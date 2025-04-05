import AppIntents
import AudioKit
import AVFoundation
import EventKit
import Foundation
import PhotosUI
import SwiftData
import SwiftUI
import SwiftWhisper
import SwipeActions
import UniformTypeIdentifiers
import UserNotifications
import WidgetKit

@Observable
class ItemStore {
    @MainActor
    static var modelContext: ModelContext {
        SharedState.sharedModelContainer.mainContext
    }

    static func allActiveItemsPredicate() -> Predicate<Item> {
        #Predicate<Item> { $0.parent == nil && !$0.archived }
    }

    static func activeItemsPredicated(for day: Date) -> Predicate<Item> {
        let start = Calendar.current.startOfDay(for: day)
        let end = Calendar.current.startOfDay(for: start.advanced(by: 86400))
        return #Predicate<Item> {
            $0.parent == nil && !$0.archived && start <= $0
                .timestamp && $0
                .timestamp < end
        }
    }

    static func filterByBook(items: [Item], book: Book?) -> [Item] {
        if let book {
            return items.filter { $0.tags.contains { book.tags.contains($0) } }
        } else {
            return items
        }
    }

    static func filterByChapter(items: [Item], chapter: Tag?) -> [Item] {
        if let chapter {
            return items.filter { $0.tags.contains(chapter) }
        } else {
            return items
        }
    }

    static func idPredicate(id: UUID) -> Predicate<Item> {
        #Predicate<Item> { $0.id == id }
    }

    static func eventItemPredicated(for eventCalendar: EventCalendar)
        -> Predicate<Item>
    {
        let id = eventCalendar.identifier
        return #Predicate<Item> {
            if let eventData = $0.eventData {
                return eventData.calendarIdentifier == id
            } else {
                return false
            }
        }
    }

    static func filterAllDayEvents(from items: [Item]) -> [Item] {
        return items
            .filter {
                if
                    let e =
                    $0.eventData
                {
                    return !e.allDay
                } else {
                    return true
                }
            }
    }

    static func allDayEvents(from items: [Item]) -> [Item] {
        return items
            .filter {
                if
                    let e =
                    $0.eventData
                {
                    return e.allDay
                } else {
                    return false
                }
            }
    }

    static func idsPredicate(ids: [UUID]) -> Predicate<Item> {
        #Predicate<Item> {
            ids.contains($0.id)
        }
    }

    @MainActor
    static func byId(id: UUID) -> Item? {
        let desc = FetchDescriptor<Item>(predicate: idPredicate(id: id))
        return try? modelContext.fetch(desc).first
    }

    @MainActor
    static func byIds(ids: [UUID]) -> [Item] {
        let desc =
            FetchDescriptor<Item>(predicate: ItemStore.idsPredicate(ids: ids))
        guard let items = try? modelContext.fetch(desc) else {
            return []
        }
        return items
    }

    @MainActor
    static func loadEventItems() -> [Item] {
//        let desc = FetchDescriptor<Item>(predicate: #Predicate<Item> {
//            $0.eventData != nil
//        })

        let desc = FetchDescriptor<Item>()
        let items = try? modelContext.fetch(desc)
        let res = items ?? []
        return res.filter { $0.eventData != nil }
    }

    @MainActor
    static func loadEventItems(by eventCalendar: EventCalendar) -> [Item] {
        let desc = FetchDescriptor<Item>()
        let items = try? modelContext.fetch(desc)
        let res = items ?? []
        let id = eventCalendar.identifier
        return res.filter {
            $0.eventData?.calendarIdentifier == id
        }
    }

    @MainActor
    static func byDay(date _: Date) -> [Item]? {
        let desc = FetchDescriptor<Item>(
            predicate: activeItemsPredicated(
                for: SharedState.widgetConductor
                    .date
            )
        )
        return try? modelContext.fetch(desc)
    }

    @MainActor
    static func itemExists(id: UUID) -> Bool {
        return byId(id: id) != nil
    }

    @MainActor
    static func create(
        id: UUID = UUID(),
        timestamp: Date,
        parent: Item? = nil,
        position: Int? = nil,
        archived: Bool = false,
        archivedAt: Date? = nil,
        tags: [Tag] = [],
        taskData: TaskData? = nil,
        eventData: EventData? = nil,
        imageData: ImageData? = nil,
        audioData: AudioData? = nil
    ) -> Item {
        let item = Item()
        item.id = id
        item.timestamp = timestamp
        item.parent = parent
        item.archived = archived
        item.archivedAt = archivedAt
        item.position = position ?? ItemStore.calculatePosition(for: timestamp)
        item.tags = tags
        item.taskData = taskData
        item.eventData = eventData
        item.imageData = imageData
        item.audioData = audioData
        return item
    }

    @MainActor
    static func deleteAllItems(for eventCalendar: EventCalendar) {
        let items = loadEventItems(by: eventCalendar)
        for i in items {
            modelContext.delete(i)
        }
    }

    @MainActor
    static func calculatePosition(
        item: Item
    ) -> Int {
        var items = loadItems(for: item.timestamp)

        guard let event = item.eventData else {
            return items.count
        }

        let events = items.filter {
            guard let e = $0.eventData else {
                return false
            }

            return e.startDate < event.startDate
        }

        guard
            let replace = events.sorted(by: { $0.position > $1.position })
                .first
        else {
            return items.count
        }

        items.sort(by: { $0.position < $1.position })
        items.insert(
            item,
            at: replace.position + 1
        )

        for (index, i) in items.enumerated() {
            i.position = index
        }

        return replace.position + 1
    }

    @MainActor
    static func calculatePosition(
        for day: Date
    ) -> Int {
        let items = loadItems(for: day)
        return items.count
    }

    @MainActor
    static func loadItems(for day: Date) -> [Item] {
        let desc =
            FetchDescriptor<Item>(predicate: activeItemsPredicated(for: day))
        let items = try? modelContext.fetch(desc)
        return items ?? []
    }

    static func updatePositions(
        items: [Item],
        indexSet: IndexSet,
        newIndex: Int
    ) -> (Bool, String) {
        for index in indexSet {
            let count = items.count
            let movedItem = items[index]

            if let movedEvent = movedItem.eventData {
                for i in 0 ..< newIndex {
                    let item = items[i]
                    if let itemEvent = item.eventData {
                        if movedEvent.startDate < itemEvent.startDate {
                            print("wrong above")
                            return (false, "Invalid event order!")
                        }
                    }
                }

                for i in newIndex ..< count {
                    let item = items[i]
                    if let itemEvent = item.eventData, itemEvent != movedEvent {
                        if movedEvent.startDate >= itemEvent.startDate {
                            print("wrong below")
                            return (false, "Invalid event order!")
                        }
                    }
                }
            }
        }

        var i = items
        i.move(fromOffsets: indexSet, toOffset: newIndex)
        for (index, item) in i.enumerated() {
            item.position = index
        }

        return (true, "Successfully moved item!")
    }
}

@Model
final class Item: Codable, Transferable, AppEntity, Listable {
    typealias Child = Item

    @Attribute(.unique) var id: UUID
    var timestamp: Date
    var position: Int
    var isExpanded = true
    var manuallyExpanded = false
    var archived = false
    var archivedAt: Date? = nil
    var parent: Item?
    @Relationship(deleteRule: .cascade, inverse: \Item.parent)
    var children: [Item] = []
    @Relationship(deleteRule: .noAction)
    var book: Book? = nil
    @Relationship(deleteRule: .noAction)
    var tags: [Tag] = []
    var text = ""
    var taskData: TaskData?
    var eventData: EventData?
    @Attribute(.externalStorage)
    var imageData: ImageData?
    var audioData: AudioData?

    var shadowTint: Color {
        book?.color ?? Color.clear
    }

    var fillTint: Color {
        book?.color ?? Color.white
    }

    init(
        id: UUID = UUID(),
        position: Int = 0,
        timestamp: Date = .init(),
        archived: Bool = false,
        archivedAt: Date? = nil,
        book: Book? = nil,
        tags: [Tag] = [],
        taskData: TaskData? = nil,
        eventData: EventData? = nil,
        imageData: ImageData? = nil,
        audioData: AudioData? = nil
    ) {
        self.id = id
        self.timestamp = Calendar.current.startOfDay(for: timestamp)
        self.archived = archived
        self.archivedAt = archivedAt
        self.position = position
        self.book = book
        self.tags = tags
        self.taskData = taskData
        self.eventData = eventData
        self.imageData = imageData
        self.audioData = audioData
    }

    var isTask: Bool {
        taskData != nil
    }

    var isTaskCompleted: Bool {
        taskData?.completedAt != nil
    }

    var isParent: Bool {
        parent == nil
    }

    var hasEvent: Bool {
        eventData != nil
    }

    var isEvent: Bool {
        parent == nil && eventData != nil
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

    @MainActor
    static func create(
        id: UUID = UUID(),
        timestamp: Date,
        position: Int? = nil,
        archived: Bool = false,
        archivedAt: Date? = nil,
        book: Book? = nil,
        tags: [Tag] = [],
        taskData: TaskData? = nil,
        eventData: EventData? = nil,
        imageData: ImageData? = nil,
        audioData: AudioData? = nil
    ) -> Item {
        let item = Item()
        item.id = id
        item.timestamp = Calendar.current.startOfDay(for: timestamp)
        item.archived = archived
        item.archivedAt = archivedAt
        item.position = position ?? ItemStore.calculatePosition(for: timestamp)
        item.book = book
        item.tags = tags
        item.taskData = taskData
        item.eventData = eventData
        item.imageData = imageData
        item.audioData = audioData
        return item
    }

    @MainActor
    func commit(
        timestamp: Date? = nil,
        text: String = "",
        taskData: TaskData?,
        eventFormData: EventData.FormData?,
        book: Book? = nil,
        tags: [Tag],
        children: [Item],
        syncEkEvent: Bool = true
    ) {
        if let timestamp {
            setTimestamp(timestamp)
        }
        self.text = text
        self.taskData = taskData

        if let eventFormData {
            createEvent(
                eventFormData.startDate,
                eventFormData.endDate,
                syncEkEvent
            )
        } else {
            deleteEvent()
        }

        if eventData != nil {
            updatePosition()
        }

        self.book = book
        self.tags = tags
        self.children = children

        commit()
    }

    @MainActor
    func commit(
        timestamp: Date? = nil,
        text: String = "",
        ekEvent: EKEvent
    ) {
        if let timestamp {
            setTimestamp(timestamp)
        }

        self.text = text
        taskData = taskData

        createEvent(from: ekEvent)

        commit()
    }

    @MainActor
    func commit() {
        if text.isNotEmpty {
            if !ItemStore.itemExists(id: id) {
                updatePosition()
            }
            ItemStore.modelContext.insert(self)
        } else {
            ItemStore.modelContext.delete(self)
        }
    }

    func archive() {
        deleteEvent()
        archived = true
        archivedAt = Date()
    }

    @MainActor
    func delete() {
        deleteEvent()
        ItemStore.modelContext.delete(self)
    }

    @MainActor
    func addNewChild() -> Item {
        let child = ItemStore.create(
            timestamp: timestamp,
            parent: self,
            position: children.count
        )
        child.taskData = taskData
        children.append(child)
        return child
    }

    @MainActor
    func setTimestamp(_ date: Date) {
        timestamp = date
        updatePosition()
    }

    @MainActor
    func updatePosition() {
        if eventData == nil {
            position = ItemStore.calculatePosition(for: timestamp)
        } else {
            position = ItemStore.calculatePosition(item: self)
        }
    }

    func toggleTaskData() {
        taskData = taskData == nil ? TaskData() : nil
    }

    func toggleTaskDataCompletedAt() {
        taskData?.completedAt = taskData?.completedAt == nil ? Date() : nil
    }

    func toggleEvent(_ startTime: Date? = nil, _ endTime: Date? = nil) {
        if eventData != nil {
            deleteEvent()
        } else if let startTime, let endTime {
            createEvent(startTime, endTime)
        } else {
            deleteEvent()
        }
    }

    private func createEvent(
        _ startDate: Date,
        _ endDate: Date,
        _ syncEkEvent: Bool = true
    ) {
        if !syncEkEvent {
            if let eventData {
                createNotification(eventData)
            }
            return
        }

        if
            var eventData,
            let id = eventData.eventIdentifier,
            let ek = CalendarSyncService.loadEkEventByIdentifier(id)
        {
            CalendarSyncService.update(ekEvent: ek, text, startDate, endDate)
            eventData.startDate = startDate
            eventData.endDate = endDate
            self.eventData = eventData
            return
        }

        var ek = CalendarSyncService.create(
            text,
            startDate,
            endDate
        )

        ek = CalendarSyncService.commit(ek)
        var eventData = EventData(from: ek)
        eventData.eventIdentifier = ek.eventIdentifier
        self.eventData = eventData
        createNotification(eventData)
    }

    private func createEvent(
        from ekEvent: EKEvent
    ) {
        let eventData = EventData(from: ekEvent)
        self.eventData = eventData
        createNotification(eventData)
    }

    private func deleteEvent() {
        guard let eventData else {
            return
        }

        if let id = eventData.eventIdentifier {
            CalendarSyncService.deleteByIdentifier(id)
        }

        deleteNotification()
        self.eventData = nil
    }

    private func createNotification(_ eventData: EventData) {
        var e = eventData
        let notifyAt = eventData.startDate.advanced(by: -1800)
        e.notifyAt = notifyAt

        let title = text
        let body = eventData.startDate.formatted(
            date: .omitted,
            time: .shortened
        )

        let comps = Calendar.current.dateComponents(
            [.day, .month, .year, .hour, .minute],
            from: notifyAt
        )

        NotificationSyncService.create(
            identifier: id.uuidString,
            title: title,
            body: body,
            dateMatching: comps,
            repeats: false
        )
    }

    private func deleteNotification() {
        guard var eventData else {
            return
        }

        eventData.notifyAt = nil
        NotificationSyncService.delete(id.uuidString)
    }

    @ViewBuilder
    var backgroundColor: some View {
        Tag.composeLinearGradient(for: tags)
            .opacity(0.6)
    }

    enum CodingKeys: String, CodingKey {
        case id
        case position
        case timestamp
    }

    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .item)
        ProxyRepresentation(exporting: \.text)
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

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: LocalizedStringResource(
            stringLiteral:
            text
        ))
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
        return ItemStore.byIds(ids: ids)
    }

    @MainActor
    func fetchItemById(_ id: UUID) async -> Item? {
        return ItemStore.byId(id: id)
    }
}

struct LocationData: Identifiable, Codable {
    var id: UUID = .init()
    var link: String?
}

protocol Formable {
    associatedtype FormData
    func formData() -> FormData
    mutating func apply(formData: FormData)
}

struct EventData: Identifiable, Codable, Equatable, Formable {
    var id: UUID = .init()
    var eventIdentifier: String?
    var startDate: Date
    var endDate: Date
    var notifyAt: Date?
    var calendarIdentifier: String?

    var allDay: Bool {
        let startOfDay = Calendar.current.startOfDay(for: startDate)
        return startDate == startOfDay && endDate == startOfDay
            .advanced(by: 86399)
    }

    struct FormData {
        var startDate: Date
        var endDate: Date
    }

    func formData() -> FormData {
        FormData(startDate: startDate, endDate: endDate)
    }

    mutating func apply(formData: FormData) {
        startDate = formData.startDate
        endDate = formData.endDate
    }

    init(from ekEvent: EKEvent) {
        startDate = ekEvent.startDate
        endDate = ekEvent.endDate
        eventIdentifier = ekEvent.eventIdentifier
        calendarIdentifier = ekEvent.calendar.calendarIdentifier
    }
}

struct TaskData: Identifiable, Codable, Equatable, Hashable, Formable {
    struct FormData {
        var completedAt: Date?
    }

    func formData() -> FormData {
        FormData(completedAt: completedAt)
    }

    mutating func apply(formData: FormData) {
        completedAt = formData.completedAt
    }

    var id: UUID = .init()
    var completedAt: Date?
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
            let documentPath = FileManager.default.urls(
                for: .documentDirectory,
                in: .userDomainMask
            )[0]
            let audioFilename = documentPath
                .appendingPathComponent(UUID().description + ".m4a")
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
            let documentPath = FileManager.default.urls(
                for: .documentDirectory,
                in: .userDomainMask
            )[0]
            let audioFilename = documentPath
                .appendingPathComponent(UUID().description + ".m4a")
            self.url = audioFilename
        }

        if let data = data {
            self.data = data
        }
    }
}

enum FocusedField: Hashable {
    case item(id: UUID), tag(id: UUID)
}

// struct EventDataRow: View {
//    var item: Item
//    @State var startTime: Date
//    @State var duration: TimeInterval
//    @State var endTime: Date
//    @State var isEvent: Bool
//    @State var panel: Panel = .hidden
//    enum Panel {
//        case hidden, startDate, endDate
//    }
//
//    init(item: Item) {
//        self.item = item
//        if let eventData = item.eventData {
//            startTime = eventData.startDate
//            endTime = eventData.endDate
//            duration = eventData.endDate
//                .timeIntervalSince(eventData.startDate)
//            isEvent = true
//        } else {
//            startTime = Date()
//            endTime = Date().advanced(by: 3600)
//            duration = 3600
//            isEvent = false
//        }
//    }
//
//    var body: some View {
//        VStack {
//            if isEvent {
//                VStack {
//                    switch panel {
//                        case .startDate:
//
//                            BindableDefaultDatePicker(
//                                date: $startTime
//                            )
//                            .datePickerStyle(.graphical)
//                            .labelsHidden()
//                            Divider()
//
//                            DatePicker(
//                                "",
//                                selection: $startTime,
//                                displayedComponents: [
//                                    .hourAndMinute,
//                                ]
//                            ).datePickerStyle(.wheel)
//                                .labelsHidden()
//                                .frame(height: 35)
//                                .clipShape(Capsule())
//
//                        case .endDate:
//                            BindableDefaultDatePicker(
//                                date: $endTime
//                            )
//                            .datePickerStyle(.graphical)
//                            .labelsHidden()
//                            Divider()
//                            DatePicker(
//                                "",
//                                selection: $endTime,
//                                displayedComponents: [
//                                    .hourAndMinute,
//                                ]
//                            ).datePickerStyle(.wheel)
//                                .labelsHidden()
//                                .frame(height: 35)
//                                .clipShape(Capsule())
//
//                        default:
//                            EmptyView()
//                    }
//                }
//
//            } else {
//                BindableDefaultDatePicker(date: $startTime)
//            }
//
//            Spacer().frame(height: 40)
//
//            HStack {
//                if isEvent {
//                    ToolbarButton(clipShape: Capsule()) {
//                        panel = panel == .startDate ? .hidden :
//                            .startDate
//                    } label: {
//                        HStack {
//                            Text(
//                                startTime
//                                    .formatted(
//                                        .dateTime.day().month()
//                                        .year(.twoDigits)
//                                    )
//                            )
//                            Divider().frame(height: 12)
//
//                            Text(
//                                startTime
//                                    .formatted(
//                                        .dateTime.hour().minute()
//                                    )
//                            )
//                        }
//                    }.offset(y: panel == .startDate ? -10 : 0)
//
//                    ToolbarButton(clipShape: Capsule()) {
//                        panel = panel == .endDate ? .hidden :
//                            .endDate
//                    } label: {
//                        HStack {
//                            Text(
//                                endTime
//                                    .formatted(
//                                        .dateTime.day().month()
//                                        .year(.twoDigits)
//                                    )
//                            )
//
//                            Divider().frame(height: 12)
//
//                            Text(
//                                endTime
//                                    .formatted(
//                                        .dateTime.hour().minute()
//                                    )
//                            )
//                        }
//                    }.offset(y: panel == .endDate ? -10 : 0)
//                } else {
//                    Spacer()
//                }
//
//                ToolbarButton {
//                    isEvent.toggle()
//                } label: {
//                    Image(systemName: isEvent ? "clock.fill" : "clock")
//                }
//            }
//        }
//        .onChange(of: startTime) {
//            endTime = startTime.advanced(by: abs(duration))
//        }.onChange(of: endTime) {
//            if endTime < startTime {
//                startTime = endTime.advanced(by: -abs(duration))
//            } else {
//                duration = endTime.timeIntervalSince(startTime)
//            }
//        }
//        .onDisappear {
//            if isEvent {
//                item.createEvent(startTime, endTime)
//            } else {
//                item.deleteEvent()
//            }
//        }
//    }
// }
// struct ImageDataButton: View {
//    @State private var imageItem: PhotosPickerItem?
//    @Binding var imageData: ImageData?
//
//    var body: some View {
//        if imageData?.data == nil {
//            PhotosPicker(selection: $imageItem, matching: .images) {
//                Image(systemName: "photo")
//            }.onChange(of: imageItem) {
//                self.saveImage()
//            }
//        } else {
//            Button {
//                self.deleteImage()
//            } label: {
//                Image(systemName: "photo.fill")
//            }
//        }
//    }
//
//    func deleteImage() {
//        imageItem = nil
//        imageData?.data = nil
//    }
//
//    fileprivate func saveImage() {
//        Task {
//            if
//                let image = try await imageItem?
//                    .loadTransferable(type: Data.self)
//            {
//                withAnimation {
//                    if var i = imageData {
//                        i.data = image
//                        self.imageData = i
//                    } else {
//                        self.imageData = ImageData(data: image)
//                    }
//                }
//            }
//        }
//    }
// }
//
// struct AudioRecordingRow: View {
//    @Environment(\.modelContext) private var modelContext: ModelContext
//    @Binding var audioData: AudioData?
//
//    @State private var audioRecorder: AVAudioRecorder?
//    @State private var audioSession: AVAudioSession?
//    @State var recordedURL: URL?
//    @State private var audioFile: AVAudioFile?
//
//    @State private var hasPermission = false
//    @State var isRecording = false
//    @State var recorderPrepared = false
//    @State private var doneLoading = false
//
//    @State var count = 0
//    @State var startDate: Date?
//    @State private var currentTime: TimeInterval = 0
//    @State private var transcript = ""
//
//    var showPlay: Bool {
//        if let url = audioData?.url {
//            return FileManager.default
//                .fileExists(atPath: url.path()) && !isRecording
//        }
//        return false
//    }
//
//    var body: some View {
//        HStack {
//            if self.showPlay {
//                AudioPlayerRow(
//                    doneLoading: self.$doneLoading,
//                    audioData: self.$audioData
//                )
//                .opacity(!self.doneLoading ? 0.5 : 1)
//                .onAppear {
//                    if let url = audioData?.url {
//                        self.doneLoading = FileManager.default
//                            .fileExists(atPath: url.path()) && !self
//                            .isRecording
//                    }
//                }
//                .disabled(!self.doneLoading)
//            } else {
//                Button {
//                    self.setupAudioRecorder()
//                    self.toggleRecording()
//                } label: {
//                    Image(
//                        systemName: self
//                            .isRecording ? "stop.circle.fill" : "circle.fill"
//                    )
//                    .resizable()
//                    .scaledToFit()
//                    .frame(width: 25, height: 25)
//                    .foregroundStyle(.red)
//                    .tint(.red)
//                }.buttonStyle(.plain)
//                    .tint(.red)
//                    .foregroundStyle(.red)
//                Spacer()
//            }
//        }
//        .onDisappear { try? self.audioSession?.setActive(false) }
//        .multilineTextAlignment(.leading)
//    }
//
//    private func setupAudioRecorder() {
//        deleteCorruptedRecording()
//        if !hasPermission {
//            Task {
//                await self.requestRecordPermission()
//            }
//        }
//    }
//
//    func toggleRecording() {
//        if isRecording {
//            stopRecording()
//            if let url = recordedURL {
//                Task {
//                    self.extractTextFromAudio(url) { result in
//                        switch result {
//                            case let .success(string):
//                                if var audio = audioData {
//                                    audio.transcript = string
//                                    self.audioData = audio
//                                } else {
//                                    self.transcript = string
//                                    let newAudio = AudioData(
//                                        url: url,
//                                        transcript: transcript
//                                    )
//                                    self.audioData = newAudio
//                                }
//                                self.doneLoading = true
//                            case let .failure(error):
//                                print(error.localizedDescription)
//                        }
//                    }
//                }
//            }
//            try? audioSession?.setActive(false)
//        } else {
//            Task {
//                let documentPath = FileManager.default.urls(
//                    for: .documentDirectory,
//                    in: .userDomainMask
//                )[0]
//                let audioFilename = documentPath
//                    .appendingPathComponent(UUID().description + ".m4a")
//                self.recordedURL = audioFilename
//                let newAudio = AudioData(url: audioFilename)
//                self.audioData = newAudio
//                try? await self.setupRecorder(audioFilename: audioFilename)
//                self.startDate = Date()
//                withAnimation { self.startRecording() }
//            }
//        }
//    }
//
//    func deleteRecording() {
//        guard let audioData else {
//            return
//        }
//        if FileManager.default.fileExists(atPath: audioData.url.path()) {
//            try? FileManager.default.removeItem(at: audioData.url)
//        }
//
//        withAnimation { self.audioData = nil }
//    }
//
//    func deleteCorruptedRecording() {
//        if
//            let audioData,
//            !FileManager.default.fileExists(atPath: audioData.url.path())
//        {
//            try? FileManager.default.removeItem(at: audioData.url)
//            self.audioData = nil
//        }
//    }
//
//    func requestRecordPermission() async {
//        if await AVAudioApplication.requestRecordPermission() {
//            hasPermission = true
//        } else {
//            hasPermission = false
//        }
//    }
//
//    func setupAudioSession() async throws {
//        if !hasPermission {
//            await requestRecordPermission()
//        }
//
//        if audioSession == nil {
//            let audioSession = AVAudioSession.sharedInstance()
//            try audioSession.setCategory(.playAndRecord, mode: .spokenAudio)
//            try? audioSession
//                .overrideOutputAudioPort(AVAudioSession.PortOverride.speaker)
//            try audioSession.setActive(true)
//            self.audioSession = audioSession
//        }
//    }
//
//    func setupRecorder(audioFilename: URL) async throws {
//        try? await setupAudioSession()
//        let recordingSettings: [String: Any] = [
//            AVFormatIDKey: kAudioFormatMPEG4AAC,
//            AVSampleRateKey: 12000,
//            AVNumberOfChannelsKey: 1,
//            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
//        ]
//        recordedURL = audioFilename
//        audioRecorder = try AVAudioRecorder(
//            url: audioFilename,
//            settings: recordingSettings
//        )
//        audioRecorder?.prepareToRecord()
//    }
//
//    func startRecording() {
//        audioRecorder?.record()
//        withAnimation { self.isRecording = true }
//    }
//
//    func stopRecording() {
//        audioRecorder?.stop()
//
//        if isRecording {
//            withAnimation { self.isRecording = false }
//        }
//
//        try? audioSession?.setActive(false)
//    }
//
//    func extractTextFromAudio(
//        _ audioURL: URL,
//        completionHandler: @escaping (Result<String, Error>) -> Void
//    ) {
//        let modelURL = Bundle.main.url(
//            forResource: "tiny",
//            withExtension: "bin"
//        )!
//        let whisper = Whisper(fromFileURL: modelURL)
//        convertAudioFileToPCMArray(fileURL: audioURL) { result in
//            switch result {
//                case let .success(success):
//                    Task {
//                        do {
//                            let segments = try await whisper
//                                .transcribe(audioFrames: success)
//                            completionHandler(.success(
//                                segments.map(\.text)
//                                    .joined()
//                            ))
//                        } catch {
//                            completionHandler(.failure(error))
//                        }
//                    }
//                case let .failure(failure):
//                    completionHandler(.failure(failure))
//            }
//        }
//    }
//
//    func convertAudioFileToPCMArray(
//        fileURL: URL,
//        completionHandler: @escaping (Result<[Float], Error>) -> Void
//    ) {
//        var options = FormatConverter.Options()
//        options.format = .wav
//        options.sampleRate = 16000
//        options.bitDepth = 16
//        options.channels = 1
//        options.isInterleaved = false
//
//        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory())
//            .appendingPathComponent(UUID().uuidString)
//        let converter = FormatConverter(
//            inputURL: fileURL,
//            outputURL: tempURL,
//            options: options
//        )
//        converter.start { error in
//            if let error {
//                completionHandler(.failure(error))
//                return
//            }
//
//            let data = try! Data(contentsOf: tempURL)
//
//            let floats = stride(from: 44, to: data.count, by: 2).map {
//                data[$0 ..< $0 + 2].withUnsafeBytes {
//                    let short = Int16(littleEndian: $0.load(as: Int16.self))
//                    return max(-1.0, min(Float(short) / 32767.0, 1.0))
//                }
//            }
//
//            try? FileManager.default.removeItem(at: tempURL)
//
//            completionHandler(.success(floats))
//        }
//    }
// }
//
// struct AudioPlayerRow: View {
//    @Binding var doneLoading: Bool
//    @Binding var audioData: AudioData?
//    @State private var player: AVPlayer?
//    @State private var isPlaying = false
//    @State private var audioSession: AVAudioSession?
//    @State private var transcript = ""
//    @FocusState private var transcriptFocus: Bool
//
//    var body: some View {
//        if let data = audioData {
//            HStack {
//                Button(action: self.togglePlayback) {
//                    Image(
//                        systemName: self
//                            .isPlaying ? "stop.circle.fill" :
//                            "play.circle.fill"
//                    )
//                    .resizable()
//                    .scaledToFit()
//                    .frame(width: 20, height: 20)
//                    .padding(.horizontal, 5)
//                }.buttonStyle(.plain)
//
//                if !data.transcript.isEmpty {
//                    TextField(
//                        "[transcript]",
//                        text: self.$transcript,
//                        axis: .vertical
//                    )
//                    .focused(self.$transcriptFocus)
//                    .fixedSize(horizontal: false, vertical: true)
//                    .onChange(of: self.transcriptFocus) {
//                        if !self.transcriptFocus {
//                            if self.transcript.isNotEmpty {
//                                self.audioData?.transcript = self.transcript
//                            }
//                        }
//                    }
//                    .onAppear {
//                        self.transcript = data.transcript
//                    }.onSubmit {
//                        if self.transcript.isNotEmpty {
//                            self.audioData?.transcript = self.transcript
//                        }
//                    }.submitScope()
//                } else {
//                    HStack {
//                        ProgressView("Transcribing...")
//                            .padding(.vertical)
//                    }
//                    .onChange(of: self.audioData?.transcript) {
//                        guard let d = audioData else {
//                            return
//                        }
//                        if
//                            d.transcript.isNotEmpty &&
//                            d.transcript != self.transcript
//                        {
//                            self.transcript = d.transcript
//                        }
//                    }
//                    .labelsHidden()
//                    .progressViewStyle(.linear)
//                }
//            }
//        }
//    }
//
//    func deleteRecording() {
//        guard let audioData else {
//            return
//        }
//        if FileManager.default.fileExists(atPath: audioData.url.path()) {
//            try? FileManager.default.removeItem(at: audioData.url)
//        }
//
//        self.audioData = nil
//    }
//
//    private func setupAudioPlayer() {
//        guard let data = audioData else {
//            return
//        }
//
//        if !FileManager.default.fileExists(atPath: data.url.path()) {
//            withAnimation {
//                self.audioData = nil
//            }
//        }
//
//        let audioSession = AVAudioSession.sharedInstance()
//        try? audioSession.setCategory(.playback, mode: .spokenAudio)
//        try? audioSession
//            .overrideOutputAudioPort(AVAudioSession.PortOverride.speaker)
//        try? audioSession.setActive(true)
//        self.audioSession = audioSession
//
//        player = AVPlayer(url: data.url)
//
//        NotificationCenter.default.addObserver(
//            forName: .AVPlayerItemDidPlayToEndTime,
//            object: player?.currentItem,
//            queue: .main
//        ) { _ in
//            self.isPlaying = false
//            self.player?.seek(to: .zero)
//        }
//    }
//
//    private func togglePlayback() {
//        setupAudioPlayer()
//        guard let player = player else {
//            return
//        }
//        if isPlaying {
//            player.seek(to: .zero)
//            player.pause()
//        } else {
//            player.play()
//        }
//        withAnimation {
//            self.isPlaying.toggle()
//        }
//    }
// }
