//
//  Day.swift
//  wispr
//
//  Created by Faisal Alalaiwat on 02.02.25.
//

import AudioKit
import EventKit
import PhotosUI
import SwiftData
import SwiftUI
import SwiftWhisper
import WidgetKit

struct Day: Identifiable, Hashable {
    var id: UUID = .init()
    var date: Date
    var offset: Int
    var items: [Item] = []

    init(offset: Int, date: Date = Date()) {
        self.offset = offset
        let cal = Calendar.current
        self.date = cal.startOfDay(for: date)
    }

    var itemPredicate: Predicate<Item> {
        let start = date
        let end = date.advanced(by: 86400)
        return #Predicate<Item> { start <= $0.timestamp && end > $0.timestamp }
    }
}

struct DayHeader: View {
    let date: Date
    let isEmpty: Bool

    var activeDate: Date {
        return Calendar.current.startOfDay(for: date)
    }

    var todayDate: Date {
        return Calendar.current.startOfDay(for: Date())
    }

    var body: some View {
        HStack {
            Text(DateTimeString.leftDateString(date: date))
                .fixedSize()
                .frame(alignment: .leading)
            RoundedRectangle(cornerRadius: 2).frame(height: 1)
            if activeDate == todayDate {
                Text("\(todayDate.formatted(.dateTime.weekday())) - Today")
            } else {
                Text(DateTimeString.navbarDateString(date: date))
                    .fixedSize()
            }
        }
    }
}

enum NavDestination: Hashable {
    case day, timeline, itemDetails(item: Item)
}

struct TimeLineHeader: View {
    @Environment(\.modelContext) private var modelContext: ModelContext
    @Environment(\.scenePhase) var scenePhase
    @Environment(\.editMode) private var editMode
    @Environment(DayDetailsConductor.self) private var conductor: DayDetailsConductor
    @Environment(CalendarService.self) private var calendarService: CalendarService

    var activeDate: Date {
        return Calendar.current.startOfDay(for: conductor.date)
    }

    var todayDate: Date {
        return Calendar.current.startOfDay(for: Date())
    }

    var body: some View {
        HStack {
            Image("Logo")
                .resizable()
                .scaledToFit()
                .frame(width: 15, height: 15)

            RoundedRectangle(cornerRadius: 2).fill(.white).frame(height: 1)
                .padding(.horizontal, 10)

            Button {
                conductor.date = todayDate
            } label: {
                Image(systemName: "circle.dotted.circle")
            }

            if activeDate == todayDate {
                Text("\(todayDate.formatted(.dateTime.weekday())) - Today")
            } else {
                Text(DateTimeString.navbarDateString(date: conductor.date))
                    .fixedSize()
            }
        }.padding(.horizontal, 25)
            .padding(.vertical, 5)
            .tint(.white)
    }
}

struct DayScreen: View {
    @Environment(\.modelContext) private var modelContext: ModelContext
    @Environment(\.scenePhase) var scenePhase
    @Environment(\.editMode) private var editMode
    @Environment(DayDetailsConductor.self) private var conductor: DayDetailsConductor
    @Environment(CalendarService.self) private var calendarService: CalendarService

    @Namespace var namespace

    @State var isEditing: Bool = false
    @State var path: [NavDestination] = []
    @State var count: Int = 0

    @FocusState var focused: Bool

    var start: Date {
        Calendar.current.startOfDay(for: conductor.date)
    }

    var end: Date {
        start.advanced(by: 86400)
    }

    var activeDate: Date {
        return Calendar.current.startOfDay(for: conductor.date)
    }

    var todayDate: Date {
        return Calendar.current.startOfDay(for: Date())
    }

