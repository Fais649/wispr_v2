//
//  DateShelfButtonLabel.swift
//  wispr
//
//  Created by Faisal Alalaiwat on 25.03.25.
//
import SwiftUI

struct DateShelfButtonLabel: View {
    @Environment(ThemeStateService.self) private var theme: ThemeStateService
    @Environment(NavigationStateService.self) var navigationStateService: NavigationStateService

    var date: Date? = nil
    var d: Date {
        date ?? navigationStateService.activeDate
    }

    var body: some View {
        Text(
            d.formatted(
                .dateTime.day().month()
                    .year(.twoDigits)
            )
        )
    }
}
