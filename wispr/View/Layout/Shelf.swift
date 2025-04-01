import SwiftUI

struct Shelf<Content: View>: View {
    var content: Content

    var body: some View {
        VStack {
            content
                .frame(width: 340, height: 340)
                .padding(Spacing.m)
        }
        .frame(width: 500, height: 400)
        .labelsHidden()
        .datePickerStyle(.graphical)
        .tint(Material.ultraThinMaterial)
    }
}

struct ShelfButton<Label: View, Content: View>: TestShelf {
    @Environment(ShelfStateService.self) private var shelfStateService
    var type: ShelfStateService.SType
    var label: Label
    var content: Content
    
    var body: some View {
        AniButton(padding: Spacing.none) {
            shelfStateService.toggle(type: type)
        } label: {
            label
        }.clipShape(Capsule())
    }
}

extension View {
    func dateShelf<Label: View, Content: View>(
        @ViewBuilder label: @escaping () -> Label,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        modifier(DateShelfModifier(label: label, shelf: content))
    }
    
    func bookShelf<Label: View, Content: View>(
        @ViewBuilder label: @escaping () -> Label,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        modifier(BookShelfModifier(label: label, shelf: content))
    }
}
    
struct DateShelfModifier<L: View, C: View>: ViewModifier {
    @Environment(ShelfStateService.self) private var shelfState
    var label:  () -> L
    var shelf: () -> C
    
    func body(content: Content) -> some View {
        content.onAppear {
            withAnimation {
                shelfState.setDateShelf(shelf, label)
            }
        }
    }
}

struct BookShelfModifier<L: View, C: View>: ViewModifier {
    @Environment(ShelfStateService.self) private var shelfState
    var label:  () -> L
    var shelf: () -> C
    
    func body(content: Content) -> some View {
        content.onAppear {
            withAnimation {
                shelfState.setBookShelf(shelf, label)
            }
        }
    }
}
// MARK: - testView Protocol
protocol TestShelf: View {
    associatedtype Label: View
    associatedtype Content: View
    var label: Label { get }
    var content: Content { get }
}
