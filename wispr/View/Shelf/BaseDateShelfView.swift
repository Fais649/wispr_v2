//
//  BaseDateShelfView.swift
//  wispr
//
//  Created by Faisal Alalaiwat on 29.03.25.
//
import SwiftUI

struct BaseDateShelfView: View {
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
}

struct BaseDateShelfLabelView: View {
    @Environment(ThemeStateService.self) private var theme: ThemeStateService
    @Environment(
        NavigationStateService
            .self
    ) var navigationStateService: NavigationStateService
    @State var showTodayButton: Bool = false
    
    var dateShelfShown: Bool  {
        navigationStateService.shelfState.isDatePicker()
    }
    
    var body: some View {
        HStack {
            if showTodayButton {
                ToolbarButton(
                    toggledOn: dateShelfShown
                ) {
                    navigationStateService.goToToday()
                } label: {
                    Image(systemName: "asterisk")
                        .decorationFontStyle()
                }
            }
            
            ToolbarButton(
                toggledOn: dateShelfShown,
                clipShape: Capsule()
            ) {
                navigationStateService.toggleDatePickerShelf()
            } label: {
                Text(
                    navigationStateService.activeDate.formatted(.dateTime.day().month().year(.twoDigits))
                )
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
                    .blur( radius: dateShelfShown ? 50 : 0 )
                    .blendMode(.luminosity)
            }
        }
    }
}
