//
//  Screen.swift
//  wispr
//
//  Created by Faisal Alalaiwat on 21.03.25.
//
import SwiftUI

extension View {
    func screenStyler() -> some View {
        modifier(ScreenStyler())
    }
}

private struct ScreenStyler: ViewModifier {
    @Environment(NavigatorService.self) private var nav: NavigatorService
    @Environment(ActiveTheme.self) private var activeTheme: ActiveTheme
    func body(content: Content) -> some View {
        VStack {
            content

            if nav.showDatePicker {
                nav.datePicker()
                    .id("defaultDatePicker")
                    .background {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(activeTheme.theme.headerMaterial)
                            .blur(radius: 50)
                    }
            }
        }
        .padding(.top, ScreenConstant.paddingTop)
        .padding(.bottom, ScreenConstant.paddingBottom)
        .padding(.leading, ScreenConstant.paddingLeading)
        .padding(.trailing, ScreenConstant.paddingTrailing)
    }
}
