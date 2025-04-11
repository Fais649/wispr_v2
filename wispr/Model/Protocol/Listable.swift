//
//  Listable.swift
//  wispr
//
//  Created by Faisal Alalaiwat on 25.03.25.
//
import SwiftUI

protocol Listable: Transferable, Identifiable, Equatable {
    associatedtype Child: Identifiable, Equatable
    var children: [Child] { get }
    @ViewBuilder
    var preview: AnyView { get }
    var shadowTint: Color { get }
    var fillTint: Color { get }
}

extension Listable {
    var shadowTint: Color { Color.clear }
    var fillTint: Color { Color.white }
}
