//
//  DefaultDatePickerButton.swift
//  wispr
//
//  Created by Faisal Alalaiwat on 25.03.25.
//
import SwiftUI

struct DefaultDatePickerButton: View {
    @Environment(ThemeStateService.self) private var theme: ThemeStateService
    @Environment(
        NavigationStateService
            .self
    ) var navigationStateService: NavigationStateService
    @State var showTodayButton: Bool = false

    var body: some View {
        HStack {
            if showTodayButton {
                ToolbarButton(
                    toggledOn: navigationStateService.shelfState.isDatePicker()
                ) {
                    navigationStateService.goToToday()
                } label: {
                    Image(systemName: "asterisk")
                        .decorationFontStyle()
                }
            }

            ToolbarButton(
                toggledOn: navigationStateService.shelfState.isDatePicker(),
                clipShape: Capsule()
            ) {
                navigationStateService.toggleDatePickerShelf()
            } label: {
                DefaultDatePickerButtonLabel()
            }
            .onChange(of: navigationStateService.activePath) {
                if navigationStateService.onForm {
                    withAnimation {
                        navigationStateService.closeShelf()
                    }
                }
            }
            .onChange(of: navigationStateService.activeDate) {
                withAnimation {
                    navigationStateService.closeShelf()
                    showTodayButton = !navigationStateService.isTodayActive
                }
            }
        }.onAppear {
            withAnimation {
                showTodayButton = !navigationStateService.isTodayActive
            }
        }
        .background {
            if !navigationStateService.isTodayActive {
                Capsule().fill(theme.activeTheme.backgroundMaterialOverlay)
                    .blur(radius: navigationStateService.shelfState.isDatePicker() ? 50 : 0)
                    .blendMode(.luminosity)
            }
        }
    }
}
