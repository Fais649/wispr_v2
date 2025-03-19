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

@Model
final class Item: Codable, Transferable, AppEntity {
    @Attribute(.unique) var id: UUID
    var timestamp: Date
    var position: Int
    var isExpanded: Bool = true
    var manuallyExpanded: Bool = false
    var archived: Bool = false
    var archivedAt: Date? = nil
    var parent: Item?
    @Relationship(deleteRule: .cascade, inverse: \Item.parent)
    var children: [Item] = []
    @Relationship(deleteRule: .noAction)
    var tags: [Tag] = []

    var text: String = ""
    var taskData: TaskData?
    var eventData: EventData?
    @Attribute(.externalStorage)
    var imageData: ImageData?
    var audioData: AudioData?

    init(
        id: UUID = UUID(),
        position: Int = 0,
        timestamp: Date = .init(),
        archived: Bool = false,
        archivedAt: Date? = nil,
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

    static func create(
        id: UUID = UUID(),
        position: Int = 0,
        timestamp: Date = .init(),
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
        item.timestamp = Calendar.current.startOfDay(for: timestamp)
        item.archived = archived
        item.archivedAt = archivedAt
        item.position = position
        item.tags = tags
        item.taskData = taskData
        item.eventData = eventData
        item.imageData = imageData
        item.audioData = audioData
        return item
    }

    func addNewChild() -> Item {
        let child = Item.create(position: children.count)
        children.append(child)
        return child
    }

    func setTimestamp(_ date: Date) {
        timestamp = Calendar.current.startOfDay(for: date)
    }

    func commit(
        _ modelContext: ModelContext,
        text: String = "",
        taskData: TaskData?,
        eventData: EventData?,
        tags: [Tag],
        children: [Item]
    ) {
        self.text = text
        self.taskData = taskData
        self.eventData = eventData
        self.tags = tags
        self.children = children

        if self.text.isNotEmpty {
            modelContext.insert(self)
        } else {
            modelContext.delete(self)
        }
    }

    func toggleTaskData() {
        taskData = taskData == nil ? TaskData() : nil
    }

    func toggleCompletedAt() {
        taskData?.completedAt = taskData?.completedAt == nil ? Date() : nil
    }

    @ViewBuilder
    var backgroundColor: some View {
        Tag.composeLinearGradient(for: tags)
            .opacity(0.6)
    }

    struct DGroups: View {
        @Environment(\.modelContext) private var modelContext: ModelContext
        var items: [Item]
        var animated: Bool = false
        var withSwipe: Bool = false
        @State var flashError: Bool = false

        var body: some View {
            if flashError {
                HStack {
                    Image(systemName: "xmark").font(.system(size: 32))
                    Text("Invalid event order!")
                }.onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() +
                        2.5)
                    {
                        flashError = false
                    }
                }
            }

            ForEach(items) { item in
                DGroup(item: item, animated: animated, withSwipe: withSwipe)
            }
            .onMove { indexSet, newIndex in
                for index in indexSet {
                    let count = self.items.count
                    let movedItem = self.items[index]

                    if let movedEvent = movedItem.eventData {
                        for i in 0 ..< newIndex {
                            let item = items[i]
                            if let itemEvent = item.eventData {
                                if movedEvent.startDate < itemEvent.startDate {
                                    withAnimation {
                                        flashError = true
                                    }
                                    print("bad order above")
                                    return
                                }
                            }
                        }

                        for i in newIndex ..< count {
                            let item = items[i]
                            if let itemEvent = item.eventData {
                                if movedEvent.startDate >= itemEvent.startDate {
                                    withAnimation {
                                        flashError = true
                                    }
                                    print("bad order below")
                                    return
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
            }
            .opacity(flashError ? 0 : 1)
        }
    }

    struct DGroup: View {
        @Environment(\.modelContext) private var modelContext: ModelContext
        @Environment(Navigator.self) private var nav: Navigator
        var item: Item
        var animated: Bool = false
        var withSwipe: Bool = false
        @State var opacity: CGFloat = 1
        @State var blur: CGFloat = 0

        var body: some View {
            DisclosureGroup {
                ForEach(item.children) { child in
                    row(child)
                }.onMove { indexSet, newIndex in
                    item.children.move(fromOffsets: indexSet, toOffset: newIndex)
                    for (index, child) in item.children.enumerated() {
                        child.position = index
                    }
                }
            } label: {
                label
            }
            .disclosureGroupStyle(ItemDetailsStack(isAnimated: animated, hideExpandButton: item.children.isEmpty))
        }

        var label: some View {
            AniButton {
                nav.selectedDate = item.timestamp
                nav.path.append(.itemForm(item: item))
            } label: {
                HStack {
                    if item.text.isNotEmpty {
                        Text(item.text)
                    }
                    Spacer()
                }
            }
            .contentShape(Rectangle())
            .background(item.backgroundColor)
            .buttonStyle(.plain)
            .swipeActions(edge: .leading) {
                archiveButton(item)
            }.swipeActions(edge: .trailing) {
                deleteButton(item)
            }
        }

        func row(_ child: Item) -> some View {
            HStack(spacing: 0) {
                if var task = child.taskData {
                    AniButton {
                        task.completedAt = task.completedAt == nil ? Date() : nil
                        child.taskData = task
                    } label: {
                        Image(systemName: task.completedAt == nil ? "circle.dotted" : "circle.fill")
                    }
                }

                Text(child.text)
                Spacer()
            }
            .swipeActions(edge: .trailing) {
                deleteButton(child)
            }
        }

        @ViewBuilder
        func archiveButton(_ item: Item) -> some View {
            AniButton {
                archive(item)
            } label: {
                Image(systemName: "archivebox.fill")
            }
            .tint(.clear)
        }

        @ViewBuilder
        func deleteButton(_ item: Item) -> some View {
            AniButton {
                delete(item)
            } label: {
                Image(systemName: "trash.fill")
            }
            .tint(.clear)
        }

        func archive(_ item: Item) {
            checkEventData(item)
            withAnimation {
                item.archived = true
                item.archivedAt = Date()
            }
        }

        func delete(_ item: Item) {
            checkEventData(item)
            withAnimation {
                modelContext.delete(item)
            }
        }

        func checkEventData(_ item: Item) {
            if let event = item.eventData {
                Task {
                    let eh = EventHandler(item, event)
                    _ = eh.processEventData()
                }
            }
        }
    }

    struct DGroupHeader: View {
        @Environment(Navigator.self) private var nav: Navigator
        var item: Item

        var body: some View {
            AniButton {
                nav.selectedDate = item.timestamp
                nav.path.append(contentsOf: [.dayScreen, .itemForm(item: item)])
            } label: {
                Text(item.text)
            }.background(item.backgroundColor)
                .buttonStyle(.plain)
        }
    }

    struct DGroupContent: View {
        @Environment(\.modelContext) private var modelContext: ModelContext
        @Environment(Navigator.self) private var nav: Navigator
        var item: Item

        var body: some View {
            ForEach(item.children) { child in
                HStack(spacing: 0) {
                    if var task = child.taskData {
                        AniButton {
                            task.completedAt = task.completedAt == nil ? Date() : nil
                            child.taskData = task
                        } label: {
                            Text(task.completedAt == nil ? "[ ]" : "[x]")
                        }
                    }

                    Text(child.text)
                    Spacer()
                }
            }
        }
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
        DisplayRepresentation(title: LocalizedStringResource(stringLiteral:
            text))
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

struct TaskData: Identifiable, Codable, Equatable, Hashable {
    var id: UUID = .init()
    var completedAt: Date?
}

struct LocationData: Identifiable, Codable {
    var id: UUID = .init()
    var link: String?
}

struct EventData: Identifiable, Codable, Equatable {
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

enum FocusedField: Hashable {
    case item(id: UUID), tag(id: UUID)
}

struct ItemForm: View {
    @Environment(Navigator.self) private var nav: Navigator
    @Environment(\.modelContext) private var modelContext: ModelContext
    @Environment(CalendarService.self) private var calendarService: CalendarService
    @FocusState var focus: FocusedField?

    @State var item: Item

    @State private var text: String
    @State private var taskData: TaskData?
    @State private var eventData: EventData?
    @State private var children: [Item]
    @State private var tags: [Tag]
    @State private var sheet: ItemFormSheets? = nil

    init(item: Item? = nil) {
        let i = item ?? Item.create(position: 0)
        self.item = i
        text = i.text
        taskData = i.taskData
        eventData = i.eventData
        children = i.children
        tags = i.tags
    }

    enum ItemFormSheets: String, Identifiable {
        case tags, event
        var id: Self { self }
    }

    @State var isExpanded = true

    var body: some View {
        List {
            DisclosureGroup(isExpanded: $isExpanded) {
                ForEach(children, id: \.self) { child in
                    Children(children: $children, child: child)
                        .focused($focus, equals: .item(id: child.id))
                        .fontWeight(.light)
                }.onAppear {
                    children.sort { $0.position < $1.position }
                }
            } label: {
                TextField("...", text: $text, axis: .vertical)
                    .focused($focus, equals: .item(id: item.id))
                    .background(item.backgroundColor)
                    .onChange(of: text) {
                        guard focus != nil else { return }
                        guard text.contains("\n") else { return }
                        text = text.replacing("\n", with: "")

                        if text.isEmpty {
                            focus = .item(id: item.id)
                            return
                        }

                        let child = item.addNewChild()
                        focus = .item(id: child.id)
                    }.submitScope()
                    .onAppear {
                        focus = .item(id: item.id)
                    }
            }.disclosureGroupStyle(ItemDetailsStack(hideExpandButton: true))
        }
        .safeAreaPadding(.vertical, 20)
        .defaultScrollAnchor(.top)
        .onAppear {
            nav.selectedDate = item.timestamp
        }
        .onChange(of: nav.selectedDate) {
            item.setTimestamp(nav.selectedDate)
        }
        .onDisappear {
            item.commit(
                modelContext,
                text: text,
                taskData: taskData,
                eventData:
                eventData,
                tags: tags,
                children: children
            )
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .sheet(item: $sheet) { sheetEnum in
            switch sheetEnum {
            case .tags:
                VStack {
                    TagSelector(selectedItemTags: $tags)
                }
            case .event:
                VStack {
                    DatePicker("", selection: $item.timestamp, displayedComponents: [.date]).datePickerStyle(.graphical)
                        .onChange(of: item.timestamp) {
                            sheet = nil
                        }

                    HStack {
                        TimelineView(.everyMinute) { time in
                            AniButton {
                                toggleEventData(time: time.date)
                            } label: {
                                Image(systemName: "clock")
                                    .background(item.isEvent ? .white : .black)
                                    .foregroundStyle(item.isEvent ? .black : .white)
                                    .clipShape(Circle())
                            }
                        }
                        Spacer()

                        if item.isEvent {
                            EventDataRow(item: $item, eventData: $item.eventData)
                        }
                    }.padding()
                }
                .presentationBackground(.black)
                .presentationDetents([.fraction(0.5)])
            }
        }
        .toolbarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(text.isEmpty)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                HStack {
                    AniButton {
                        focus = nil
                    } label: {
                        Image(systemName: "keyboard")
                    }

                    Divider()

                    Spacer()
                }
            }
        }.hideSystemBackground()
    }

    fileprivate func toggleEventData(time: Date) {
        if let event = item.eventData {
            if let id = event.eventIdentifier, let ekEvent =
                calendarService.eventStore.event(withIdentifier: id)
            {
                calendarService.deleteEventInCalendar(event: ekEvent)
            }
            item.eventData = nil
        } else {
            item.eventData = .init(
                startDate: Calendar.current.combineDateAndTime(date: item.timestamp, time: time),
                endDate: Calendar.current.combineDateAndTime(date: item.timestamp, time: time.advanced(by: 3600))
            )
        }
    }

    struct Children: View {
        @Environment(\.modelContext) private var modelContext: ModelContext
        @Binding var children: [Item]
        @State var child: Item
        @FocusState var focus: Bool
        @State var text: String

        init(children: Binding<[Item]>, child: Item) {
            _children = children
            self.child = child
            text = child.text
        }

        var body: some View {
            HStack {
                if child.isTask {
                    AniButton {
                        child.toggleTaskData()
                    } label: {
                        Image(systemName: child.isTaskCompleted ? "circle.dotted" : "circle.fill")
                    }
                }

                TextField("", text: $text, axis: .vertical)
                    .onAppear {
                        if text.isEmpty {
                            focus = true
                        }
                    }.onChange(of: focus) {
                        if !focus {
                            child.text = text
                            if text.isEmpty {
                                children.removeAll { $0.id == child.id }
                            }
                        }
                    }
                    .focused($focus)
                    .onChange(of: text) {
                        guard focus else { return }
                        guard text.contains("\n") else { return }
                        text = text.replacing("\n", with: "")

                        if text.isNotEmpty {
                            child.text = text
                            let newItem = Item.create(position: child.position + 1)
                            newItem.taskData = child.taskData
                            children.insert(newItem, at: newItem.position)
                        } else {
                            children.removeAll { $0.id == child.id }
                        }
                    }
            }
            .toolbar {
                if focus {
                    ToolbarItemGroup(placement: .keyboard) {
                        HStack {
                            Divider()
                            AniButton {
                                print("add_audio")
                            } label: {
                                Image(systemName: "link")
                            }.disabled(text.isEmpty)

                            Divider()

                            AniButton {
                                child.toggleTaskData()
                            } label: {
                                Image(systemName: child.isTask ? "circle.fill" : "circle.dotted")
                            }.disabled(text.isEmpty)
                        }
                    }
                }
            }
        }
    }
}

struct ItemDetailsStack: DisclosureGroupStyle {
    @Environment(\.modelContext) private var modelContext: ModelContext
    var isAnimated: Bool = false
    let hideExpandButton: Bool
    @State var opacity: CGFloat = 1
    @State var blur: CGFloat = 0

    func makeBody(configuration: Configuration) -> some View {
        label(configuration)
            .listRowStyler(10)
            .onTapGesture {
                if !hideExpandButton {
                    withAnimation {
                        configuration.isExpanded.toggle()
                    }
                }
            }

        if configuration.isExpanded {
            configuration.content
                .listRowStyler()
                .padding(.leading, 24)
        }
    }

    @ViewBuilder
    func label(_ configuration: Configuration) -> some View {
        if isAnimated {
            animatedLabel(configuration)
        } else {
            staticLabel(configuration)
        }
    }

    @ViewBuilder
    func staticLabel(_ configuration: Configuration) -> some View {
        HStack(alignment: .center) {
            if !hideExpandButton {
                Rectangle()
                    .fill(.white)
                    .frame(width: 2, height: 16)
                    .rotationEffect(.degrees(configuration.isExpanded ? 90 : 18))
                    .padding(0)
                    .opacity(configuration.isExpanded ? 1 : 0.3)
            } else {
                Rectangle()
                    .fill(.white)
                    .frame(width: 2, height: 2)
                    .padding(0)
                    .opacity(0.3)
            }

            configuration.label
                .padding(0)
            Spacer()
        }
    }

    @ViewBuilder
    func animatedLabel(_ configuration: Configuration) -> some View {
        GeometryReader { geo in
            staticLabel(configuration)
                .opacity(opacity)
                .blur(radius: blur)
                .onAppear {
                    updateAnimation(geo)
                }
                .onChange(of: geo.frame(in: .global).minY) {
                    updateAnimation(geo)
                }
        }
    }

    func updateAnimation(_ geo: GeometryProxy) {
        let globalY = geo.frame(in: .global).minY
        let threshold: CGFloat = 200
        let distance = max(globalY - threshold, 0)
        opacity = min(distance / 100, 1)
        blur = min(distance / 10, 0)
    }
}

struct EventDataRow: View {
    @Environment(\.modelContext) private var modelContext: ModelContext
    @Environment(CalendarService.self) private var calendarService: CalendarService
    @Binding var item: Item
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

                    item = EventHandler.handleItem(item, eventData)
                }
            }.onChange(of: [startDate, endDate]) {
                if var eventData {
                    eventData.startDate = startDate
                    eventData.endDate = endDate
                    self.eventData = eventData

                    item = EventHandler.handleItem(item, eventData)
                }
            }
            .swipeActions(edge: .trailing) {
                if startDate > Date() {
                    Button {
                        Task {
                            await toggleNotification()
                        }
                    } label: {
                        Image(systemName: notify ? "bell.slash.fill" : "bell")
                    }.tint(.black)
                }
            }

        if let notifyAt = eventData?.notifyAt, notifyAt > Date() {
            Image(systemName: "wave.3.right")
                .font(.custom("GohuFont11NFM", size: 14))
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

struct ImageDataButton: View {
    @State private var imageItem: PhotosPickerItem?
    @Binding var imageData: ImageData?

    var body: some View {
        if imageData?.data == nil {
            PhotosPicker(selection: $imageItem, matching: .images) {
                Image(systemName: "photo")
            }.onChange(of: imageItem) {
                saveImage()
            }
        } else {
            Button {
                deleteImage()
            } label: {
                Image(systemName: "photo.fill")
            }
        }
    }

    func deleteImage() {
        imageItem = nil
        imageData?.data = nil
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

struct AudioRecordingRow: View {
    @Environment(\.modelContext) private var modelContext: ModelContext
    @Binding var audioData: AudioData?

    @State private var audioRecorder: AVAudioRecorder?
    @State private var audioSession: AVAudioSession?
    @State var recordedURL: URL?
    @State private var audioFile: AVAudioFile?

    @State private var hasPermission: Bool = false
    @State var isRecording: Bool = false
    @State var recorderPrepared: Bool = false
    @State private var doneLoading: Bool = false

    @State var count: Int = 0
    @State var startDate: Date?
    @State private var currentTime: TimeInterval = 0
    @State private var transcript: String = ""

    var showPlay: Bool {
        if let url = audioData?.url {
            return FileManager.default.fileExists(atPath: url.path()) && !isRecording
        }
        return false
    }

    var body: some View {
        HStack {
            if showPlay {
                AudioPlayerRow(doneLoading: $doneLoading, audioData: $audioData)
                    .opacity(!doneLoading ? 0.5 : 1)
                    .onAppear {
                        if let url = audioData?.url {
                            doneLoading = FileManager.default.fileExists(atPath: url.path()) && !isRecording
                        }
                    }
                    .disabled(!doneLoading)
            } else {
                Button {
                    setupAudioRecorder()
                    toggleRecording()
                } label: {
                    Image(systemName: isRecording ? "stop.circle.fill" : "circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 25, height: 25)
                        .foregroundStyle(.red)
                        .tint(.red)
                }.buttonStyle(.plain)
                    .tint(.red)
                    .foregroundStyle(.red)
                Spacer()
            }
        }
        .onDisappear { try? audioSession?.setActive(false) }
        .multilineTextAlignment(.leading)
    }

    private func setupAudioRecorder() {
        deleteCorruptedRecording()
        if !hasPermission {
            Task {
                await requestRecordPermission()
            }
        }
    }

    func toggleRecording() {
        if isRecording {
            stopRecording()
            if let url = recordedURL {
                Task {
                    extractTextFromAudio(url) { result in
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
            try? audioSession?.setActive(false)
        } else {
            Task {
                let documentPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                let audioFilename = documentPath.appendingPathComponent(UUID().description + ".m4a")
                recordedURL = audioFilename
                let newAudio = AudioData(url: audioFilename)
                audioData = newAudio
                try? await setupRecorder(audioFilename: audioFilename)
                startDate = Date()
                withAnimation { startRecording() }
            }
        }
    }

    func deleteRecording() {
        guard let audioData else { return }
        if FileManager.default.fileExists(atPath: audioData.url.path()) {
            try? FileManager.default.removeItem(at: audioData.url)
        }

        withAnimation { self.audioData = nil }
    }

    func deleteCorruptedRecording() {
        if let audioData, !FileManager.default.fileExists(atPath: audioData.url.path()) {
            try? FileManager.default.removeItem(at: audioData.url)
            self.audioData = nil
        }
    }

    func requestRecordPermission() async {
        if await AVAudioApplication.requestRecordPermission() {
            hasPermission = true
        } else {
            hasPermission = false
        }
    }

    func setupAudioSession() async throws {
        if !hasPermission {
            await requestRecordPermission()
        }

        if audioSession == nil {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .spokenAudio)
            try? audioSession.overrideOutputAudioPort(AVAudioSession.PortOverride.speaker)
            try audioSession.setActive(true)
            self.audioSession = audioSession
        }
    }

    func setupRecorder(audioFilename: URL) async throws {
        try? await setupAudioSession()
        let recordingSettings: [String: Any] = [AVFormatIDKey: kAudioFormatMPEG4AAC, AVSampleRateKey: 12000, AVNumberOfChannelsKey: 1, AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue]
        recordedURL = audioFilename
        audioRecorder = try AVAudioRecorder(url: audioFilename, settings: recordingSettings)
        audioRecorder?.prepareToRecord()
    }

    func startRecording() {
        audioRecorder?.record()
        withAnimation { isRecording = true }
    }

    func stopRecording() {
        audioRecorder?.stop()

        if isRecording {
            withAnimation { isRecording = false }
        }

        try? audioSession?.setActive(false)
    }

    func extractTextFromAudio(_ audioURL: URL, completionHandler: @escaping (Result<String, Error>) -> Void) {
        let modelURL = Bundle.main.url(forResource: "tiny", withExtension: "bin")!
        let whisper = Whisper(fromFileURL: modelURL)
        convertAudioFileToPCMArray(fileURL: audioURL) { result in
            switch result {
            case let .success(success):
                Task {
                    do {
                        let segments = try await whisper.transcribe(audioFrames: success)
                        completionHandler(.success(segments.map(\.text).joined()))
                    } catch {
                        completionHandler(.failure(error))
                    }
                }
            case let .failure(failure):
                completionHandler(.failure(failure))
            }
        }
    }

    func convertAudioFileToPCMArray(fileURL: URL, completionHandler: @escaping (Result<[Float], Error>) -> Void) {
        var options = FormatConverter.Options()
        options.format = .wav
        options.sampleRate = 16000
        options.bitDepth = 16
        options.channels = 1
        options.isInterleaved = false

        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        let converter = FormatConverter(inputURL: fileURL, outputURL: tempURL, options: options)
        converter.start { error in
            if let error {
                completionHandler(.failure(error))
                return
            }

            let data = try! Data(contentsOf: tempURL)

            let floats = stride(from: 44, to: data.count, by: 2).map {
                data[$0 ..< $0 + 2].withUnsafeBytes {
                    let short = Int16(littleEndian: $0.load(as: Int16.self))
                    return max(-1.0, min(Float(short) / 32767.0, 1.0))
                }
            }

            try? FileManager.default.removeItem(at: tempURL)

            completionHandler(.success(floats))
        }
    }
}

struct AudioPlayerRow: View {
    @Binding var doneLoading: Bool
    @Binding var audioData: AudioData?
    @State private var player: AVPlayer?
    @State private var isPlaying = false
    @State private var audioSession: AVAudioSession?
    @State private var transcript: String = ""
    @FocusState private var transcriptFocus: Bool

    var body: some View {
        if let data = audioData {
            HStack {
                Button(action: togglePlayback) {
                    Image(systemName: isPlaying ? "stop.circle.fill" : "play.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                        .padding(.horizontal, 5)
                }.buttonStyle(.plain)

                if !data.transcript.isEmpty {
                    TextField("[transcript]", text: $transcript, axis: .vertical)
                        .focused($transcriptFocus)
                        .fixedSize(horizontal: false, vertical: true)
                        .onChange(of: transcriptFocus) {
                            if !transcriptFocus {
                                if transcript.isNotEmpty {
                                    audioData?.transcript = transcript
                                }
                            }
                        }
                        .onAppear {
                            transcript = data.transcript
                        }.onSubmit {
                            if transcript.isNotEmpty {
                                audioData?.transcript = transcript
                            }
                        }.submitScope()
                } else {
                    HStack {
                        ProgressView("Transcribing...")
                            .padding(.vertical)
                    }
                    .onChange(of: audioData?.transcript) {
                        guard let d = audioData else { return }
                        if d.transcript.isNotEmpty &&
                            d.transcript != transcript
                        {
                            transcript = d.transcript
                        }
                    }
                    .labelsHidden()
                    .progressViewStyle(.linear)
                }
            }
        }
    }

    func deleteRecording() {
        guard let audioData else { return }
        if FileManager.default.fileExists(atPath: audioData.url.path()) {
            try? FileManager.default.removeItem(at: audioData.url)
        }

        self.audioData = nil
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
        setupAudioPlayer()
        guard let player = player else { return }
        if isPlaying {
            player.seek(to: .zero)
            player.pause()
        } else {
            player.play()
        }
        withAnimation {
            isPlaying.toggle()
        }
    }
}
