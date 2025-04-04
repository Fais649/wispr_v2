//
//  Listable.swift
//  wispr
//
//  Created by Faisal Alalaiwat on 25.03.25.
//
import SwiftUI

protocol Listable: Identifiable, Equatable {
    associatedtype Child: Identifiable
    var children: [Child] { get }
    var shadowTint: Color { get }
    var fillTint: Color { get }
}

extension Listable {
    var shadowTint: Color { Color.clear }
    var fillTint: Color { Color.white }
}
