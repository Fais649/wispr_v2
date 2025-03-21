//
//  ListRowStyler.swift
//  wispr
//
//  Created by Faisal Alalaiwat on 21.03.25.
//
import SwiftUI

extension View {
    func listRowStyler(_ rowSpacing: CGFloat = 0) -> some View {
        modifier(ListRowStyler(rowSpacing: rowSpacing))
    }
}

private struct ListRowStyler: ViewModifier {
    var rowSpacing: CGFloat = 0
    func body(content: Content) -> some View {
        content
            .listRowBackground(Color.clear)
            .listRowSpacing(rowSpacing)
            .listRowSeparator(.hidden)
            .contentShape(Rectangle())
            .font(.system(size: 16))
            .foregroundStyle(.white)
            .shadow(color: .white, radius: 2)
    }
}
