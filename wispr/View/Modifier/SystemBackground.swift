//
//  HiddenSystemBackground.swift
//  wispr
//
//  Created by Faisal Alalaiwat on 21.03.25.
//
import SwiftUI
import SwiftUIIntrospect

extension View {
    func hideSystemBackground() -> some View {
        modifier(HiddenSystemBackground())
    }
}

private struct HiddenSystemBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .introspect(
                .navigationStack,
                on: .iOS(.v18),
                scope: .ancestor
            ) { something in
                let allsubviews = something.view.allSubViews
                for view in allsubviews {
                    if
                        view.backgroundColor == .systemBackground,
                        view.debugDescription
                            .contains("NavigationStackHostingController")
                    {
                        view.backgroundColor = nil
                    }
                }
            }
    }
}
