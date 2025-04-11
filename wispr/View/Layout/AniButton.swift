//
//  AniButton.swift
//  wispr
//
//  Created by Faisal Alalaiwat on 24.03.25.
//
import SwiftData
import SwiftUI

struct AniButton<Content: View>: View {
    @Environment(\.isEnabled) private var isEnabled
    var padding: CGFloat = Spacing.s
    var duration: Double = 0.5
    let action: () -> Void
    @ViewBuilder var label: () -> Content
    @State var clicked: Bool = false

    var backgroundColor: Color {
        return .clear
    }

    var foregroundColor: Color {
        if isEnabled {
            return .white
        } else {
            return .gray
        }
    }

    var body: some View {
        Button {
            // withAnimation(.spring(duration: duration)) {
            action()
            clicked.toggle()
            // }
        } label: {
            label()
        }.padding(padding)
            .background(backgroundColor)
            .foregroundStyle(foregroundColor)
    }
}
