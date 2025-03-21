//
//  ItemDisclosureGroup.swift
//  wispr
//
//  Created by Faisal Alalaiwat on 21.03.25.
//

import SwiftData
import SwiftUI

extension View {
    func itemDisclosureGroupStyler(
        isAnimated: Bool = false,
        hideExpandButton: Bool
    ) -> some View {
        modifier(
            ItemDisclosureGroupStyler(
                isAnimated: isAnimated,
                hideExpandButton: hideExpandButton
            )
        )
    }
}

private struct ItemDisclosureGroupStyler: ViewModifier {
    let isAnimated: Bool
    let hideExpandButton: Bool
    func body(content: Content) -> some View {
        content
            .disclosureGroupStyle(
                ItemDisclosureGroupStyle(
                    isAnimated: isAnimated,
                    hideExpandButton: hideExpandButton
                )
            )
    }
}

private struct ItemDisclosureGroupStyle: DisclosureGroupStyle {
    @Environment(\.modelContext) private var modelContext: ModelContext
    @Environment(
        DayScreenReader
            .self
    ) private var dayScreenReader: DayScreenReader
    var isAnimated = false
    let hideExpandButton: Bool
    @State var opacity: CGFloat = 1
    @State var blur: CGFloat = 0

    func makeBody(configuration: Configuration) -> some View {
        label(configuration)
            .listRowStyler(10)
            .onTapGesture {
                if !self.hideExpandButton {
                    withAnimation {
                        configuration.isExpanded.toggle()
                    }
                }
            }

        if configuration.isExpanded {
            configuration.content
                .listRowStyler()
                .padding(.leading, 24)
        }
    }

    @ViewBuilder
    func label(_ configuration: Configuration) -> some View {
        if isAnimated {
            animatedLabel(configuration)
        } else {
            staticLabel(configuration)
        }
    }

    @ViewBuilder
    func staticLabel(_ configuration: Configuration) -> some View {
        HStack(alignment: .center) {
            if !self.hideExpandButton {
                Rectangle()
                    .fill(.white)
                    .frame(width: 2, height: 16)
                    .rotationEffect(.degrees(
                        configuration
                            .isExpanded ? 90 : 18
                    ))
            } else {
                Rectangle()
                    .fill(.white)
                    .frame(width: 2, height: 2)
            }

            configuration.label
            Spacer()
        }
    }

    @ViewBuilder
    func animatedLabel(_ configuration: Configuration) -> some View {
        GeometryReader { geo in
            self.staticLabel(configuration)
                .blur(radius: blur)
                .opacity(opacity)
                .onAppear {
                    self.updateAnimation(geo)
                }
                .onChange(of: geo.frame(in: .global).minY) {
                    self.updateAnimation(geo)
                }
        }
    }

    func updateAnimation(_ geo: GeometryProxy) {
        let yPos = geo.frame(in: .global).minY
        let listTop = dayScreenReader.minY
        let distance = max(yPos - listTop, 0)
        opacity = min(distance / 30.0, 1.0)
        let effectiveDistance = min(
            distance,
            30.0
        )
        blur = (1 - (effectiveDistance / 30.0)) * 5
    }
}
