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
        NavigationStateService
            .self
    ) private var navigationStateService: NavigationStateService
    @Environment(FlashStateService.self) private var flashService: FlashStateService
    @Environment(\.modelContext) private var modelContext: ModelContext
    var items: [Item]

    func onMove(_ indexSet: IndexSet, _ newIndex: Int) {
        let (success, message) = ItemStore.updatePositions(
            items: items,
            indexSet: indexSet,
            newIndex: newIndex
        )

        if !success {
            withAnimation {
                flashService.flash = FlashData(type: .error, message: message)
            }
        }
    }

    func onMoveChild(_ item: Item, _ indexSet: IndexSet, _ newIndex: Int) {
        item.children.move(
            fromOffsets: indexSet,
            toOffset: newIndex
        )

        for (index, child) in item.children.enumerated() {
            child.position = index
        }
    }

    var body: some View {
        Disclosures(
            items: items,
            onMove: onMove,
            onMoveChild: onMoveChild
        ) { item in
            label(item)
                .id(item.id)
                .padding(Spacing.s)
        } childRow: { child in
            row(child)
                .id(child.id)
                .padding(Spacing.xxs)
        }
        .listRowInsets(EdgeInsets())
        .opacity(flashService.isFlashing ? 0 : 1)
    }

    @ViewBuilder
    func label(_ item: Item) -> some View {
        AniButton(padding: Spacing.xxs) {
            navigationStateService.activeDate = item.timestamp
            navigationStateService.pathState.setActive(.itemForm(item: item))
        } label: {
            VStack(alignment: .leading) {
                Text(item.text)
                    .truncationMode(.tail)
                    .lineLimit(1)

                if let e = item.eventData {
                    HStack {
                        Text(
                            e.startDate
                                .formatted(
                                    .dateTime.hour()
                                        .minute()
                                )
                        )
                        .eventTimeFontStyle()
                        Text("-")
                            .eventTimeFontStyle()
                        Text(
                            e.endDate
                                .formatted(
                                    .dateTime.hour()
                                        .minute()
                                )
                        )
                        .eventTimeFontStyle()
                    }
                }
            }
        }
        .parentItem()
        .padding(Spacing.s)
        .buttonStyle(.plain)
        .swipeActions(edge: .leading) {
            self.archiveButton(item)
        }.swipeActions(edge: .trailing) {
            self.deleteButton(item)
        }
    }

    func row(_ child: Item) -> some View {
        HStack {
            if var task = child.taskData {
                AniButton(padding: Spacing.none) {
                    task.completedAt = task
                        .completedAt == nil ? Date() : nil
                    child.taskData = task
                } label: {
                    Image(
                        systemName: task
                            .completedAt == nil ? "circle.dotted" :
                            "circle.fill"
                    )
                    .buttonFontStyle()
                }
            }

            AniButton(padding: Spacing.xs) {
                navigationStateService.goToItemForm(child.parent)
            } label: {
                Text(child.text)
                    .multilineTextAlignment(.leading)
            }

            Spacer()
        }
        .padding(Spacing.xxs)
        .childItem()
        .swipeActions(edge: .trailing) {
            self.deleteButton(child)
        }
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
        AniButton {
            self.delete(item)
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
