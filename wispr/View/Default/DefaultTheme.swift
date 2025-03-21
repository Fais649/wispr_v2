//
//  DefaultTheme.swift
//  wispr
//
//  Created by Faisal Alalaiwat on 21.03.25.
//
import SwiftUI

struct DefaultTheme: UITheme {
    var toolbarBlur: UIBlurEffect { .init(style: .systemUltraThinMaterial) }
    var toolbarForegroundColor: Color { .white }
    var toolbarBackgroundColor: Color { .black }
    
    var headerMaterial: Material { .ultraThinMaterial }
    var headerBackgroundColor: Color { .gray }
    var headerForegroundColor: Color { .white }
    
    var contentMaterial: Material { .thickMaterial }
    var contentBackgroundColor: Color { .black }
    var contentForegroundColor: Color { .white }
    
    var symbolMaterial: Material { .ultraThinMaterial }
    var symbolBackgroundColor: Color { .white }
    var symbolForegroundColor: Color { .black }
}
