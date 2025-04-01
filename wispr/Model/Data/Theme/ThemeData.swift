//
//  Theme.swift
//  wispr
//
//  Created by Faisal Alalaiwat on 25.03.25.
//
import SwiftUI

protocol ThemeData {
    var h1: Font { get }
    var h2: Font { get }
    var h3: Font { get }
    var h4: Font { get }
    var h5: Font { get }
    var h6: Font { get }
    var h7: Font { get }
    
    var accentColor: Color { get }
    var backgroundMaterialOverlay: Material { get }
    var defaultBackgroundColor: Color { get }
    var listRowSeparator: Visibility { get }
    var sectionRowSeparator: Visibility { get }
    var toolbarButtonBackgroundStyle: AnyShapeStyle { get }
}

extension ThemeData {
    var listRowSeparator: Visibility { .hidden }
    var sectionRowSeparator: Visibility { .hidden }
    var toolbarButtonBackgroundStyle: AnyShapeStyle { AnyShapeStyle(.ultraThinMaterial) }
}