    var body: some View {
        NavigationStack(path: $path) {
            VStack {
                HStack {
                    Image("Logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 15, height: 15)

                    Spacer()

                    if !conductor.isEditingItem {
                        Button(action: { stepTo(date: Date()) }) {
                            Image(systemName: activeDate == todayDate ?
                                "circle.fill" : "circle.dotted.circle")
                        }.scaleEffect(activeDate == todayDate ? 0.5 : 1)
                            .tint(.white)
                    }
                    if activeDate == todayDate {
                        Text("\(todayDate.formatted(.dateTime.weekday())) - Today")
                    } else {
                        Text(DateTimeString.navbarDateString(date: conductor.date))
                            .fixedSize()
                    }

                    if !conductor.isEditingItem {
                        NavigationLink(value: NavDestination.timeline) {
                            Image(systemName: "calendar.day.timeline.left")
                        }.onChange(of: conductor.date) {
                            path.removeAll()
                        }
                    }
                }.padding(.horizontal, 25)
                    .padding(.vertical, 5)
                    .tint(.white)

                if conductor.showArchive {
                    @Bindable var conductor = conductor
                    VStack {
                        ArchiveItemSheet(date: activeDate, position: conductor.itemCount)
                    }.transition(.asymmetric(
                        insertion: .push(from: .bottom),
                        removal: .push(from: .top)
                    ))
                } else {
                    VStack {
                        ItemList(namespace: namespace, date: conductor.date)
                            .focused($focused)
                            .environment(\.editMode, .constant(self.isEditing ? EditMode.active : EditMode.inactive))
                    }.transition(.asymmetric(
                        insertion: .push(from: .top),
                        removal: .push(from: .bottom)
                    ))
                }

                if conductor.showDatePicker {
                    VStack {
                        @Bindable var conductor = conductor
                        HStack {
                            DatePicker("", selection: $conductor.date, displayedComponents: [.date])
                                .datePickerStyle(.graphical)
                                .labelsHidden()
                        }
                    }
                    .padding()
                    .tint(.white)
                }
            }
            .matchedTransitionSource(id: conductor.date, in: namespace)
            .navigationDestination(for: NavDestination.self) { destination in
                switch destination {
                case .timeline:
                    TimeLineTestView(path: $path)
                        .navigationBarBackButtonHidden()
                        .navigationTransition(
                            .zoom(sourceID: conductor.date, in: namespace)
                        )
                        .onAppear {
                            conductor.editItem = nil
                            focused = false
                        }.onDisappear {
                            focused = true
                        }
                case .day:
                    self
                case let .itemDetails(item):
                    ItemDetailsForm(item: item)
                        .navigationTransition(.zoom(sourceID: item.id, in: namespace))
                        .navigationBarBackButtonHidden()
                }
            }
            .toolbar {
                if conductor.editItem == nil {
                    ToolbarItemGroup(placement: .bottomBar) {
                        BottomToolbar(
                            path: $path
                        ).onAppear {
                            WidgetCenter.shared.reloadAllTimelines()
                        }
                        .font(.custom("GohuFont11NFM", size: 18))
                    }
                }
            }
            .toolbarBackground(.black, for: .bottomBar)
        }
        .onChange(of: scenePhase) {
            if [ScenePhase.background, ScenePhase.inactive].contains(scenePhase) {
                SharedState.commitEditItem(context: modelContext)
            }
        }
        .font(.custom("GohuFont11NFM", size: 18))
        .onAppear(perform: { calendarService.syncCalendar(modelContext: modelContext) })
    }

    func dateString(date: Date) -> String {
        return date.formatted(.dateTime.weekday(.wide).day().month().year())
    }

    fileprivate func stepTo(date: Date) {
        if conductor.date == Calendar.current.startOfDay(for: date) {
            return
        }

        withAnimation {
            conductor.date = Calendar.current.startOfDay(for: date)
        }
    }
}

struct BottomToolbar: View {
    @Environment(\.modelContext) private var modelContext: ModelContext
    @Environment(DayDetailsConductor.self) private var conductor: DayDetailsConductor

    @State var showArchive: Bool = false
    @Binding var path: [NavDestination]

    var activeDate: Date {
        return Calendar.current.startOfDay(for: conductor.date)
    }

    var todayDate: Date {
        return Calendar.current.startOfDay(for: Date())
    }

