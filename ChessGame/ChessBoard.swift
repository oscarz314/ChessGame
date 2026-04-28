//
//  ChessBoard.swift
//  ChessGame
//
//  Created by Student on 4/27/26.
//

import Foundation
import SwiftUI

struct ChessBoard: View {
    //Board size 8 by 8
    let size = 8
    
    @State private var game = ChessboardLogic()

    //Current piece
    @State private var selectedPiece: (piece: ChessPiece, row: Int, col: Int)?
    @State private var dragOffset: CGSize = .zero
    
    var body: some View {
        HStack{
            GeometryReader{ geo in
                //Geometry reader used to read the board size and square size relative to the grid
                let boardSize = min(geo.size.width, geo.size.height)
                let squareSize = boardSize / CGFloat(size)
                
                ZStack(alignment: .topLeading) {
                    // Make grid
                    Grid(horizontalSpacing: 0, verticalSpacing: 0) {
                        ForEach(0..<size, id: \.self) { row in
                            GridRow {
                                ForEach(0..<size, id: \.self) { column in
                                    Rectangle()
                                        .fill(isDark(row: row, col: column) ? Color.green : Color.white)
                                        .aspectRatio(1, contentMode: .fit)
                                }
                            }
                        }
                        
                    }
                    .border(Color.black, width: 2)
                    
                    //Pieces
                    ForEach(game.activePieces, id: \.piece.id) { item in
                        let isSelected = selectedPiece?.piece.id == item.piece.id
                        
                        Image(item.piece.imageName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: squareSize, height: squareSize)
                            .position(
                                x: CGFloat(item.col) * squareSize + (squareSize / 2) + (isSelected ? dragOffset.width : 0),
                                y: CGFloat(item.row) * squareSize + (squareSize / 2) + (isSelected ? dragOffset.height : 0)
                            )
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        selectedPiece = item
                                        dragOffset = value.translation
                                    }
                                    .onEnded { value in
                                        handleDrop(item: item, translation: value.translation, squareSize: squareSize)
                                        dragOffset = .zero
                                        selectedPiece = nil
                                    }
                            )
                    }
                }
                .frame(width: boardSize, height: boardSize)
            }
            .aspectRatio(1, contentMode: .fit)
            .padding()
        }
    }
    
    //Decide which square is dark
    func isDark(row: Int, col: Int) -> Bool {
            return (row + col) % 2 != 0
        }
    
    //Drag and drop pieces
    func handleDrop(item: (piece: ChessPiece, row: Int, col: Int),
                    translation: CGSize,
                    squareSize: CGFloat) {
        
        let colChange = Int((translation.width / squareSize).rounded())
        let rowChange = Int((translation.height / squareSize).rounded())
        
        let newRow = item.row + rowChange
        let newCol = item.col + colChange
        
        // Stay inside board
        guard newRow != item.row || newCol != item.col else { return }

        guard (0..<8).contains(newRow), (0..<8).contains(newCol) else { return }
        
        game.move(from: (item.row, item.col), to: (newRow, newCol))
    }
}

#Preview {
    ChessBoard()
}
