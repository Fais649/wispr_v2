//
//  WeekTimelineScreen.swift
//  wispr
//
//  Created by Faisal Alalaiwat on 21.03.25.
//
import SwiftData
import SwiftUI

struct WeekTimelineScreen: View {
    @Environment(\.modelContext) private var modelContext: ModelContext
    @Environment(
        NavigationStateService
            .self
    ) private var navigationStateService: NavigationStateService

    @Query var days: [Day]

    var todayDate: Date {
        Calendar.current.startOfDay(for: Date())
    }

    @Namespace var animation

    @State private var loaded: Bool = false

    var body: some View {
        VStack {
            if loaded {
            } else {}
        }.task {}
    }
}
