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

    var body: some View {
        HStack {
            Text(DateTimeString.leftDateString(date: date))
                .fixedSize()
                .frame(alignment: .leading)
            RoundedRectangle(cornerRadius: 2).frame(height: 1)
            Text(DateTimeString.rightDateString(date: date))
                .fixedSize()
                .frame(alignment: .trailing)
            Spacer()
        }
        .tint(isEmpty ? .gray : .white)
        .opacity(isEmpty ? 0.7 : 1)
        .scaleEffect(isEmpty ? 0.8 : 1, anchor: .trailing)
        .truncationMode(.middle)
        .lineLimit(1)
    }
}

enum NavDestination: String, CaseIterable {
    case day, timeline
}

struct DayDetails: View {
    @Environment(\.modelContext) private var modelContext: ModelContext
    @Environment(\.scenePhase) var scenePhase
    @Environment(\.editMode) private var editMode

    @Environment(DayDetailsConductor.self) private var conductor: DayDetailsConductor
    @Environment(CalendarService.self) private var calendarService: CalendarService
    @State var isEditing: Bool = false

    @Namespace var namespace

    @Query var items: [Item]

    @State var path: [NavDestination] = []
    @FocusState var toolbarFocus: Bool

    @State var newTaskLinkActive = false

    var start: Date {
        Calendar.current.startOfDay(for: conductor.date)
    }

    var end: Date {
        start.advanced(by: 86400)
    }

    var dayItems: [Item] {
        items.filter { start <= $0.timestamp && $0.timestamp < end && $0.parent == nil }.sorted(by: { $0.position < $1.position })
    }

    @State var editItem: Item?

    var body: some View {
        NavigationStack(path: $path) {
            VStack {
                if !conductor.isEditingItem {
                    HStack {
                        Image("Logo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 30, height: 30)
                    }
                }

                VStack {
                    ItemList(editItem: $editItem, items: dayItems)
                        .environment(\.editMode, .constant(self.isEditing ? EditMode.active : EditMode.inactive))
                }

                toolBar.focused($toolbarFocus)
            }
            .matchedTransitionSource(id: conductor.date, in: namespace)
            .navigationDestination(for: NavDestination.self) { destination in
                switch destination {
                case .timeline:
                    TimeLineView(path: $path)
                        .navigationBarBackButtonHidden()
                        .navigationTransition(
                            .zoom(sourceID: conductor.date, in: namespace)
                        )
                case .day:
                    self
                }
            }
        }
        .onChange(of: scenePhase) {
            if [ScenePhase.background, ScenePhase.inactive].contains(scenePhase) {
                SharedState.commitEditItem()
            }
        }
        .font(.custom("GohuFont11NFM", size: 16))
        .onAppear(perform: { calendarService.syncCalendar(modelContext: modelContext) })
    }

    @ViewBuilder
    var toolBar: some View {
        VStack {
            TopToolbar(
                editItem: $editItem,
                path: $path,
                position: items.count
            )

            HStack {
                BottomToolbar(
                    path: $path,
                    itemCount: items.count
                ).onAppear {
                    WidgetCenter.shared.reloadAllTimelines()
                }
            }
        }.padding()
            .tint(.white)
    }

    func dateString(date: Date) -> String {
        return date.formatted(.dateTime.weekday(.wide).day().month().year())
    }
}

struct TopToolbar: View {
    @Environment(DayDetailsConductor.self) private var conductor: DayDetailsConductor
    @Binding var editItem: Item?
    @Binding var path: [NavDestination]
    let position: Int

    var body: some View {
        @Bindable var conductor = conductor
        if let e = editItem {
            HStack {
                EditItemForm(editItem: e, position: position)
            }.transition(.push(from: .bottom))
                .opacity(conductor.showDatePicker ? 0 : 1)
                .onDisappear {
                    WidgetCenter.shared.reloadAllTimelines()
                }
        }

        if conductor.showDatePicker {
            HStack {
                DatePicker("", selection: $conductor.date, displayedComponents: [.date])
                    .datePickerStyle(.graphical)
                    .labelsHidden()
            }
        }
    }

    func createNewItem() -> Item {
        return SharedState.createNewItem(date: conductor.date, position: position)
    }
}

struct BottomToolbar: View {
    @Environment(\.modelContext) private var modelContext: ModelContext
    @Environment(DayDetailsConductor.self) private var conductor: DayDetailsConductor
    @Binding var path: [NavDestination]
    let itemCount: Int

    @State var newItemLink = false

    var activeDate: Date {
        return Calendar.current.startOfDay(for: conductor.date)
    }

    var todayDate: Date {
        return Calendar.current.startOfDay(for: Date())
    }

    var body: some View {
        @Bindable var conductor = conductor
        VStack {
            HStack {
                if !conductor.isEditingItem {
                    NavigationLink(value: NavDestination.timeline) {
                        Image(systemName: "calendar.day.timeline.left")
                    }.onChange(of: conductor.date) {
                        path.removeAll()
                    }
                }

                Button {
                    withAnimation {
                        conductor.showDatePicker.toggle()
                    }
                } label: {
                    header
                }.onChange(of: conductor.date) {
                    WidgetCenter.shared.reloadAllTimelines()
                }
            }.padding()
            HStack {
                Spacer()

                Button(action: { stepDate(by: -1) }) {
                    Image(systemName: "chevron.left")
                }.padding(.horizontal)

                Spacer()
                Spacer()

                Button(action: createNewItem) {
                    Image(systemName: "plus")
                        .rotationEffect(.degrees(conductor.isEditingItem ? 45 : 0))
                        .font(.system(size: conductor.isEditingItem ? 20 : 16))
                }

                Spacer()
                Spacer()

                Button(action: { stepDate(by: 1) }) {
                    Image(systemName: "chevron.right")
                }.padding(.horizontal)

                Spacer()
            }.padding()
        }
        .padding()
        .padding(.horizontal, 50)
        .tint(.white)
    }

    @ViewBuilder
    var header: some View {
        HStack {
            if activeDate < todayDate {
                Text(DateTimeString.toolbarPastDateString(date: conductor.date))
                    .fixedSize()
            }

            if activeDate == todayDate {
                Text(DateTimeString.toolbarTodayDateString())
                    .fixedSize()
            } else {
                Button(action: { stepTo(date: Date()) }) {
                    Image(systemName: "circle.fill")
                }
            }

            if activeDate > todayDate {
                Text(DateTimeString.toolbarFutureDateString(date: conductor.date))
            }
        }
        .fixedSize()
        .padding(.horizontal)
        .lineLimit(1)
    }

    @ViewBuilder
    var headerLeft: some View {
        Text(DateTimeString.toolbarPastDateString(date: conductor.date))
            .fixedSize()
            .frame(alignment: .leading)
    }

    var headerCenter: some View {
        RoundedRectangle(cornerRadius: 2).frame(height: 1)
    }

    @ViewBuilder
    var headerRight: some View {
        Text(DateTimeString.toolbarFutureDateString(date: conductor.date))
            .frame(alignment: .trailing)
            .fixedSize()
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

    func createNewItem() {
        if conductor.editItem == nil {
            _ = SharedState.createNewItem(date: conductor.date, position: itemCount)
        } else {
            conductor.rollback(context: modelContext)
        }
    }
}
