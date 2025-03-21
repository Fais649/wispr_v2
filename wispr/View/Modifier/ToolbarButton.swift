//
//  ToolbarButtonLabelStyler.swift
//  wispr
//
//  Created by Faisal Alalaiwat on 21.03.25.
//
import SwiftUI

extension View {
    func toolbarButtonLabelStyler(
        padding: (x: CGFloat, y: CGFloat) = (x: 6, y: 6),
        shadowRadius: CGFloat = 2,
        fontSize: CGFloat = 16
    ) -> some View {
        modifier(ToolbarButtonLabelStyler(
            padding: padding,
            shadowRadius: shadowRadius,
            fontSize: fontSize
        ))
    }
}

private struct ToolbarButtonLabelStyler: ViewModifier {
    var padding: (x: CGFloat, y: CGFloat) = (x: 6, y: 6)
    var shadowRadius: CGFloat = 2
    var fontSize: CGFloat = 16

    func body(content: Content) -> some View {
        content
            .contentShape(Rectangle())
            .font(.system(size: fontSize))
            .foregroundStyle(.white)
            .shadow(color: .white, radius: shadowRadius)
            .padding(.horizontal, padding.x)
            .padding(.vertical, padding.y)
    }
}
