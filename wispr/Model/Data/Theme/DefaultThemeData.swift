//
//  DefaultTheme.swift
//  wispr
//
//  Created by Faisal Alalaiwat on 21.03.25.
//
import SwiftUI

struct DefaultThemeData: ThemeData {
    var h1: Font { .h1 }
    var h2: Font { .h2 }
    var h3: Font { .h3 }
    var h4: Font { .h4 }
    var h5: Font { .h5 }
    var h6: Font { .h6 }
    var h7: Font { .h7 }

    var accentColor: Color { .white }
    var defaultBackgroundColor: Color { .white }
    var backgroundMaterialOverlay: Material { .thin }
    var listRowSeparator: Visibility { .hidden }
    var sectionRowSeparator: Visibility { .hidden }
}
