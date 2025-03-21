//
//  UITheme.swift
//  wispr
//
//  Created by Faisal Alalaiwat on 21.03.25.
//
import SwiftData
import SwiftUI

protocol UITheme {
    var toolbarBlur: UIBlurEffect { get }
    var toolbarForegroundColor: Color { get }
    var toolbarBackgroundColor: Color { get }

    var headerMaterial: Material { get }
    var headerBackgroundColor: Color { get }
    var headerForegroundColor: Color { get }

    var contentMaterial: Material { get }
    var contentBackgroundColor: Color { get }
    var contentForegroundColor: Color { get }

    var symbolMaterial: Material { get }
    var symbolBackgroundColor: Color { get }
    var symbolForegroundColor: Color { get }
}