    var body: some View {
        @Bindable var conductor = conductor
        Spacer()

        AniButton(action: { stepDate(by: -1) }) {
            Image(systemName: "chevron.left")
        }

        Spacer()

        AniToggle(toggledOn: $conductor.showArchive, action: nil) {
            Image(systemName: "archivebox")
        }

        AniToggle(toggledOn: $conductor.showDatePicker, action: nil) {
            Text(DateTimeString.toolbarDateString(date: activeDate))
                .fixedSize()
                .frame(width: 120)
        }.onChange(of: conductor.date) {
            WidgetCenter.shared.reloadAllTimelines()
        }

        AniButton {
            let newItem = Item(position: conductor.itemCount, timestamp: activeDate)
            modelContext.insert(newItem)
            conductor.editItem = newItem
        } label: {
            Image(systemName: "plus")
        }

        Spacer()

        AniButton(action: { stepDate(by: 1) }) {
            Image(systemName: "chevron.right")
        }

        Spacer()
    }

    fileprivate func stepDate(by days: TimeInterval) {
        withAnimation {
            conductor.date = Calendar.current.startOfDay(for: conductor.date.advanced(by: 86400 * days))
        }
    }

    fileprivate func stepTo(date: Date) {
        withAnimation {
            conductor.date = Calendar.current.startOfDay(for: date)
        }
    }
}

struct ArchiveItemSheet: View {
    @Environment(\.modelContext) private var modelContext: ModelContext
    @Environment(DayDetailsConductor.self) private var conductor: DayDetailsConductor
    var date: Date
    var position: Int
    @State var selectedArchivedItems = Set<Item>()
    @Query(filter: #Predicate<Item> { $0.parent == nil && $0.archived == true }, sort: \Item.archivedAt, order: .reverse) var archivedItems: [Item]
    @State var archiveItemSearch: String = ""
    @State var mode: EditMode = .active
    @State var newArchiveItemNoteData: NoteData = .init(text: "")
    @State var newArchiveItem: Item = .init(position: 0, timestamp: Date())
    @State var showNewArchiveItem: Bool = false
    @FocusState var focusNewArchiveItem: Bool

    var body: some View {
        VStack {
            HStack {
                Text("archive_")
                Spacer()

                AniButton {
                    newArchiveItemNoteData = .init(text: "")
                    newArchiveItem = .init(position: 0, timestamp: Date())
                    newArchiveItem.archived = true
                    newArchiveItem.archivedAt = Date()
                    showNewArchiveItem = true
                    modelContext.insert(newArchiveItem)
                    mode = .inactive
                } label: {
                    Image(systemName: "plus")
                }
            }

            if archivedItems.isEmpty {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Text("archive empty...")
                        Spacer()
                    }
                    Spacer()
                }
            }
            List(archivedItems, id: \.self, selection: $selectedArchivedItems) { archivedItem in
                if showNewArchiveItem, archivedItem == newArchiveItem {
                    HStack {
                        TextField("...", text: $newArchiveItemNoteData.text)
                            .focused($focusNewArchiveItem)
                            .onSubmit {
                                showNewArchiveItem = false

                                if newArchiveItemNoteData.text.isEmpty {
                                    modelContext.delete(newArchiveItem)
                                } else {
                                    newArchiveItem.noteData = newArchiveItemNoteData
                                    mode = .active
                                    try? modelContext.save()
                                }
                            }.submitScope()
                    }.onAppear {
                        focusNewArchiveItem = true
                    }
                    .listRowBackground(Color.clear)
                    .listRowSpacing(4)
                } else {
                    HStack {
                        Text(archivedItem.noteData.text)
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                    .listRowSpacing(4)
                    .onAppear {
                        if archivedItem.noteData.text.isEmpty {
                            modelContext.delete(archivedItem)
                        }
                    }
                }

            }.listStyle(.plain)
        }.environment(\.editMode, $mode)
            .padding()
            .presentationBackground(.black)
            .presentationSizing(.fitted)
            .tint(.white)

        HStack {
            if selectedArchivedItems.isNotEmpty {
                AniButton {
                    for (i, selected) in selectedArchivedItems.enumerated() {
                        selected.timestamp = date
                        selected.position = position + i
                        selected.archived = false
                        selected.archivedAt = nil
                    }
                    mode = .inactive
                    conductor.showArchive = false
                    try? modelContext.save()
                } label: {
                    Image(systemName: "arrow.up.bin.fill")
                }
            }
        }.padding()
    }
}
