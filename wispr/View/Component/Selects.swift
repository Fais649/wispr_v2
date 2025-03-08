//
//  Selects.swift
//  wispr
//
//  Created by Faisal Alalaiwat on 02.03.25.
//
import Flow
import SwiftData
import SwiftUI

protocol Selectable {
    associatedtype T: View

    static func createNew() -> Self

    @ViewBuilder
    func editButtonLabel(isEdit: Bool, minimized: Bool) -> T

    associatedtype W: View

    associatedtype BackgroundView: View
    @ViewBuilder
    var selectedBackground: BackgroundView { get }

    @ViewBuilder
    var background: W { get }

    var searchable: String { get }
    var timestamp: Date { get set }
    var lastClicked: Date? { get set }
}

protocol Detailable: Selectable {
    @ViewBuilder
    func header() -> T

    @ViewBuilder
    func details() -> W

    associatedtype X: View
    @ViewBuilder
    func toolbar() -> X
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize,
                      subviews: Subviews,
                      cache _: inout ()) -> CGSize
    {
        let containerWidth = proposal.width ?? .infinity
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        return layout(sizes: sizes,
                      spacing: spacing,
                      containerWidth: containerWidth).size
    }

    func placeSubviews(in bounds: CGRect,
                       proposal _: ProposedViewSize,
                       subviews: Subviews,
                       cache _: inout ())
    {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        let offsets =
            layout(sizes: sizes,
                   spacing: spacing,
                   containerWidth: bounds.width).offsets
        for (offset, subview) in zip(offsets, subviews) {
            subview.place(at: .init(x: offset.x + bounds.minX,
                                    y: offset.y + bounds.minY),
                          proposal: .unspecified)
        }
    }

    func layout(sizes: [CGSize],
                spacing: CGFloat = 8,
                containerWidth: CGFloat) -> (offsets: [CGPoint], size: CGSize)
    {
        var result: [CGPoint] = []
        var currentPosition: CGPoint = .zero
        var lineHeight: CGFloat = 0
        var maxX: CGFloat = 0
        for size in sizes {
            if currentPosition.x + size.width > containerWidth {
                currentPosition.x = 0
                currentPosition.y += lineHeight + spacing
                lineHeight = 0
            }
            result.append(currentPosition)
            currentPosition.x += size.width
            maxX = max(maxX, currentPosition.x)
            currentPosition.x += spacing
            lineHeight = max(lineHeight, size.height)
        }
        return (result,
                .init(width: maxX, height: currentPosition.y + lineHeight))
    }
}

enum SelectAction {
    case view, create, selectEdit, edit, deleted

    var isView: Bool { self == .view }
    var isCreate: Bool { self == .create }
    var isSelectEdit: Bool { self == .selectEdit }
    var isEdit: Bool { self == .edit }
    var deleted: Bool { self == .deleted }
}

enum SelectorStyle {
    case list, grid, inlineList, inlineGrid
}

struct AniButton<Content: View>: View {
    @Environment(\.isEnabled) private var isEnabled
    let action: () -> Void
    @ViewBuilder var label: () -> Content
    @State var clicked: Bool = false

    var backgroundColor: Color {
        return .clear
    }

    var foregroundColor: Color {
        if isEnabled {
            return .white
        } else {
            return .gray
        }
    }

    var body: some View {
        Button {
            withAnimation(.spring) {
                action()
                clicked.toggle()
            }
        } label: {
            label()
        }.padding(5)
            .background(backgroundColor)
            .foregroundStyle(foregroundColor)
    }
}

struct AniToggle<Content: View>: View {
    @Environment(\.isEnabled) private var isEnabled
    @Binding var toggledOn: Bool
    let action: (() -> Void)?
    @ViewBuilder var label: () -> Content
    @State var clicked: Bool = false

    var background: some View {
        Circle().fill(toggledOn ? .white : .clear)
            .frame(width: 4, height: 4)
    }

    var foregroundColor: Color {
        if isEnabled {
            return .white
        } else {
            return .gray
        }
    }

    var body: some View {
        Button {
            withAnimation(.smooth) {
                toggledOn.toggle()
                if let action {
                    action()
                }
            }
        } label: {
            label()
        }.padding(5)
            .background {
                VStack {
                    Spacer()
                    background
                }
            }
            .foregroundStyle(foregroundColor)
            .offset(y: toggledOn ? -8 : 0)
            .scaleEffect(toggledOn ? 1.02 : 1)
    }
}

struct Selector<Content: View, T: Identifiable & Equatable & Selectable>: View {
    @State var style: SelectorStyle = .list
    var emptyIcon: String = "ellipsis"
    var styleButton: Bool = false
    @Binding var selected: [T]
    var all: [T]
    var selectLimit: Int
    var editTForm: ((Binding<[T]>, Binding<SelectAction>, Binding<T?>) -> Content)? = nil
    var isEditable: Bool = true
    var isSearchable: Bool = true
    @State var minimized: Bool = false

