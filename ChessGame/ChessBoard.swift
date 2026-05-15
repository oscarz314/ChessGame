//
//  ChessBoard.swift
//  ChessGame
//
//  Created by Student on 4/27/26.
//

//
//  ChessBoard.swift
//  ChessGame
//

import Foundation
import SwiftUI

struct ChessBoard: View {

    let size = 8
    let botLevel: Int

    @State private var showingPromotionSelection = false
    @StateObject private var game = ChessboardLogic()

    @State private var selectedPiece: (
        piece: ChessPiece,
        row: Int,
        col: Int
    )?
    
    @State private var checkmateAnimationTrigger = false
    @State private var dragOffset: CGSize = .zero

    var legalMovesForSelected: [(Int, Int)] {

        guard let selected = selectedPiece else {
            return []
        }

        let legalMoves = game.isLegal(
            row: selected.row,
            col: selected.col,
            targetBoard: game.board
        )

        return game.isCheckSafe(
            from: (selected.row, selected.col),
            pseudoMoves: legalMoves
        )
    }

    var body: some View {

        VStack {

            Text("Current Turn: \(game.currentTurn.rawValue.capitalized)")
            
            if !game.gameState.isEmpty {
                Text(game.gameState)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(
                        game.gameState == "Checkmate"
                        ? .red
                        : .orange
                    )
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black.opacity(0.1))
                )
            }
            
