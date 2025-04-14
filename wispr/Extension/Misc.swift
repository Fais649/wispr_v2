
import AppIntents
import AudioKit
import AVFoundation
import EventKit
import EventKitUI
import Foundation
import SwiftData
import SwiftUI
import SwiftWhisper

public extension Date {
    var defaultIntentParameter: IntentParameter<Date> {
        let i = IntentParameter<Date>(title: "Date", default: self)
        i.wrappedValue = self
        return i
    }
}

extension Calendar {
    func nextDay(for date: Date) -> Date {
        Calendar.current.startOfDay(for: date.advanced(
            by:
            86400
        ))
    }

    func previousDay(for date: Date) -> Date {
        Calendar.current.startOfDay(for: date.advanced(
            by:
            -86400
        ))
    }

    func combineDateAndTime(date: Date, time: Date) -> Date {
        var comps = Calendar.current.dateComponents(
            [.year, .month, .day],
            from: date
        )
        comps.hour = Calendar.current.component(.hour, from: time)
        comps.minute = Calendar.current.component(.minute, from: time)
        let d = Calendar.current.date(from: comps)
        return d ?? time
    }

    func startOfWeek(_ date: Date) -> Date? {
        guard
            let sunday = self.date(from: dateComponents(
                [.yearForWeekOfYear, .weekOfYear],
                from: date
            )) else { return nil }
        return self.date(byAdding: .day, value: 1, to: sunday)
    }

    func endOfWeek(_ date: Date) -> Date? {
        guard
            let sunday = self.date(from: dateComponents(
                [.yearForWeekOfYear, .weekOfYear],
                from: date
            )) else { return nil }
        return self.date(byAdding: .day, value: 7, to: sunday)
    }

    func startOfHour(for date: Date) -> Date {
        return self.date(from: dateComponents(
            [.year, .month, .day, .hour],
            from: date
        ))!
    }

    func roundToNearestHalfHour(_ date: Date) -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: date)
        let minute = components.minute ?? 0

        let roundedMinutes: Int
        if minute < 15 {
            roundedMinutes = 0
        } else if minute < 45 {
            roundedMinutes = 30
        } else {
            // Move to next hour
            return calendar.date(
                byAdding: .hour,
                value: 1,
                to: calendar.startOfHour(for: date)
            )!
        }

        return calendar.date(
            bySettingHour: components.hour ?? 0,
            minute: roundedMinutes,
            second: 0,
            of: date
        )!
    }
}

extension UIColor {
    convenience init(hex: String) {
        var hexString = hex.trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased()
        if hexString.hasPrefix("#") {
            hexString.removeFirst()
        }

        let scanner = Scanner(string: hexString)

        var rgbValue: UInt64 = 0
        var red, green, blue, alpha: UInt64
        if scanner.scanHexInt64(&rgbValue) {
            switch hexString.count {
                case 6:
                    red = (rgbValue >> 16)
                    green = (rgbValue >> 8 & 0xFF)
                    blue = (rgbValue & 0xFF)
                    alpha = 255
                case 8:
                    red = (rgbValue >> 16)
                    green = (rgbValue >> 8 & 0xFF)
                    blue = (rgbValue & 0xFF)
                    alpha = rgbValue >> 24
                default:
                    red = 0
                    green = 0
                    blue = 0
                    alpha = 0
            }
        } else {
            red = 0
            green = 0
            blue = 0
            alpha = 0
        }

        self.init(
            red: CGFloat(red) / 255,
            green: CGFloat(green) / 255,
            blue: CGFloat(blue) / 255,
            alpha: CGFloat(alpha) / 255
        )
    }

    func toHex(includeAlpha: Bool = false) -> String? {
        guard let components = cgColor.components
        else {
            return nil
        }

        let red = Int(components[0] * 255.0)
        let green = Int(components[1] * 255.0)
        let blue = Int(components[2] * 255.0)

        let hexString: String
        if includeAlpha, let alpha = components.last {
            let alphaValue = Int(alpha * 255.0)
            hexString = String(
                format: "#%02X%02X%02X%02X",
                red,
                green,
                blue,
                alphaValue
            )
        } else {
            hexString = String(format: "#%02X%02X%02X", red, green, blue)
        }

        return hexString
    }
}

extension UIView {
    var allSubViews: [UIView] {
        return subviews.flatMap { [$0] + $0.allSubViews }
    }
}
