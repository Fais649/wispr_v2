//
//  ItemSamples.swift
//  wispr
//
//  Created by Faisal Alalaiwat on 31.01.25.
//

import Foundation

extension Item {
    static var sampleItems: [Item] {
        [
            Item(timestamp: Date()),
            Item(timestamp: Date()),
        ]
    }
}

// struct Test : View {
//    @Environment(\.modelContext) private var modelContext: ModelContext
//    @Environment(\.editMode) private var editMode
//    @State var date: Date
//    @State var items: [Item]
//    @State var isEditing: Bool = false
//
//    func dateString(date: Date) -> String {
//        return date.formatted(.dateTime.weekday(.wide).day().month().year())
//    }
//
//    func addTask() {
//        let newItem = Item.createTask(
//            title: "",
//            start: Date()
//        )
//        newItem.position = items.count
//        modelContext.insert(newItem)
//        items.append(newItem)
//        try! modelContext.save()
//    }
//
//    func addEvent() {
//        let newItem = Item.createEvent(
//            title: "",
//            start: Date().advanced(by: -7200),
//            end: Date().advanced(by: -3600)
//        )
//        newItem.position = items.count
//        modelContext.insert(newItem)
//
//        if let before = items.first(where: {$0.start > newItem.start}) {
//            items.insert(newItem, at: before.position)
//            for (index, item) in items.enumerated() {
//                item.position = index
//            }
//        } else {
//            items.append(newItem)
//        }
//        try! modelContext.save()
//    }
//
//    var body: some View {
//        VStack {
//            Text(date.formatted())
//                .foregroundStyle(.black)
//                .font(.title)
//                .background {
//                    RoundedRectangle(cornerRadius: 25).fill(.white).frame(width: 600, height: 400)
//                        .ignoresSafeArea()
//                }
//            List {
//                ForEach(items, id: \.self) { item in
//                    ItemRow(item: item)
//                        .listRowBackground(Color.clear)
//                        .listRowSeparator(.hidden)
//                }.onMove { indexSet, newIndex in
//                    for index in indexSet {
//                        let count = self.items.count
//                        let movedItem = self.items[index]
//
//                        if movedItem.type == .event {
//                            for i in 0..<newIndex {
//                                let item = items[i]
//                                if item.type == .event {
//                                    if movedItem.start < item.start {
//                                        print("bad order above")
//                                        return
//                                    }
//                                }
//                            }
//
//                            for i in newIndex..<count {
//                                let item = items[i]
//                                if item.type == .event {
//                                    if movedItem.start > item.start {
//                                        print("bad order below")
//                                        return
//                                    }
//                                }
//                            }
//                        }
//                    }
//
//                    items.move(fromOffsets: indexSet, toOffset: newIndex)
//
//                    for (index, item) in items.enumerated() {
//                        item.position = index
//                    }
//
//                    try! modelContext.save()
//                }
//            }
//            .environment(\.editMode, .constant(self.isEditing ? EditMode.active : EditMode.inactive))
//            .listRowSpacing(10)
//        }
//        .overlay(alignment: .bottomTrailing) {
//            HStack {
//                Spacer()
//                HStack {
//                    Button { withAnimation { isEditing.toggle() } } label: { Image(systemName: isEditing ? "xmark" : "pencil") }
//                    Button {withAnimation { addEvent()  }} label: { Image(systemName: "calendar.badge.plus") }
//                    Button {withAnimation { addTask()  }} label: { Image(systemName: "checkmark.circle.fill") }
//                }
//                .tint(.white)
//                .background(.black)
//                .clipShape(Capsule())
//            }
//        }
//    }
// }
