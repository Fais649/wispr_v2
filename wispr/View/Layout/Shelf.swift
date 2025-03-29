import SwiftUI

struct Shelf<Content: View>: View {
    @ViewBuilder
    var content: () -> Content

    var body: some View {
        VStack {
            content()
                .frame(width: 340, height: 340)
                .padding(Spacing.m)
        }
        .frame(width: 500, height: 400)
        .labelsHidden()
        .datePickerStyle(.graphical)
        .tint(Material.ultraThinMaterial)
    }
}


// MARK: - testView Protocol
protocol TestShelf: View {
    associatedtype Label: View
    var label: Label { get }
}

// MARK: - Observable Shelf Manager
class ShelfManager: ObservableObject {
    @Published var currentShelf: AnyView?

    func display<V: TestShelf>(_ shelf: V) {
        currentShelf = AnyView(shelf)
    }
}

// MARK: - ShelfViewModifier
struct ShelfViewModifier<V: TestShelf>: ViewModifier {
    @EnvironmentObject var shelfManager: ShelfManager
    let shelf: () -> V

    func body(content: Content) -> some View {
        content
            .onAppear {
                shelfManager.display(shelf())
            }
    }
}

// MARK: - View Extension for Convenience
extension View {
    func shelfView<V: TestShelf>(_ shelf: @escaping () -> V) -> some View {
        self.modifier(ShelfViewModifier(shelf: shelf))
    }
}

// MARK: - Example TestShelf Implementation
struct ExampleShelf: TestShelf {
    var label: some View {
        Text("Example Shelf")
            .font(.headline)
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(8)
    }

    var body: some View {
        HStack {
            label
            Spacer()
            Button("Action") {
                print("Shelf action triggered")
            }
        }
        .padding()
    }
}

