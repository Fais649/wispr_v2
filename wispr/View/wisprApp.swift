//
//  wisprApp.swift
//  wispr
//
//  Created by Faisal Alalaiwat on 10.01.25.
//

import SwiftData
import SwiftUI
import UIKit

@main
struct wisprApp: App {
    @State var theme: ThemeStateService = .init()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(theme)
                .preferredColorScheme(.dark)
                .accentColor(theme.activeTheme.accentColor)
        }
        .modelContainer(SharedState.sharedModelContainer)
    }
}
