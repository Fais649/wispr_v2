//
//  BrandStyle.swift
//  wispr
//
//  Created by Faisal Alalaiwat on 31.03.25.
//
import SwiftUI

struct ToolbarButtonStyle: ViewModifier {
    @Environment(ThemeStateService.self) private var themeState
    var clipShape: AnyShape?

    func body(content: Content) -> some View {
        content
            .padding(Spacing.s)
            .background(themeState.activeTheme.toolbarButtonBackgroundStyle)
            .clipShape(clipShape ?? AnyShape(Circle()))
    }
}

struct HideBackgroundStyle: ViewModifier {
    @Binding var hide: Bool
    
    func body(content: Content) -> some View
    {
        content
            .background {
                if hide {
                    Color.clear
                }
            }
    }
}

struct TitleBarStyle: ViewModifier {
    @Environment(ThemeStateService.self) private var themeState
    func body(content: Content) -> some View {
        content
            .padding(Spacing.s)
            .titleFontStyle()
    }
}
