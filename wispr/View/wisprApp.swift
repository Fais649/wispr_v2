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
    @State var audioService: AudioService = .init()
    @State var activeTheme: ActiveTheme = .init()
    @State var dayScreenReader: DayScreenReader = .init()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(SharedState.calendarService)
                .environment(audioService)
                .environment(dayScreenReader)
                .environment(activeTheme)
                .preferredColorScheme(.dark)
                .accentColor(activeTheme.theme.toolbarForegroundColor)
        }
        .modelContainer(SharedState.sharedModelContainer)
    }
}
