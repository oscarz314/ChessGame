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
    @State private var showingPromotionSelection = false
    @State private var pendingPromotion: (from: (row: Int, col: Int), to: (row: Int, col: Int))?
    @State private var game = ChessboardLogic()
    
    //Current piece
    @State private var selectedPiece: (piece: ChessPiece, row: Int, col: Int)?
    @State private var dragOffset: CGSize = .zero
    
    var legalMovesForSelected: [(Int, Int)] {
        guard let selected = selectedPiece else { return [] }
        return game.isLegal(row: selected.row, col: selected.col)
    }
    
    var body: some View {
        VStack {
            Text("Current Turn: \(game.currentTurn.rawValue.capitalized)")
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
                                                                            
                                        //check if this square is part of the previous move
                                        let lastFrom = game.lastMove?.from
                                        let lastTo = game.lastMove?.to
                                                                            
                                        let isLastMove = (row == lastFrom?.0 && column == lastFrom?.1) || (row == lastTo?.0 && column == lastTo?.1)
                                                                            
                                        Rectangle()
                                        // if it's the previous move, use yellow, otherwise use the board pattern
                                        .fill(isLastMove ? Color.yellow.opacity(0.6) : isDark(row: row, col: column) ? Color.green : Color.white)
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
                                .zIndex(selectedPiece?.piece.id == item.piece.id ? 1 : 0)
                                .position(
                                    x: CGFloat(item.col) * squareSize + (squareSize / 2) + (isSelected ? dragOffset.width : 0),
                                    y: CGFloat(item.row) * squareSize + (squareSize / 2) + (isSelected ? dragOffset.height : 0)
                                )
                                .onTapGesture {
                                    if (item.piece.color == game.currentTurn) {
                                        selectedPiece = item
                                    }
                                    handleTapMove(row: item.row, col: item.col)
                                }
                                .gesture(
                                    DragGesture()
                                        .onChanged { value in
                                            if item.piece.color == game.currentTurn {
                                                selectedPiece = item
                                                dragOffset = value.translation
                                            }
                                        }
                                        .onEnded { value in
                                            if selectedPiece != nil {
                                                handleDrop(item: item, translation: value.translation, squareSize: squareSize)
                                                dragOffset = .zero
                                                selectedPiece = nil
                                            }
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
        .confirmationDialog("Promote Pawn", isPresented: $showingPromotionSelection, titleVisibility: .visible) {
            Button("Queen") { promote(to: .queen) }
            Button("Knight") { promote(to: .knight) }
            Button("Rook") { promote(to: .rook) }
            Button("Bishop") { promote(to: .bishop) }
            Button("Cancel", role: .cancel) { pendingPromotion = nil }
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
            guard (0..<8).contains(newRow), (0..<8).contains(newCol) else { return }
            guard newRow != item.row || newCol != item.col else { return }
            
            if item.piece.type == .pawn && (newRow == 0 || newRow == 7) {
                game.move(from: (item.row, item.col), to: (newRow, newCol))
                
                pendingPromotion = (from: (newRow, newCol), to: (newRow, newCol))
                showingPromotionSelection = true
            } else {
                game.move(from: (item.row, item.col), to: (newRow, newCol))
            }
                        
        
    }
    
    func handleTapMove(row: Int, col: Int) {
        
        // If a piece is already selected → try to move
        if let selected = selectedPiece {
            
            let legalMoves = game.isLegal(row: selected.row, col: selected.col)
            
            // If tapped square is a legal move → move
            if legalMoves.contains(where: { $0 == (row, col) }) {
                game.move(from: (selected.row, selected.col), to: (row, col))
                selectedPiece = nil
                return
            }
            
            // If tapping another piece of same color → switch selection
            if let newPiece = game.board[row][col],
               newPiece.color == game.currentTurn {
                selectedPiece = (newPiece, row, col)
                return
            }
            
            // Otherwise deselect
            selectedPiece = nil
        }
        
        // If nothing selected → select piece
        else {
            if let piece = game.board[row][col],
               piece.color == game.currentTurn {
                selectedPiece = (piece, row, col)
            }
        }
    }
    
    func promote(to type: PieceType) {
            if let move = pendingPromotion {
                game.board[move.to.row][move.to.col] = ChessPiece(type: type, color: move.to.row == 0 ? .white : .black)
            }
            pendingPromotion = nil
        }
}

#Preview {
    ChessBoard()
}
