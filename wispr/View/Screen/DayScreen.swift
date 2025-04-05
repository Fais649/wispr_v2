//
//  DayScreen.swift
//  wispr
//
//  Created by Faisal Alalaiwat on 21.03.25.
//
import SwiftData
import SwiftUI

struct DayScreen: View {
    var items: [Item] = []

    @Binding var editMode: EditMode

    var noAllDayEvents: [Item] {
        ItemStore.filterAllDayEvents(from: items)
    }

    var body: some View {
        Lst {
            ItemDisclosures(items: noAllDayEvents)
        }
        .environment(\.editMode, $editMode)
        .overlay(alignment: .center) {
            if self.items.isEmpty {
                Image(systemName: "plus.circle.dashed")
                    .fontWeight(.ultraLight)
            }
        }
        // .onLongPressGesture {
        //     editMode = editMode.isEditing ? .inactive : .active
        // }
    }
}
