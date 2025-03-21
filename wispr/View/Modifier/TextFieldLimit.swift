//
//  TextFieldLimit.swift
//  wispr
//
//  Created by Faisal Alalaiwat on 21.03.25.
//
import SwiftUI

extension View {
    func limitInputLength(value: Binding<String>, length: Int) -> some View {
        modifier(TextFieldLimitModifer(value: value, length: length))
    }
}

private struct TextFieldLimitModifer: ViewModifier {
    @Binding var value: String
    var length: Int

    func body(content: Content) -> some View {
        content
            .onReceive(value.publisher.collect()) {
                self.value = String($0.prefix(self.length))
            }
    }
}
