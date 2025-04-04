import SwiftUI

public enum Padding {
    static let screenTop: CGFloat = Spacing.m
    static let screenBottom: CGFloat = Spacing.xl
    static let screenLeading: CGFloat = Spacing.l
    static let screenTrailing: CGFloat = Spacing.l

    static let toolbarPaddingBottom: CGFloat = Spacing.l
}

public enum Spacing {
    public static let none: CGFloat = 0
    public static let xxxs: CGFloat = 1
    public static let xxs: CGFloat = 2
    public static let xs: CGFloat = 4
    public static let s: CGFloat = 8
    public static let m: CGFloat = 16
    public static let l: CGFloat = 32
    public static let xl: CGFloat = 64
    public static let xxl: CGFloat = 128
    public static let xxxl: CGFloat = 256
}

@Observable
final class ThemeStateService {
    private var _theme: ThemeData = DefaultThemeData()

    var activeTheme: ThemeData {
        get {
            _theme
        }
        set {
            _theme = newValue
        }
    }
}
