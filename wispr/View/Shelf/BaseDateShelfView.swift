//
//  BaseDateShelfView.swift
//  wispr
//
//  Created by Faisal Alalaiwat on 29.03.25.
//
import SwiftUI

struct BaseDateShelfView: DateShelfView {
    @Environment(NavigationStateService.self) private var navigationStateService
    @State var showCalendarShelf: Bool = false

    var body: some View {
        VStack {
            DatePicker(
                "",
                selection: Bindable(navigationStateService).activeDate,
                displayedComponents: [.date]
            ).datePickerStyle(.graphical)
                .frame(width: 340, height: 340)

            ToolbarButton {
                showCalendarShelf.toggle()
            } label: {
                Image(systemName: "calendar")
            }.hidden()
        }
    }

    var label: some View {
        Text(navigationStateService.activeDate.formatted())
    }
}
