//
//  DefaultDatePicker.swift
//  wispr
//
//  Created by Faisal Alalaiwat on 21.03.25.
//

import SwiftData
import SwiftUI

struct BindableDefaultDatePicker: View {
    @Environment(ActiveTheme.self) private var activeTheme: ActiveTheme
    @Binding var date: Date

    var body: some View {
        VStack {
            DatePicker(
                "",
                selection: $date,
                displayedComponents: [.date]
            )
            .datePickerStyle(.graphical)
            .tint(Material.ultraThinMaterial)
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(activeTheme.theme.headerMaterial)
        )
        .frame(width: 320, height: 320)
        .padding()
        .transition(.opacity)
    }
}

struct DefaultDatePicker: View {
    @Environment(ActiveTheme.self) private var activeTheme: ActiveTheme
    @Environment(NavigatorService.self) var nav: NavigatorService

    var body: some View {
        DatePicker(
            "",
            selection: Bindable(nav).activeDate,
            displayedComponents: [.date]
        )
        .datePickerStyle(.graphical)
        .tint(Material.ultraThinMaterial)
        .padding(10)
        .frame(width: 360, height: 360)
    }
}

struct DefaultDatePickerButton: View {
    @Environment(ActiveTheme.self) private var activeTheme: ActiveTheme
    @Environment(NavigatorService.self) var nav: NavigatorService

    var body: some View {
        ToolbarButton(
            toggle: Bindable(nav).showDatePicker,
            clipShape: Capsule()
        ) {
            self.nav.showDatePicker.toggle()
        } label: {
            nav.datePickerButtonLabel()
        }
        .onChange(of: nav.activePath) {
            nav.showDatePicker = false
        }
        .onChange(of: nav.activeDate) {
            nav.showDatePicker = false
        }
    }
}

struct DefaultDatePickerButtonLabel: View {
    @Environment(ActiveTheme.self) private var activeTheme: ActiveTheme
    @Environment(NavigatorService.self) var nav: NavigatorService

    var body: some View {
        Text(
            nav.activeDate
                .formatted(
                    .dateTime.day().month()
                        .year(.twoDigits)
                )
        )
    }
}
