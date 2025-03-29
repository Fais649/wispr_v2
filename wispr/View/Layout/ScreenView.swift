//
//  ScreenView.swift
//  wispr
//
//  Created by Faisal Alalaiwat on 29.03.25.
//

import SwiftUI

protocol ScreenView: View {
    associatedtype Title: View
    associatedtype TrailingTitle: View
    associatedtype Subtitle: View

    var title: Title {get}
    var trailingTitle: TrailingTitle {get}
    var subtitle: Subtitle {get}
}

extension ScreenView {
    var subtitle: some View {
        EmptyView()
    }

    var trailingTitle: some View {
        EmptyView()
    }
}

struct TestScreenView: ScreenView {
    var title: some View {
        Text("Test")
    }
    
    var body: some View {
        Text("Test")
    }
}

struct ScreenOutputView<Screen: ScreenView>: View {
    var screen: Screen
    var body: some View {
        VStack {
            VStack {
                HStack {
                    screen.title
                    Spacer()
                    screen.trailingTitle
                }
                
                screen.subtitle
            }
            
            screen
        }
    }
}

//struct BaseScreenView: ScreenView {
//    var title: some View {
//        Text("Test")
//    }
//    
//    var body: some View {
//        ScreenOutputView(screen: self)
//    }
//}
