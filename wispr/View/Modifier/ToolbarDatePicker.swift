import SwiftUI

extension View {
    func navigatorDatePicker<Content: View>(
        @ViewBuilder datePicker: @escaping () -> Content
    ) -> some View {
        modifier(NavigatorDatePickerSetter(datePicker: datePicker))
    }

    func navigatorDatePickerButtonLabel<Content: View>(
        @ViewBuilder datePicker: @escaping () -> Content
    ) -> some View {
        modifier(NavigatorDatePickerButtonLabelSetter(datePicker: datePicker))
    }

    func resetDatePickerOnDisppear() -> some View {
        modifier(NavigatorDatePickerResetter())
    }
}

private struct NavigatorDatePickerButtonLabelSetter: ViewModifier {
    @Environment(NavigatorService.self) private var nav: NavigatorService
    private let datePicker: () -> AnyView

    init<Content: View>(@ViewBuilder datePicker: @escaping () -> Content) {
        self.datePicker = { AnyView(datePicker()) }
    }

    func body(content: Content) -> some View {
        content
            .onAppear {
                nav.setDatePickerButtonLabel {
                    datePicker()
                }
            }
    }
}

private struct NavigatorDatePickerSetter: ViewModifier {
    @Environment(NavigatorService.self) private var nav: NavigatorService
    private let datePicker: () -> AnyView

    init<Content: View>(@ViewBuilder datePicker: @escaping () -> Content) {
        self.datePicker = { AnyView(datePicker()) }
    }

    func body(content: Content) -> some View {
        content
            .onAppear {
                nav.setDatePicker {
                    datePicker()
                }
            }
    }
}

private struct NavigatorDatePickerResetter: ViewModifier {
    @Environment(NavigatorService.self) private var nav: NavigatorService

    func body(content: Content) -> some View {
        content
            .onDisappear {
                nav.resetDatePicker()
            }
    }
}
