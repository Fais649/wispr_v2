//
//  DefaultDatePicker.swift
//  wispr
//
//  Created by Faisal Alalaiwat on 21.03.25.
//

import SwiftData
import SwiftUI

struct DefaultDatePicker: View {
    @Environment(ThemeStateService.self) private var theme: ThemeStateService
    @Environment(NavigationStateService.self) var navigationStateService: NavigationStateService

    var body: some View {
            DatePicker(
                "",
                selection: Bindable(navigationStateService).activeDate,
                displayedComponents: [.date]
            )
    }
}