    @State var new: T? = nil
    @State var selectAction: SelectAction = .view
    @State var search: String = ""

    @State var editT: T? = nil
    @FocusState var focus: Bool

    var available: [T] { all.filter { !selected.contains($0) } }

    var body: some View {
        if isSearchable || isEditable || available.isNotEmpty || selected.isNotEmpty {
            switch style {
            case .grid, .inlineGrid:
                SelectorGrid(inline: true, emptyIcon: emptyIcon, minimized: $minimized) {
                    topBar
                } content: {
                    if minimized, selected.isEmpty {
                        Image(systemName: emptyIcon)
                            .padding(8)
                    } else {
                        content
                            .background {
                                if minimized {
                                    RoundedRectangle(cornerRadius: 20).stroke(.gray.opacity(0.2))
                                }
                            }
                    }
                }.padding(.horizontal, 8)
            case .list:
                List {
                    topBar
                    content
                }
                .scrollContentBackground(.hidden)
            case .inlineList:
                if !minimized {
                    topBar
                }
                content
            }
        }
    }

    @ViewBuilder
    var content: some View {
        SelectorSection(
            style: style,
            minimized: $minimized,
            selected: $selected,
            editT: $editT,
            all: all,
            selectLimit: selectLimit,
            selectAction: $selectAction,
            search: $search
        )
        .disabled(selectAction.isCreate || (selectAction.isEdit && editT != nil))
        .listRowBackground(Color.clear)
    }

    @ViewBuilder
    var topBar: some View {
        if !minimized, isSearchable || isEditable {
            HStack {
                if style == .inlineGrid, selectAction.isView {
                    AniButton {
                        minimized = true
                    } label: {
                        Image(systemName: "chevron.left")
                    }.buttonStyle(.plain).tint(.white)
                }

                SelectorTopBar(
                    style: $style,
                    search: $search,
                    selectAction: $selectAction,
                    selected: $selected,
                    editT: $editT,
                    editTForm: editTForm,
                    isEditable: isEditable,
                    isSearchable: isSearchable
                )
            }
        }
    }
}

struct SelectorTopBar<Content: View, T: Identifiable & Equatable & Selectable>: View {
    @Binding var style: SelectorStyle
    var styleButton: Bool = false
    @Binding var search: String
    @Binding var selectAction: SelectAction
    @Binding var selected: [T]
    @Binding var editT: T?
    var editTForm: ((Binding<[T]>, Binding<SelectAction>, Binding<T?>) -> Content)? = nil
    var isEditable: Bool
    var isSearchable: Bool

    var hasEditTForm: Bool {
        return editTForm != nil
    }

    var editTSelected: Bool {
        return editT != nil
    }

    var showEditTForm: Bool {
        if hasEditTForm, editTSelected {
            return true
        }

        return false
    }

    @FocusState var focus: Bool

    var body: some View {
        if !showEditTForm {
            HStack {
                if search.isEmpty, hasEditTForm, isEditable {
                    AniButton {
                        if selectAction.isSelectEdit || selectAction.isEdit {
                            selectAction = .view
                        } else {
                            selectAction = .selectEdit
                        }
                    } label: {
                        Image(systemName: selectAction.isSelectEdit || selectAction.isEdit ? "xmark" : "pencil")
                    }
                    .buttonStyle(.plain)
                }

                if isSearchable {
                    TextField("search...", text: $search)
                        .focused($focus)
                        .onAppear {
                            focus = true
                        }
                        .disabled(selectAction.isEdit)
                } else {
                    Spacer()
                }

                if search.isNotEmpty {
                    AniButton {
                        search = ""
                    } label: {
                        Image(systemName: "delete.left")
                    }
                    .buttonStyle(.plain)
                    .disabled(!selectAction.isView)
                } else {
                    if hasEditTForm {
                        AniButton {
                            editT = T.createNew()
                            selectAction = .edit
                        } label: {
                            Image(systemName: "plus")
                        }
                        .buttonStyle(.plain)
                        .disabled(!selectAction.isView)
                    }

                    if styleButton {
                        AniButton {
                            style = style == .grid ? .list : .grid
                        } label: {
                            Image(systemName: style == .grid ? "list.dash" : "square.grid.3x2")
                        }
                        .buttonStyle(.plain)
                        .disabled(!selectAction.isView)
                    }
                }
            }
        } else if let editTForm {
            editTForm($selected, $selectAction, $editT)
        }
    }
}

struct SelectorSection<T: Identifiable & Equatable & Selectable>: View {
    let style: SelectorStyle
    @Binding var minimized: Bool
    @Binding var selected: [T]
    @Binding var editT: T?
    var all: [T]
    var selectLimit: Int

    @Binding var selectAction: SelectAction
    @Binding var search: String

    var available: [T] {
        return all.filter {
            if search.isNotEmpty {
                return !selected.contains($0) && $0.searchable.contains(search)
            }
            return !selected.contains($0)
        }.sorted { first, second in
            if let firstClick = first.lastClicked, let secondClick = second.lastClicked {
                return firstClick > secondClick
            }

            return first.timestamp > second.timestamp
        }
    }

