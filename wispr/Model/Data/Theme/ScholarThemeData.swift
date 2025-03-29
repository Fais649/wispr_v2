//
//  ScholarThemeData.swift
//  wispr
//
//  Created by Faisal Alalaiwat on 25.03.25.
//
import SwiftUI

struct ScholarThemeData: ThemeData {
    var h1: Font { .notoSerif(.regular, size: Font.h1Size) }
    var h2: Font { .notoSerif(.regular, size: Font.h2Size) }
    var h3: Font { .notoSerif(.regular, size: Font.h3Size) }
    var h4: Font { .notoSerif(.regular, size: Font.h4Size) }
    var h5: Font { .notoSerif(.regular, size: Font.h5Size) }
    var h6: Font { .notoSerif(.regular, size: Font.h6Size) }
    var h7: Font { .notoSerif(.regular, size: Font.h7Size) }

    var accentColor: Color { .white }
    var defaultBackgroundColor: Color {
        Color(red: 0.76, green: 0.65, blue: 0.50)
    }

    var backgroundMaterialOverlay: Material { .ultraThinMaterial }
    var sectionRowSeparator: Visibility { .visible }
}
