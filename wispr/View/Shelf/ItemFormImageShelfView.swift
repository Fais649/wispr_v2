
//
//  ItemFormImageShelfView.swift
//  wispr
//
//  Created by Faisal Alalaiwat on 21.03.25.
//

import PhotosUI
import SwiftData
import SwiftUI

struct ItemFormImageShelfView: View {
    @Environment(
        NavigationStateService
            .self
    ) private var navigationStateService: NavigationStateService
    @Environment(BookStateService.self) private var bookState: BookStateService
    @Environment(ThemeStateService.self) private var theme: ThemeStateService
    @Environment(\.dismiss) var dismiss

    @ViewBuilder
    func title() -> some View {
        Text("Photos")
    }

    @ViewBuilder
    func trailingTitle() -> some View {
        ToolbarButton {
            PhotosPicker(
                selection: $imageItems,
                matching: .images,
                photoLibrary: .shared()
            ) {
                Image(
                    systemName: "photo.badge.plus"
                )
            }
        }
    }

    @Binding var imageItems: [PhotosPickerItem]
    @Binding var imageData: [ImageData]
    @Binding var preloaded: Bool
    @Binding var preloadedImages: [UIImage]
    var imageTransition: Namespace.ID

    var body: some View {
        Screen(
            .imageShelf,
            loaded: preloaded,
            title: title,
            trailingTitle: trailingTitle,
            footer: {
                ToolbarButton {
                    imageData.removeAll()
                    imageItems.removeAll()
                } label: {
                    HStack {
                        Spacer()
                        Image(systemName: "xmark")
                        Text("Remove All")
                        Spacer()
                    }
                    .padding(Spacing.m)
                    .foregroundStyle(.black)
                    .background(.red)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        ) {
            ScrollView(.horizontal) {
                LazyHStack {
                    ForEach(
                        Array(preloadedImages.enumerated()),
                        id: \.offset
                    ) { _, uiImage in
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .cornerRadius(Spacing.m)
                            .containerRelativeFrame(
                                .horizontal
                            )
                    }
                }
            }.scrollTargetLayout()
        }
        .scrollIndicators(.hidden)
        .scrollTargetBehavior(.paging)
        .contentMargins(20)
        .shelfScreenStyle([.fraction(0.5)])
    }
}
