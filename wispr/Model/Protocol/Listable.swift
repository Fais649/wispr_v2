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
    var preview: AnyView { get }
    var shadowTint: AnyShapeStyle { get }
    var fillTint: Color { get }
    var menuItems: [MenuItem] { get }
}

extension Listable {
    var shadowTint: AnyShapeStyle { AnyShapeStyle(Color.clear) }
    var fillTint: Color { Color.white }
    var menuItems: [MenuItem] { [] }
}
