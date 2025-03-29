//
//  Selectable.swift
//  wispr
//
//  Created by Faisal Alalaiwat on 25.03.25.
//
import SwiftUI

protocol Selectable {
    associatedtype T: View

    static func createNew() -> Self

    @ViewBuilder
    func editButtonLabel(isEdit: Bool, minimized: Bool) -> T

    associatedtype W: View

    associatedtype BackgroundView: View
    @ViewBuilder
    var selectedBackground: BackgroundView { get }

    @ViewBuilder
    var background: W { get }

    var searchable: String { get }
    var timestamp: Date { get set }
    var lastClicked: Date? { get set }
}
