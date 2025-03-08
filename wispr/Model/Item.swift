import AppIntents
import AudioKit
import AVFoundation
import EventKit
import Foundation
import PhotosUI
import SFSymbolsPicker
import SwiftData
import SwiftUI
import SwiftWhisper
import UniformTypeIdentifiers
import UserNotifications
import WidgetKit
@_spi(Advanced) import SwiftUIIntrospect

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

    var title: String = "UNTITLED: " + Date().formatted(.dateTime.hour().minute())
    var noteData: NoteData = NoteData(text: "")
    var taskData: TaskData?
    var eventData: EventData?
    @Attribute(.externalStorage)
    var imageData: ImageData?
    var audioData: AudioData?

    var hasNote: Bool {
        !noteData.text.isEmpty
    }

    var isTask: Bool {
        taskData != nil
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

    @ViewBuilder
    var colorMesh: some View {
        let colors = tags.map { $0.color }

        MeshGradient(width: 2, height: 2, points: [
            [0, 0], [1, 0],
            [0, 1], [1, 1],
        ], colors: colors)
            .blur(radius: 15 + 10)
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

struct NoteData: Identifiable, Codable, Hashable {
    var id: UUID = .init()
    var text: String
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

struct TestContentView: View {
    @Environment(\.modelContext) private var modelContext: ModelContext
    @Query() var items: [Item]
    @State private var selected: Set<Item> = []

    var body: some View {
        NavigationStack {
            List(items, id: \.self) { item in
                NavigationLink {
                    TestForm(item: item)
                } label: {
                    Text(item.noteData.text)
                }
            }
        }
    }
}

struct TestChildRow: View {
    @Binding var children: [Item]
    @State var child: Item
    @State var noteData: NoteData = .init(text: "")
    @FocusState var focus: Bool

    var body: some View {
        HStack {
            if var taskData = child.taskData {
                AniButton {
                    taskData.completedAt = taskData.completedAt == nil ? Date() : nil
                    child.taskData = taskData
                } label: {
                    Image(systemName: taskData.completedAt == nil ? "circle.dotted" : "circle.fill")
                }
            }

            TextField("", text: $noteData.text, axis: .vertical)
                .onAppear {
                    noteData = child.noteData
                    if noteData.text.isEmpty {
                        focus = true
                    }
                }.onChange(of: focus) {
                    if !focus {
                        child.noteData = noteData
                        if noteData.text.isEmpty {
                            children.removeAll { $0.id == child.id }
                        }
                    }
                }
                .focused($focus)
                .onChange(of: noteData.text) {
                    guard focus else { return }
                    guard noteData.text.contains("\n") else { return }
                    noteData.text = noteData.text.replacing("\n", with: "")

                    if noteData.text.isNotEmpty {
                        child.noteData = noteData
                        let newItem = Item(position: child.position + 1)
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
                        AniButton {
                            focus = false
                        } label: {
                            Image(systemName: "keyboard")
                        }

                        Divider()

                        Spacer()

                        Divider()
                        AniButton {
                            print("add_audio")
                        } label: {
                            Image(systemName: "link")
                        }.disabled(noteData.text.isEmpty)

                        Divider()

                        AniButton {
                            child.taskData = child.taskData == nil ? TaskData() : nil
                        } label: {
                            Image(systemName: child.isTask ? "circle.fill" : "circle.dotted")
                        }.disabled(noteData.text.isEmpty)
                    }
                }
            }
        }.toolbarBackgroundVisibility(.hidden, for: .automatic)
    }
}

struct TestForm: View {
    @Environment(\.modelContext) private var modelContext: ModelContext
    @Environment(CalendarService.self) private var calendarService: CalendarService
    @FocusState var focus: FocusedField?

    @State var item: Item

    @State private var title: String = ""
    @State private var noteData: NoteData = .init(text: "")
    @State private var children: [Item] = []
    @State private var showTags: Bool = false
    @State private var tags: [Tag] = []

    var body: some View {
        if showTags {
            HStack {
                TagSelector(selectedItemTags: $tags)
            }
        }

        if item.isEvent {
            HStack {
                EventDataRow(item: $item, eventData: $item.eventData)
            }
        }

        List {
            ForEach(children, id: \.self) { child in
                TestChildRow(children: $children, child: child)
                    .focused($focus, equals: .item(id: child.id))
            }.onAppear {
                children.sort { $0.position < $1.position }
            }
        }
        .onAppear {
            title = item.title
            noteData = item.noteData
            children = item.children
        }
        .onDisappear {
            item.title = title
            item.noteData = noteData
            item.children = children
        }
        .navigationBarBackButtonHidden()
        .toolbarRole(.navigationStack)
        .toolbar {
            ToolbarItemGroup(placement: .topBarLeading) {
                AniButton {
                    print("")
                } label: {
                    Image(systemName: "chevron.left")
                }

                TextField("title...", text: $title)
                    .focused($focus, equals: .item(id: item.id))
                    .frame(minWidth: 40)
                    .onSubmit {
                        let newItem = Item(position: item.children.count)
                        children.append(newItem)
                        focus = .item(id: newItem.id)
                    }.submitScope()

                TimelineView(.everyMinute) { time in
                    AniButton {
                        toggleEventData(time: time.date)
                    } label: {
                        Image(systemName: item.eventData != nil ? "clock.fill" : "clock")
                    }
                }

                AniButton {
                    showTags.toggle()
                } label: {
                    Image(systemName: showTags ? "tag.fill" : "tag")
                }
            }

            ToolbarItemGroup(placement: .topBarTrailing) {
                AniButton {
                    item.archivedAt = Date()
                    item.archived = true
                } label: {
                    Image(systemName: "archivebox")
                }

                AniButton {
                    modelContext.delete(item)
                } label: {
                    Image(systemName: "trash")
                }
            }

            if focus == .item(id: item.id) {
                ToolbarItem(placement: .keyboard) {
                    AniButton {
                        focus = nil
                    } label: {
                        Image(systemName: "keyboard")
                    }
                }
            }
        }
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
}

struct ItemList: View {
    @Environment(\.modelContext) private var modelContext: ModelContext
    @Environment(DayDetailsConductor.self) private var conductor: DayDetailsConductor
    @Environment(\.scenePhase) var scenePhase
    @Environment(CalendarService.self) private var calendarService: CalendarService

    let namespace: Namespace.ID

    @Query var items: [Item]
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
    @FocusState var focus: FocusedField?
    @FocusState var focusList: Bool

    init(namespace: Namespace.ID, date: Date) {
        let start = Calendar.current.startOfDay(for: date)
        let end = Calendar.current.startOfDay(for: date.advanced(by: 86400))
        _items = Query(filter: #Predicate<Item> { start <= $0.timestamp &&
                $0.timestamp < end && $0.parent == nil && $0.archived == false
        }, sort: \Item.position)
        self.namespace = namespace
    }

    var body: some View {
        ZStack {
            list
            if flashError {
                errorFlash
            }
        }
    }

    var allDayEvents: [Item] {
        return items.filter {
            if let event = $0.eventData {
                return event.startDate == start && event.endDate ==
                    end.advanced(by: -1)
            }
            return false
        }
    }

    var filteredItems: [Item] {
        items.filter {
            if let editItem = conductor.editItem {
                return $0.id == editItem.id
            }

            return !allDayEvents.contains($0)
        }.sorted { $0.position < $1.position }
    }

    @ViewBuilder
    var list: some View {
        List {
            if allDayEvents.isNotEmpty {
                DisclosureGroup {
                    ForEach(allDayEvents) { allDayEvent in
                        HStack {
                            Text(allDayEvent.noteData.text)
                            Spacer()
                        }
                    }
                } label: {
                    HStack {
                        Text("all_day")
                        Spacer()
                    }
                }
                .tint(.white)
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            }

            ForEach(filteredItems) { item in
                DisclosureGroup {
                    ForEach(item.children) { child in
                        Text(child.noteData.text)
                    }
                } label: {
                    NavigationLink {
                        TestForm(item: item)
                            .navigationTransition(.zoom(sourceID: item.id, in: namespace))
                    } label: {
                        Text(item.title)
                            .matchedTransitionSource(id: item.id, in: namespace)
                    }
                }.disclosureGroupStyle(ItemDetailsStack(hideExpandButton: item.children.isEmpty))
            }
        }
        .opacity(flashError ? 0.1 : 1)
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
            let count = filteredItems.count
            if index > filteredItems.count { return }
            let movedItem = filteredItems[index]
            self.movedItem = movedItem

            if let movedEventData = movedItem.eventData {
                for i in 0 ..< newIndex {
                    let item = filteredItems[i]
                    if let itemEventData = item.eventData {
                        if movedEventData.startDate < itemEventData.startDate {
                            triggerFlashError()
                            return
                        }
                    }
                }

                for i in newIndex ..< count {
                    let item = filteredItems[i]
                    if let itemEventData = item.eventData {
                        if movedEventData.startDate > itemEventData.startDate {
                            triggerFlashError()
                            return
                        }
                    }
                }
            }
        }

        var itms = filteredItems
        itms.move(fromOffsets: indexSet, toOffset: newIndex)

        for (index, item) in itms.enumerated() {
            item.position = index
        }

        try! modelContext.save()
    }

    func dynamicallyReorderList(item: Item) {
        if allDayEvents.contains(item) {
            return
        }
        guard let itemEventData = item.eventData else {
            return
        }

        let oldIndex = items.firstIndex(of: item)!
        if let newIndex = items.firstIndex(where: {
            if let eventData = $0.eventData {
                return $0.id != item.id && eventData.startDate > itemEventData.startDate
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

struct ItemDetailsStack: DisclosureGroupStyle {
    @Environment(\.modelContext) private var modelContext: ModelContext
    let hideExpandButton: Bool

    func makeBody(configuration: Configuration) -> some View {
        HStack {
            VStack {
                configuration.label
            }

            if !hideExpandButton {
                AniButton {
                    configuration.isExpanded.toggle()
                } label: {
                    HStack {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(.white)
                            .opacity(configuration.isExpanded ? 1 : 0.5)
                            .contentShape(Rectangle())
                            .frame(width: 4, height: configuration.isExpanded ? 30 : 20)
                    }
                }.contentShape(Rectangle())
                    .buttonStyle(.plain)
            }
        }
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
        .listRowSpacing(4)

        if configuration.isExpanded {
            configuration.content
                .listRowBackground(Color.clear)
        }
    }
}

struct ItemDetailsForm: View {
    @Environment(\.modelContext) private var modelContext: ModelContext
    @Environment(\.scenePhase) var scenePhase
    @Environment(DayDetailsConductor.self) private var conductor: DayDetailsConductor
    @Environment(CalendarService.self) private var calendarService: CalendarService

    @Namespace var namespace
    @State var item: Item

    init(item: Item) {
        self.item = item
        noteData = item.noteData
    }

    @State var noteData: NoteData

    @State var showTags: Bool = false
    @State var showNewTag: Bool = false
    @State var showTagDelete: Bool = false
    @State var showAudio: Bool = false

    var isEditItem: Bool {
        item == conductor.editItem
    }

    @State var initialExpansion: Bool = false
    @State var isExpanded: Bool = false
    @FocusState var focusState: FocusedField?

    var hideExpandButton: Bool {
        isEditItem || item.children.isEmpty
    }

    var body: some View {
        DisclosureGroup(isExpanded: $item.isExpanded) {
            if item.children.isNotEmpty {
                ForEach(item.children) { child in
                    ChildRow(item: child, focusState: $focusState)
                        .listRowBackground(Color.clear)
                        .swipeActions(edge: .trailing) { deleteButton(child).tint(.black) }
                }.onMove(perform: onChildMove)
                    .listSectionSpacing(4)
                    .padding(.leading, 40)
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .listRowSpacing(0)
            }
        } label: {
            if isEditItem {
                TagSelector(selectedItemTags: $item.tags, minimized: true)
                    .listRowSeparator(.hidden)
                    .listRowSpacing(0)
                    .listSectionSpacing(0)
                    .padding(6)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .listRowBackground(Color.clear)
            }
            Section {
                ParentRow(item: $item, focusState: $focusState)
                    .listRowBackground(Color.clear)
                    .toolbar {
                        if isEditItem {
                            ToolbarItemGroup(placement: .bottomBar) {
                                HStack {
                                    AniButton {
                                        onExit()
                                    } label: {
                                        Image(systemName: "chevron.left")
                                    }

                                    Spacer()

                                    archiveButton
                                    deleteButton()
                                }.tint(.white)
                            }
                        }
                    }
            }
            .swipeActions(edge: .leading) { archiveButton.tint(.black) }
            .swipeActions(edge: .trailing) { deleteButton().tint(.black) }
        }.disclosureGroupStyle(
            ItemDetailsStack(
                hideExpandButton: hideExpandButton
            )
        )
    }

    @ViewBuilder
    var archiveButton: some View {
        AniButton {
            item.archived = true
            item.archivedAt = Date()
            if conductor.editItem == item {
                conductor.editItem = nil
            }
        } label: {
            Image(systemName: "archivebox.fill")
        }
    }

    @ViewBuilder
    func deleteButton(_ item: Item? = nil) -> some View {
        AniButton {
            if let item {
                delete(item)
            } else {
                deleteParent()
            }
        } label: {
            Image(systemName: "trash.fill")
        }
    }

    func onExit() {
        conductor.editItem = nil
        if item.noteData.text.isEmpty {
            deleteParent()
        }
    }

    func delete(_ item: Item) {
        item.parent?.children.removeAll { $0.id == item.id }
        modelContext.delete(item)
    }

    func deleteParent() {
        if let event = item.eventData {
            let eh = EventHandler(item, event)
            _ = eh.processEventData()
        }

        delete(item)
        if conductor.editItem == item {
            conductor.editItem = nil
        }
    }

    struct ParentRow: View {
        @Environment(\.modelContext) private var modelContext: ModelContext
        @Environment(\.scenePhase) var scenePhase
        @Environment(DayDetailsConductor.self) private var conductor: DayDetailsConductor
        @Environment(FocusConductor.self) private var focusConductor: FocusConductor
        @Environment(CalendarService.self) private var calendarService: CalendarService
        @Binding var item: Item
        @State var noteData: NoteData = .init(text: "")
        var focusState: FocusState<FocusedField?>.Binding
        @FocusState var textField: Bool

        var isFocused: Bool {
            focusState.wrappedValue == .item(id: item.id)
        }

        var body: some View {
            @Bindable var focusConductor = focusConductor
            HStack {
                if var taskData = item.taskData {
                    AniButton {
                        taskData.completedAt = taskData.completedAt == nil ? Date() : nil
                        item.taskData = taskData
                    } label: {
                        Image(systemName: taskData.completedAt == nil ? "circle.dotted" : "circle.fill")
                    }.buttonStyle(.plain)
                }

                if conductor.editItem == item {
                    TextField("...", text: $noteData.text, axis: .vertical)
                        .focused(focusState, equals: .item(id: item.id))
                        .onChange(of: noteData.text) {
                            guard focusState.wrappedValue == .item(id: item.id) else { return }
                            guard noteData.text.contains("\n") else { return }
                            noteData.text = noteData.text.replacing("\n", with: "")
                            submit(true)
                        }
                        .toolbar {
                            if isFocused {
                                ToolbarItemGroup(placement: .keyboard) {
                                    if item.isParent {
                                        parentToolbar
                                    }
                                }
                            }
                        }
                        .onAppear { noteData = item.noteData }
                } else {
                    AniButton {
                        conductor.editItem = item
                        item.isExpanded = true
                        focusState.wrappedValue = .item(id: item.id)
                    } label: {
                        HStack {
                            Text(item.noteData.text)
                                .lineLimit(1)
                            Spacer()
                        }
                    }.buttonStyle(.plain)
                }

                if item.isEvent {
                    EventDataRow(item: $item, eventData: $item.eventData)
                }
            }
            .padding()
            .background(item.colorMesh)
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }

        @ViewBuilder
        var parentToolbar: some View {
            HStack {
                AniButton {
                    submit()
                } label: {
                    Image(systemName: "keyboard.chevron.compact.down")
                }.padding(.horizontal, 4)

                Spacer()
                HStack {
                    AniButton {
                        item.taskData = item.taskData == nil ? TaskData() : nil
                        for child in item.children {
                            child.taskData = item.taskData
                        }
                    } label: {
                        Image(systemName: item.taskData == nil ?
                            "circle.dotted" : "circle.fill")
                    }

                    TimelineView(.everyMinute) { time in
                        AniButton {
                            toggleEventData(time: time.date)
                        } label: {
                            Image(systemName: item.eventData != nil ? "clock.fill" : "clock")
                        }
                    }
                }.disabled(noteData.text.isEmpty)
                    .tint(noteData.text.isEmpty ? .gray : .white)
            }
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

        func submit(_ addChild: Bool = false) {
            if noteData.text.isEmpty {
                deleteParent()
                return
            }

            withAnimation {
                item.noteData = noteData

                if !addChild {
                    focusState.wrappedValue = nil
                    return
                }

                let newItem = Item()
                newItem.taskData = item.taskData
                newItem.position = item.children.count + 1
                focusState.wrappedValue = .item(id: newItem.id)
                item.children.append(newItem)
            }
        }

        func delete(_ item: Item) {
            item.parent?.children.removeAll { $0.id == item.id }
            modelContext.delete(item)
        }

        func deleteParent() {
            if let event = item.eventData {
                let eh = EventHandler(item, event)
                _ = eh.processEventData()
            }

            delete(item)
            if conductor.editItem == item {
                conductor.editItem = nil
            }
        }
    }

    struct ChildRow: View {
        @Environment(\.modelContext) private var modelContext: ModelContext
        @Environment(\.scenePhase) var scenePhase
        @Environment(DayDetailsConductor.self) private var conductor: DayDetailsConductor
        @Environment(CalendarService.self) private var calendarService: CalendarService

        @State var item: Item
        @State var noteData: NoteData = .init(text: "")
        var focusState: FocusState<FocusedField?>.Binding
        @FocusState var textField: Bool
        @State var focused: Bool = false

        var isFocused: Bool {
            focusState.wrappedValue == .item(id: item.id)
        }

        var body: some View {
            HStack {
                if var taskData = item.taskData {
                    AniButton {
                        taskData.completedAt = taskData.completedAt == nil ? Date() : nil
                        item.taskData = taskData
                    } label: {
                        Image(systemName: taskData.completedAt == nil ? "circle.dotted" : "circle.fill")
                    }.buttonStyle(.plain)
                }

                if conductor.editItem == item.parent {
                    TextField("", text: $noteData.text, axis: .vertical)
                        .onChange(of: noteData.text) {
                            guard focusState.wrappedValue == .item(id: item.id) else {
                                if noteData.text.isEmpty {
                                    modelContext.delete(item)
                                }
                                return
                            }
                            guard noteData.text.isNotEmpty else { return }
                            guard noteData.text.contains("\n") else { return }
                            noteData.text = noteData.text.replacing("\n", with: "")
                            withAnimation {
                                submit(true)
                            }
                        }
                        .onAppear {
                            noteData = item.noteData
                        }
                        .focused(focusState, equals: .item(id: item.id))
                } else {
                    Text(item.noteData.text)
                }
            }
            .toolbar {
                if isFocused {
                    ToolbarItemGroup(placement: .keyboard) {
                        childToolbar
                    }
                }
            }
        }

        @ViewBuilder
        var childToolbar: some View {
            HStack {
                AniButton {
                    submit(false)
                } label: {
                    Image(systemName: "keyboard.chevron.compact.down")
                }.padding(.horizontal, 4)

                Spacer()
                HStack {
                    AniButton {
                        item.taskData = item.taskData == nil ? TaskData() : nil
                        for child in item.children {
                            child.taskData = item.taskData
                        }
                    } label: {
                        Image(systemName: item.taskData == nil ?
                            "circle.dotted" : "circle.fill")
                    }
                }.disabled(noteData.text.isEmpty)
                    .tint(noteData.text.isEmpty ? .gray : .white)
            }
        }

        func submit(_ addChild: Bool = false) {
            if noteData.text.isEmpty {
                deleteChild(item)
                return
            }

            item.noteData = noteData

            if !addChild {
                focusState.wrappedValue = nil
                return
            }
            guard let parent = item.parent else { return }

            let newItem = Item()
            newItem.taskData = item.taskData
            focusState.wrappedValue = .item(id: newItem.id)
            let index = parent.children.firstIndex(of: item)
            newItem.position = (index ?? parent.children.count) + 1
            parent.children.insert(newItem, at: newItem.position)
        }

        func deleteChild(_ item: Item) {
            item.parent?.children.removeAll { $0.id == item.id }
            modelContext.delete(item)
        }
    }

    func onChildMove(_ indexSet: IndexSet, _ newIndex: Int) {
        if item.children.isEmpty { return }
        item.children.move(fromOffsets: indexSet, toOffset: newIndex)

        for (index, item) in item.children.enumerated() {
            item.position = index
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

                    let eventHandler = EventHandler(item, eventData)
                    let e = eventHandler.processEventData()
                    item.eventData = e
                }
            }.onChange(of: [startDate, endDate]) {
                if var eventData {
                    eventData.startDate = startDate
                    eventData.endDate = endDate
                    self.eventData = eventData

                    let eventHandler = EventHandler(item, eventData)
                    let e = eventHandler.processEventData()
                    item.eventData = e
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

struct ImageDataListRow: View {
    var imageData: ImageData
    var namespace: Namespace.ID

    var body: some View {
        if let image = imageData.image {
            image.resizable().scaledToFill()
                .overlay {
                    LinearGradient(gradient: Gradient(colors: [.clear, .black]),
                                   startPoint: .bottomLeading, endPoint: .topTrailing)
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

struct CustomTextField: UIViewRepresentable {
    @Binding var item: Item
    @Binding var text: String
    @Binding var isFirstResponder: Bool

    var placeholder: String = ""
    var keyboardType: UIKeyboardType = .default
    var textContentType: UITextContentType?
    var autocorrectionType: UITextAutocorrectionType = .default

    var onBeginEditing: (() -> Void)?
    var onEndEditing: (() -> Void)?
    var onTextChange: ((String) -> Void)?
    var onSubmit: (() -> Void)?

    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        textField.delegate = context.coordinator
        textField.placeholder = placeholder
        textField.keyboardType = keyboardType
        textField.textContentType = textContentType
        textField.autocorrectionType = autocorrectionType
        textField.addTarget(context.coordinator, action: #selector(Coordinator.textFieldDidChange(_:)), for: .editingChanged)
        return textField
    }

    func updateUIView(_ uiView: UITextField, context _: Context) {
        uiView.text = text

        if isFirstResponder && !uiView.isFirstResponder {
            uiView.becomeFirstResponder()
        } else if !isFirstResponder && uiView.isFirstResponder {
            uiView.resignFirstResponder()
        }

        if uiView.text?.last == "\n" {
            item.children.append(Item(position: item.children.count))
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UITextFieldDelegate {
        var parent: CustomTextField

        init(_ parent: CustomTextField) {
            self.parent = parent
        }

        @objc func textFieldDidChange(_ textField: UITextField) {
            parent.text = textField.text ?? ""
            parent.onTextChange?(parent.text)
        }

        func textFieldDidBeginEditing(_: UITextField) {
            parent.isFirstResponder = true
            parent.onBeginEditing?()
        }

        func textFieldDidEndEditing(_: UITextField) {
            parent.isFirstResponder = false
            parent.onEndEditing?()
        }

        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            parent.onSubmit?()
            textField.resignFirstResponder()
            return true
        }
    }
}

struct ItemTextEditorIntrospect: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var parentItem: Item

    @State private var fullText: String = ""

    var body: some View {
        TextEditor(text: $fullText)
            .padding()
            .introspect(.textEditor, on: .iOS(.v14...)) { textView in
                textView.delegate = makeCoordinator()
            }
            .onAppear {
                assembleText()
            }
    }

    private func assembleText() {
        fullText = ([parentItem.noteData.text] + parentItem.children.map { $0.noteData.text })
            .joined(separator: "\n")
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parentItem: parentItem, modelContext: modelContext)
    }

    class Coordinator: NSObject, UITextViewDelegate {
        var parentItem: Item
        var modelContext: ModelContext

        init(parentItem: Item, modelContext: ModelContext) {
            self.parentItem = parentItem
            self.modelContext = modelContext
        }

        func textViewDidChange(_ textView: UITextView) {
            let lines = textView.text
                .split(separator: "\n", omittingEmptySubsequences: false)
                .map(String.init)

            parentItem.noteData.text = lines.first ?? ""

            for child in parentItem.children {
                modelContext.delete(child)
            }

            for line in lines.dropFirst() {
                let child = Item(noteData: NoteData(text: line))
                child.parent = parentItem
                modelContext.insert(child)
            }
        }
    }
}
