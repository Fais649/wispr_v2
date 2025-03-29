//
//  Flash.swift
//  wispr
//
//  Created by Faisal Alalaiwat on 21.03.25.
//
import SwiftUI

struct FlashData {
    enum FlashType: String {
        case success, error, warning, info
        
        var icon: Image {
            switch self {
                case .success:
                    Image(systemName: "checkmark.circle.fill")
                case .error:
                    Image(systemName: "xmark.circle.fill")
                case .warning:
                    Image(systemName: "exclamationmark.triangle.fill")
                default:
                    
                    Image(systemName: "info.circle.fill")
            }
        }
    }
    
    var type: FlashType
    var message: String
    var icon: Image {
        type.icon
    }
}


