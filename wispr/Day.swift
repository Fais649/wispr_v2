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
    @State var hideItemList: Bool = false

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
                if !showItemForm {
                    HStack {
                        Spacer()
                        Image("Logo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 10, height: 10)
                        Spacer()
                    }.padding()
                }

                VStack {
                    ItemList(items: dayItems)
                        .environment(\.editMode, .constant(self.isEditing ? EditMode.active : EditMode.inactive))
                        .onChange(of: conductor.editItem) {
                            withAnimation {
                                showItemForm = conductor.editItem != nil
                            }
                        }.onChange(of: showItemForm) {
                            if !showItemForm {
                                withAnimation {
                                    conductor.editItem = nil
                                }
                            }
                        }
                }

                VStack {
                    if showItemForm {
                        @Bindable var conductor = conductor
                        ItemForm(
                            item: conductor.editItem,
                            showItemForm: $showItemForm,
                            timestamp: $conductor.date,
                            position: items.count
                        ).onDisappear {
                            withAnimation {
                                hideItemList = false
                            }
                        }
                        .transition(.push(from: .bottom))
                        .opacity(conductor.showDatePicker ? 0 : 1)
                        .onDisappear {
                            WidgetCenter.shared.reloadAllTimelines()
                        }
                    }

                    if conductor.showDatePicker {
                        @Bindable var conductor = conductor
                        HStack {
                            DatePicker("", selection: $conductor.date, displayedComponents: [.date])
                                .datePickerStyle(.graphical)
                                .labelsHidden()
                        }
                    }
                }
                .padding()
                .tint(.white)

                BottomToolbar(
                    showItemForm: $showItemForm,
                    path: $path,
                    itemCount: items.count
                ).onAppear {
                    WidgetCenter.shared.reloadAllTimelines()
                }
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
                SharedState.commitEditItem(context: modelContext)
            }
        }
        .font(.custom("GohuFont11NFM", size: 16))
        .onAppear(perform: { calendarService.syncCalendar(modelContext: modelContext) })
    }

    @State var showItemForm: Bool = false

    func dateString(date: Date) -> String {
        return date.formatted(.dateTime.weekday(.wide).day().month().year())
    }
}

struct BottomToolbar: View {
    @Environment(\.modelContext) private var modelContext: ModelContext
    @Environment(DayDetailsConductor.self) private var conductor: DayDetailsConductor

    @Binding var showItemForm: Bool
    @Binding var path: [NavDestination]
    let itemCount: Int

    var activeDate: Date {
        return Calendar.current.startOfDay(for: conductor.date)
    }

    var todayDate: Date {
        return Calendar.current.startOfDay(for: Date())
    }

    var body: some View {
        HStack {
            Button(action: { withAnimation { showItemForm.toggle() } }) {
                Image(systemName: "plus")
                    .rotationEffect(.degrees(showItemForm ? 45 : 0))
                    .font(.system(size: conductor.isEditingItem ? 20 : 16))
            }
            .padding(.horizontal)

            Spacer()
            Spacer()

            Button(action: { stepDate(by: -1) }) {
                Image(systemName: "chevron.left")
            }.padding(.horizontal)

            Spacer()

            Button(action: { stepTo(date: Date()) }) {
                Image(systemName: "circle.dotted.circle")
            }.opacity(activeDate == todayDate ? 0 : 1).disabled(activeDate == todayDate)

            Button {
                withAnimation {
                    conductor.showDatePicker.toggle()
                }
            } label: {
                header
            }.onChange(of: conductor.date) {
                WidgetCenter.shared.reloadAllTimelines()
            }

            Spacer()

            Button(action: { stepDate(by: 1) }) {
                Image(systemName: "chevron.right")
            }.padding(.horizontal)

            Spacer()
            Spacer()

            NavigationLink(value: NavDestination.timeline) {
                Image(systemName: "calendar.day.timeline.left")
            }.onChange(of: conductor.date) {
                path.removeAll()
            }.opacity(showItemForm ? 0 : 1).disabled(showItemForm)
                .padding(.horizontal)
        }.padding()
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
            }

            if activeDate > todayDate {
                Text(DateTimeString.toolbarFutureDateString(date: conductor.date))
                    .fixedSize()
            }
        }
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
        conductor.editItem = Item(position: itemCount, timestamp: conductor.date)

        // if conductor.editItem == nil {
        //     _ = SharedState.createNewItem(date: conductor.date, position: itemCount)
        // } else {
        //     conductor.rollback(context: modelContext)
        // }
    }
}
