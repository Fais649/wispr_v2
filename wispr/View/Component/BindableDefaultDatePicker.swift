//
//  BindableDefaultDatePicker.swift
//  wispr
//
//  Created by Faisal Alalaiwat on 25.03.25.
//
import SwiftUI

struct BindableDefaultDatePicker: View {
    @Environment(ThemeStateService.self) private var theme: ThemeStateService
    @Binding var date: Date

    var body: some View {
        DatePicker(
            "",
            selection: $date,
            displayedComponents: [.date]
        )
        .labelsHidden()
        .datePickerStyle(.graphical)
        .tint(Material.ultraThinMaterial)
        .frame(width: 360, height: 360)
        .padding(Spacing.m)
    }
}
