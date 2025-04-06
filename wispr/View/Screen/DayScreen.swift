//
//  DayScreen.swift
//  wispr
//
//  Created by Faisal Alalaiwat on 21.03.25.
//
import SwiftData
import SwiftUI

struct DayScreen: View {
    @Environment(
        NavigationStateService
            .self
    ) private var navigationStateService:
        NavigationStateService
    var items: [Item] = []

    @Binding var editMode: EditMode

    var dayEvents: [Item] {
        ItemStore.allDayEvents(from: items)
    }

    var noAllDayEvents: [Item] {
        ItemStore.filterAllDayEvents(from: items)
    }

    var body: some View {
        Lst {
            if dayEvents.isNotEmpty {
                ForEach(dayEvents.sorted { first, second in
                    first.text.count > second.text.count
                }) { item in
                    Text(item.text)
                }
            }

            ItemDisclosures(
                defaultExpanded: true,
                items: noAllDayEvents
            )
        }
        .environment(\.editMode, $editMode)
        .overlay(alignment: .center) {
            if self.items.isEmpty {
                ToolbarButton(padding: 0) {
                    navigationStateService.goToItemForm()
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        // .onLongPressGesture {
        //     editMode = editMode.isEditing ? .inactive : .active
        // }
    }
}
