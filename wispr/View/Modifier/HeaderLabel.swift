//
//  HeaderLabelStyler.swift
//  wispr
//
//  Created by Faisal Alalaiwat on 21.03.25.
//
import SwiftUI

extension View {
    func headerLabelStyler(
        padding: CGFloat = 0,
        shadowRadius: CGFloat = 2,
        fontSize: CGFloat = 16
    ) -> some View {
        modifier(HeaderLabelStyler(
            padding: padding,
            shadowRadius: shadowRadius,
            fontSize: fontSize
        ))
    }
}

private struct HeaderLabelStyler: ViewModifier {
    var padding: CGFloat = 0
    var shadowRadius: CGFloat = 2
    var fontSize: CGFloat = 16

    func body(content: Content) -> some View {
        content
            .contentShape(Rectangle())
            .font(.system(size: fontSize))
            .foregroundStyle(.white)
            .shadow(color: .white, radius: shadowRadius)
            .padding(padding)
    }
}
