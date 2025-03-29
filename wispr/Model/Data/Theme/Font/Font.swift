//
//  FontModifier.swift
//  wispr
//
//  Created by Faisal Alalaiwat on 21.03.25.
//
import SwiftUI

public extension Font {
    static var h1Size: CGFloat = 36
    static var h2Size: CGFloat = 24
    static var h3Size: CGFloat = 20
    static var h4Size: CGFloat = 16
    static var h5Size: CGFloat = 12
    static var h6Size: CGFloat = 10
    static var h7Size: CGFloat = 10

    static var h1: Font = .system(size: h1Size, weight: .bold)
    static var h2: Font = .system(size: h2Size, weight: .regular)
    static var h3: Font = .system(size: h3Size, weight: .light)
    static var h4: Font = .system(size: h4Size, weight: .light)
    static var h5: Font = .system(size: h5Size, weight: .light)
    static var h6: Font = .system(size: h6Size, weight: .light)
    static var h7: Font = .system(size: h7Size, weight: .thin)

    static func notoSerif(_ font: NotoSerif, size: CGFloat) -> Font {
        return .custom(font.rawValue, size: size)
    }

    static func gohuFont(size: CGFloat) -> Font {
        return .custom(Gohu.mono.rawValue, size: size)
    }
}
