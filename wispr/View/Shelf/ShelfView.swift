//
//  ShelfView.swift
//  wispr
//
//  Created by Faisal Alalaiwat on 29.03.25.
//
import SwiftUI

protocol ShelfView: View {
    associatedtype T
    associatedtype Label: View
    var label: Self.Label { get }
}

protocol DateShelfView: ShelfView where T == Date {}
protocol ItemDateShelfView: DateShelfView {}

protocol BookShelfView: ShelfView where T == Book {}


extension View {
    func dateShelf<V: DateShelfView>(
        @ViewBuilder _ shelfView: @escaping ()
        -> V
    ) -> some View {
        modifier(DateShelfModifier(shelfView: shelfView))
    }
}

struct DateShelfModifier<V: DateShelfView>: ViewModifier {
    @Environment(NavigationStateService.self) private var navigationStateService
    
    @ViewBuilder
    var shelfView: () -> V
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                navigationStateService.shelfState.setDateShelfView(shelfView())
            }
    }
}
