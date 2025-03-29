import SwiftUI

struct TxtField: View {
    var label: String = ""
    @Binding var text: String
    @FocusState.Binding var focusState: FocusedField?
    var focus: FocusedField?
    var onEnterKeypress: ((_ isTextEmpty: Bool) -> Void)? = nil

    var body: some View {
        TextField(label, text: $text, axis: .vertical)
            .focused($focusState, equals: focus)
            .onChange(of: text) {
                guard let onEnterKeypress else { return }
                guard text.contains("\n") else { return }
                text = text.replacing("\n", with: "")
                onEnterKeypress(text.isEmpty)
            }
    }
}
