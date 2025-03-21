//
//  BoardSheet.swift
//  wispr
//
//  Created by Faisal Alalaiwat on 21.03.25.
//

import SwiftUI
import SwiftData

struct BoardSheet: View {
    @Environment(NavigatorService.self) private var nav: NavigatorService
    @Query var boards: [Board]
    @State var editBoards = false
    
    var body: some View {
        List {
            AniButton {
                self.nav.activeBoard.board = nil
                self.nav.activeBoard.showBoard = false
            } label: {
                Text("none_")
            }
            
            Section(
                header:
                    HStack {
                        Text("boards_")
                        Spacer()
                        
                        AniButton {
                            self.editBoards.toggle()
                        } label: {
                            Image(
                                systemName: self
                                    .editBoards ? "checkmark" : "pencil"
                            )
                        }
                    }
            ) {
                ForEach(self.boards.sorted(by: {
                    if
                        let firstClick = $0.lastClicked,
                        let secondClick = $1.lastClicked
                    {
                        return firstClick > secondClick
                    } else {
                        return $0.timestamp < $1.timestamp
                    }
                })) { board in
                    AniButton {
                        if self.editBoards {
                            self.nav.path
                                .append(.boardForm(board: board))
                        } else {
                            self.nav.activeBoard.board = board
                        }
                        self.nav.activeBoard.showBoard = false
                    } label: {
                        HStack {
                            Text(board.name)
                        }
                    }
                }
            }
        }
    }
}
