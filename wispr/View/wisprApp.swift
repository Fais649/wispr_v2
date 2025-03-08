//
//  wisprApp.swift
//  wispr
//
//  Created by Faisal Alalaiwat on 10.01.25.
//

import SwiftData
import SwiftUI

@main
struct wisprApp: App {
    @State var audioService: AudioService = .init()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(SharedState.calendarService)
                .environment(SharedState.dayDetailsConductor)
                .environment(SharedState.focusConductor)
                .environment(audioService)
                .preferredColorScheme(.dark)
        }
        .modelContainer(SharedState.sharedModelContainer)
    }
}
