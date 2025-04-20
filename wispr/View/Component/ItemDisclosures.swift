//
//  ItemDisclosures.swift
//  wispr
//
//  Created by Faisal Alalaiwat on 21.03.25.
//
import SwiftData
import SwiftUI

struct ItemDisclosures: View {
    @Environment(
        Globals
            .self
    ) private var globals: Globals
    @Environment(
        NavigationStateService
            .self
    ) private var navigationStateService: NavigationStateService
    @Environment(
        FlashStateService
            .self
    ) private var flashService: FlashStateService
    @Environment(\.modelContext) private var modelContext: ModelContext

    @Environment(\.editMode) var editMode
    var isEditing: Bool {
        if let editMode {
            return editMode.wrappedValue.isEditing
        }

        return false
    }

    var animation: Namespace.ID

    var expandable: Bool = true
    @State var defaultExpanded: Bool = false
    var items: [Item]
    var prefix: Int? = nil

    func onMove(_ indexSet: IndexSet, _ newIndex: Int) {
        let _ = ItemStore.updatePositions(
            items: items,
            indexSet: indexSet,
            newIndex: newIndex
        )
    }

    func onMoveChild(_ item: Item, _ indexSet: IndexSet, _ newIndex: Int) {
        var c = item.children
        c.move(fromOffsets: indexSet, toOffset: newIndex)
        for (index, child) in c.enumerated() {
            child.position = index
        }
        item.setChildren(c)
    }

    var body: some View {
        Disclosures(
            animation: animation,
            expandable: expandable,
            defaultExpanded: defaultExpanded,
            items: items,
            prefix: prefix,
            onMove: onMove,
            onDelete: delete,
            onMoveChild: onMoveChild,
            onDeleteChild: delete
        ) { item in
            label(item)
                .id(item.id)
        } childRow: { child in
            row(child)
                .id(child.id)
        }
        .listRowInsets(EdgeInsets())
        .opacity(flashService.isFlashing ? 0 : 1)
    }

    @ViewBuilder
    func label(_ item: Item) -> some View {
        Button {
            if item.isTask {
                withAnimation {
                    item.toggleTaskDataCompletedAt()
                }
            } else {
                navigationStateService.goToItemForm(item)
            }
        } label: {
            ItemRowLabel(item: item)
                .opacity(getOpacity(item))
                .scaleEffect(getScale(item), anchor: .leading)
        }
        .contentShape(Rectangle())
        .parentItem()
        .buttonStyle(.plain)
    }

    func getScale(_ item: Item) -> CGFloat {
        if let task = item.taskData {
            return task.completedAt == nil ? 1 : 0.8
        }

        return 1
    }

    func getOpacity(_ item: Item) -> CGFloat {
        if let task = item.taskData {
            return task.completedAt == nil ? 1 : 0.6
        }

        return 1
    }

    func row(_ child: Item) -> some View {
        Button {
            if child.isTask {
                withAnimation {
                    child.toggleTaskDataCompletedAt()
                }
            }
        } label: {
            ItemRowLabel(item: child)
                .opacity(getOpacity(child))
                .scaleEffect(getScale(child), anchor: .leading)
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
        .childItem()
    }

    @ViewBuilder
    func archiveButton(_ item: Item) -> some View {
        AniButton {
            self.archive(item)
        } label: {
            Image(systemName: "archivebox.fill")
        }
        .tint(.clear)
    }

    @ViewBuilder
    func deleteButton(_ item: Item) -> some View {
        Button(role: .destructive) {
            withAnimation {
                self.delete(item)
            }
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

    func onDelete(_ indexSet: IndexSet) {
        guard let index = indexSet.first else {
            return
        }

        let item = items[index]
        checkEventData(item)
        withAnimation {
            self.modelContext.delete(item)
        }
    }

    func delete(_ item: Item) {
        checkEventData(item)
        withAnimation {
            self.modelContext.delete(item)
        }
    }

    func checkEventData(_ item: Item) {
        if item.isEvent {
            Task {
                item.toggleEvent()
            }
        }
    }
}
