//
//  HackerThemeData.swift
//  wispr
//
//  Created by Faisal Alalaiwat on 25.03.25.
//
import SwiftUI

struct HackerThemeData: ThemeData {
    var h1: Font { .gohuFont(size: Font.h1Size) }
    var h2: Font { .gohuFont(size: Font.h2Size) }
    var h3: Font { .gohuFont(size: Font.h3Size) }
    var h4: Font { .gohuFont(size: Font.h4Size) }
    var h5: Font { .gohuFont(size: Font.h5Size) }
    var h6: Font { .gohuFont(size: Font.h6Size) }
    var h7: Font { .gohuFont(size: Font.h7Size) }

    var accentColor: Color { .white }
    var defaultBackgroundColor: Color { .black }
    var backgroundMaterialOverlay: Material { .ultraThickMaterial }
}