    var filteredSelected: [T] {
        selected.filter {
            if search.isNotEmpty {
                return $0.searchable.contains(search)
            }
            return true
        }.sorted { first, second in
            if let firstClick = first.lastClicked, let secondClick = second.lastClicked {
                return firstClick > secondClick
            }

            return first.timestamp > second.timestamp
        }
    }

    var body: some View {
        switch style {
        case .inlineList, .inlineGrid:
            content
        case .list, .grid:
            sectionContent
        }
    }

    @ViewBuilder
    var content: some View {
        ForEach(filteredSelected) { a in
            AniButton {
                if selectAction.isSelectEdit {
                    editT = a
                    editT?.lastClicked = Date()
                    selectAction = .edit
                } else {
                    selected.removeAll { $0 == a }
                }
                search = ""
            } label: {
                a.editButtonLabel(isEdit: selectAction.isSelectEdit, minimized: minimized)
            }
            .buttonStyle(.plain)
            .background(a.selectedBackground)
            .listRowBackground(Color.clear)
        }

        if !minimized {
            ForEach(available) { a in
                AniButton {
                    if selectAction.isSelectEdit {
                        editT = a
                        editT?.lastClicked = Date()
                        selectAction = .edit
                    } else if selected.count <= selectLimit {
                        selected.append(a)
                    }
                    search = ""
                } label: {
                    a.editButtonLabel(isEdit: selectAction.isSelectEdit, minimized: minimized)
                }
                .background {
                    if selectAction.isSelectEdit {
                        a.selectedBackground
                    }
                }
                .disabled(selected.count == selectLimit)
                .buttonStyle(.plain)
                .listRowBackground(Color.clear)
            }
        }
    }

    @ViewBuilder
    var sectionContent: some View {
        Section {
            content
        }
        .listRowSeparator(.hidden)
        .onChange(of: editT) {
            if editT != nil {
                selectAction = .edit
            }
        }
    }
}

extension Selector where Content == EmptyView {
    init(
        style: SelectorStyle,
        selected: Binding<[T]>,
        all: [T],
        selectAction: SelectAction = .view,
        selectLimit: Int,
        isEditable: Bool = true,
        isSearchable: Bool = true,
        minimized: Bool = false
    ) {
        self.style = style
        _selected = selected
        self.all = all
        self.selectAction = selectAction
        self.selectLimit = selectLimit
        self.isEditable = isEditable
        self.isSearchable = isSearchable
        editTForm = nil
        self.minimized = minimized
    }
}

struct RadialLayout: Layout {
    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews _: Subviews,
        cache _: inout Void
    ) -> CGSize {
        // Use as much space as is available.
        proposal.replacingUnspecifiedDimensions()
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal _: ProposedViewSize,
        subviews: Subviews,
        cache _: inout Void
    ) {
        // Set the radius to fit within the available space.
        let radius = min(bounds.size.width, bounds.size.height) / 2.0

        // Calculate the angle for each view, depending on the total number of views.
        let angle = Angle.degrees(360.0 / Double(subviews.count)).radians

        // Place each view, rotating around the center of the space, with a decreasing radius to create a spiral effect.
        for (index, subview) in subviews.enumerated() {
            var place = CGPoint(x: 0, y: -radius * CGFloat(Float(index)) / 10)
                .applying(CGAffineTransform(
                    rotationAngle: angle * Double(index)))
            place.x += bounds.midX
            place.y += bounds.midY
            subview.place(at: place, anchor: .center, proposal: .unspecified)
        }
    }
}

struct SelectorGrid<TopBarContent: View, Content: View>: View {
    var inline: Bool = false
    var emptyIcon: String = "ellipsis"
    @Binding var minimized: Bool

    var topBar: (() -> TopBarContent)? = nil
    @ViewBuilder var content: () -> Content

    @ViewBuilder
    var section: some View {
        Section {
            if !minimized, let topBar {
                topBar()
                    .listRowBackground(Color.clear)
            }

            HStack {
                HFlow(horizontalAlignment: .leading, verticalAlignment: .center) {
                    content()
                        .allowsHitTesting(!minimized)
                }
                .listRowBackground(Color.clear)
            }
            .frame(height: minimized ? 42 : nil, alignment: .top)
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
        .overlay {
            if minimized {
                AniButton {
                    minimized = false
                } label: {
                    HFlow(horizontalAlignment: .leading, verticalAlignment: .top, justified: !minimized) {
                        content()
                            .allowsHitTesting(!minimized)
                    }
                }.opacity(0)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    var body: some View {
        if inline {
            section
        } else {
            List {
                section
            }
        }
    }
}

extension SelectorGrid where TopBarContent == EmptyView {
    init(
        inline: Bool = false,
        minimized: Binding<Bool>,
        content: @escaping () -> Content
    ) {
        self.inline = inline
        self.content = content
        _minimized = minimized
        topBar = nil
    }
}