            HStack {

                GeometryReader { geo in

                    let boardSize = min(
                        geo.size.width,
                        geo.size.height
                    )

                    let squareSize = boardSize / CGFloat(size)

                    ZStack(alignment: .topLeading) {

                        // BOARD GRID
                        Grid(
                            horizontalSpacing: 0,
                            verticalSpacing: 0
                        ) {

                            ForEach(0..<size, id: \.self) { row in

                                GridRow {

                                    ForEach(0..<size, id: \.self) { column in

                                        let lastFrom = game.lastMove?.from
                                        let lastTo = game.lastMove?.to

                                        let isLastMove =
                                            (row == lastFrom?.0 && column == lastFrom?.1)
                                            ||
                                            (row == lastTo?.0 && column == lastTo?.1)

                                        Rectangle()
                                            .fill(
                                                isLastMove
                                                ? Color.yellow.opacity(0.6)
                                                : isDark(row: row, col: column)
                                                    ? Color.green
                                                    : Color.white
                                            )
                                            .aspectRatio(
                                                1,
                                                contentMode: .fit
                                            )
                                            .overlay(
                                                ZStack {

                                                    // SELECTED HIGHLIGHT
                                                    if selectedPiece?.row == row &&
                                                        selectedPiece?.col == column {

                                                        Color.blue.opacity(0.4)
                                                    }

                                                    // LEGAL MOVE HIGHLIGHT
                                                    if legalMovesForSelected.contains(
                                                        where: { $0 == (row, column) }
                                                    ) {

                                                        if game.board[row][column] != nil {

                                                            Circle()
                                                                .stroke(
                                                                    Color.black,
                                                                    lineWidth: 4
                                                                )
                                                                .padding(6)

                                                        } else {

                                                            Circle()
                                                                .fill(Color.blue)
                                                                .frame(
                                                                    width: 20,
                                                                    height: 20
                                                                )
                                                        }
                                                    }
                                                }
                                            )
                                            .onTapGesture {
                                                handleTapMove(
                                                    row: row,
                                                    col: column
                                                )
                                            }
                                    }
                                }
                            }
                        }
                        .border(Color.black, width: 2)

                        // PIECES
                        ForEach(game.activePieces, id: \.piece.id) { item in

                            let isSelected =
                                selectedPiece?.piece.id == item.piece.id
                            let isKing = item.piece.type == .king
                            let isCheckmate = game.gameState == "Checkmate"

                            Image(item.piece.imageName)
                                .resizable()
                                .scaledToFit()
                                .frame(
                                    width: squareSize,
                                    height: squareSize
                                )
                                .rotationEffect(
                                        (isKing && isCheckmate && checkmateAnimationTrigger)
                                        ? Angle.degrees(360)
                                        : Angle.degrees(0)
                                    )
                                .animation(
                                    isKing && isCheckmate
                                    ? .linear(duration: 1.2).repeatForever(autoreverses: false)
                                    : .default,
                                    value: checkmateAnimationTrigger
                                )
                                .zIndex(
                                    selectedPiece?.piece.id == item.piece.id
                                    ? 1
                                    : 0
                                )
                                .position(
                                    x: CGFloat(item.col) * squareSize
                                        + (squareSize / 2)
                                        + (isSelected
                                            ? dragOffset.width
                                            : 0),

                                    y: CGFloat(item.row) * squareSize
                                        + (squareSize / 2)
                                        + (isSelected
                                            ? dragOffset.height
                                            : 0)
                                )
                                .onTapGesture {

                                    handleTapMove(
                                        row: item.row,
                                        col: item.col
                                    )
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

                                                handleDrop(
                                                    item: item,
                                                    translation: value.translation,
                                                    squareSize: squareSize
                                                )

                                                dragOffset = .zero
                                                selectedPiece = nil
                                            }
                                        }
                                )
                        }
                    }
                    .frame(
                        width: boardSize,
                        height: boardSize
                    )
                }
                .aspectRatio(1, contentMode: .fit)
                .padding()
            }
        }
        .onChange(of: game.gameState) { _, newValue in
                if newValue == "Checkmate" {
                    withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                        checkmateAnimationTrigger = true
                    }
                } else {
                    checkmateAnimationTrigger = false
                }
            }
        
        .confirmationDialog(
            "Promote Pawn",
            isPresented: $showingPromotionSelection,
            titleVisibility: .visible
        ) {

            Button("Queen") {
                promote(to: .queen)
            }

            Button("Knight") {
                promote(to: .knight)
            }

            Button("Rook") {
                promote(to: .rook)
            }

            Button("Bishop") {
                promote(to: .bishop)
            }

            Button("Cancel", role: .cancel) {
                game.pendingPromotion = nil
            }
        }
    }

    func isDark(row: Int, col: Int) -> Bool {
        return (row + col) % 2 != 0
    }

    func handleUserMove(
        from: (Int, Int),
        to: (Int, Int)
    ) {

        // Execute player's move
        game.move(from: from, to: to)

        // Promotion UI for human player
        if game.pendingPromotion != nil {

            showingPromotionSelection = true
            return
        }
        

        // If turn switched to black, ask bot for move
        if game.currentTurn == .black {

            let currentFEN = game.generateFEN()

            print("FEN:", currentFEN)

            ChessNetworkService.shared.fetchBotMove(
                fen: currentFEN,
                botLevel: botLevel
            ) { response in

                guard let response = response else {

                    print("Bot failed to respond")
                    return
                }

                DispatchQueue.main.async {

                    // Extract promotion piece from move string
                    var promotionPiece: String? = nil

                    if let move = response.move,
                       move.count == 5 {

                        promotionPiece = String(move.last!)
                    }

                    game.executeBotMove(
                        fromUCI: response.from,
                        toUCI: response.to,
                        promotion: promotionPiece
                    )
                    
                    game.evaluateGameState()

                    // Optional debugging
                    print("Bot Move: \(response.from) -> \(response.to)")
                }
            }
        }
    }

    func handleDrop(
        item: (
            piece: ChessPiece,
            row: Int,
            col: Int
        ),
        translation: CGSize,
        squareSize: CGFloat
    ) {

        let colChange = Int(
            (translation.width / squareSize).rounded()
        )

        let rowChange = Int(
            (translation.height / squareSize).rounded()
        )

        let newRow = item.row + rowChange
        let newCol = item.col + colChange

        guard (0..<8).contains(newRow),
              (0..<8).contains(newCol),
              (newRow != item.row || newCol != item.col)
        else {

            dragOffset = .zero
            return
        }

        handleUserMove(
            from: (item.row, item.col),
            to: (newRow, newCol)
        )

        dragOffset = .zero
        selectedPiece = nil
    }

    func handleTapMove(row: Int, col: Int) {

        guard let selected = selectedPiece else {

            if let piece = game.board[row][col],
               piece.color == game.currentTurn {

                selectedPiece = (
                    piece,
                    row,
                    col
                )
            }

            return
        }

        let from = (
            selected.row,
            selected.col
        )

        let to = (row, col)

        let pseudoMoves = game.isLegal(
            row: selected.row,
            col: selected.col,
            targetBoard: game.board
        )

        let legalMoves = game.isCheckSafe(
            from: from,
            pseudoMoves: pseudoMoves
        )

        guard legalMoves.contains(
            where: { $0 == to }
        ) else {

            if let newPiece = game.board[row][col],
               newPiece.color == game.currentTurn {

                selectedPiece = (
                    newPiece,
                    row,
                    col
                )

            } else {

                selectedPiece = nil
            }

            return
        }

        handleUserMove(
            from: from,
            to: to
        )

        selectedPiece = nil
    }

    func promote(to type: PieceType) {

        game.promotePendingPawn(to: type)

        selectedPiece = nil
        showingPromotionSelection = false
    }
}

#Preview {
    ChessBoard(botLevel: 3)
}

