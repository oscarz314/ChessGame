//
//  ChessboardLogic.swift
//  ChessGame
//
//  Created by Student on 4/27/26.
//

import Foundation
import Combine


typealias Board = [[ChessPiece?]]

class ChessboardLogic: ObservableObject {
    @Published var board: Board = Array(
        repeating: Array(repeating: nil, count: 8),
        count: 8
    )
    @Published var gameState: String = ""
    @Published var gameOver: Bool = false
    
    var currentTurn: PieceColor = .white
    var history: [Board] = []
    var moveNum: Int = 0
    var enPassantTarget: (Int, Int)? = nil
    var enPassantCaptureSquare: (Int, Int)? = nil
    var pendingPromotion: (from: (Int, Int), to: (Int, Int))?
    
    //Property to keep track the previous move for highlighting
    var lastMove: (
        from: (Int, Int),
        to: (Int, Int),
        piece: ChessPiece
    )?

    
    init() {
        setupBoard()
    }
    
    var activePieces: [(piece: ChessPiece, row: Int, col: Int)] {
        var list: [(piece: ChessPiece, row: Int, col: Int)] = []
        for row in 0..<8 {
            for col in 0..<8 {
                if let piece = board[row][col] {
                    list.append((piece, row, col))
                }
            }
        }
        return list
    }
    
    func setupBoard() {
        
        let backRow: [PieceType] = [
            .rook, .knight, .bishop, .queen,
            .king, .bishop, .knight, .rook
        ]
        
        for col in 0..<8 {
            board[0][col] = ChessPiece(type: backRow[col], color: .black)
            board[1][col] = ChessPiece(type: .pawn, color: .black)
            board[6][col] = ChessPiece(type: .pawn, color: .white)
            board[7][col] = ChessPiece(type: backRow[col], color: .white)
        }
    }
    
    func move(from: (Int, Int), to: (Int, Int)) {
        
        if gameOver { return }
        
        guard let piece = board[from.0][from.1],
              piece.color == currentTurn else { return }

        // Gets pseudo legal moves based on piece type and location
        let pseudoMoves = isLegal(
            row: from.0,
            col: from.1,
            targetBoard: self.board
        )

        // Filter for if the move puts King safety at risk
        let legalMoves = isCheckSafe(
            from: from,
            pseudoMoves: pseudoMoves
        )

        // Checks if move is legal
        if legalMoves.contains(where: { $0 == to }) {
            
            if piece.type == .pawn {

                let promotionRank =
                    (piece.color == .white && to.0 == 0) ||
                    (piece.color == .black && to.0 == 7)

                if promotionRank {
                    pendingPromotion = (from: from, to: to)
                    return
                }
            }
            
            history.append(board)

            // En passant
            if piece.type == .pawn,
               from.1 != to.1,
               board[to.0][to.1] == nil,
               let captureSquare = enPassantCaptureSquare,
               captureSquare == (from.0, to.1) {

                board[from.0][to.1] = nil
            }
            
            // Castling
            if piece.type == .king,
               abs(to.1 - from.1) == 2 {

                // Kingside
                if to.1 == 6 {

                    board[from.0][5] = board[from.0][7]
                    board[from.0][7] = nil

                    board[from.0][5]?.hasMoved = true
                }

                // Queenside
                else if to.1 == 2 {

                    board[from.0][3] = board[from.0][0]
                    board[from.0][0] = nil

                    board[from.0][3]?.hasMoved = true
                }
            }

            var movedPiece = piece
            movedPiece.hasMoved = true

            board[to.0][to.1] = movedPiece
                    
            board[from.0][from.1] = nil

            lastMove = (
                from: from,
                to: to,
                piece: movedPiece
            )
            
            // Set en passant target
            if piece.type == .pawn && abs(to.0 - from.0) == 2 {

                let targetSquare = (
                    (from.0 + to.0) / 2,
                    from.1
                )

                let enemyColor = opposite(piece.color)

                var canBeCaptured = false

                // Check left/right adjacent squares for enemy pawns
                for dCol in [-1, 1] {

                    let adjacentCol = to.1 + dCol

                    if (0..<8).contains(adjacentCol),
                       let adjacentPiece = board[to.0][adjacentCol],
                       adjacentPiece.type == .pawn,
                       adjacentPiece.color == enemyColor {

                        canBeCaptured = true
                    }
                }

                if canBeCaptured {
                    enPassantTarget = targetSquare
                    enPassantCaptureSquare = to
                } else {
                    enPassantTarget = nil
                    enPassantCaptureSquare = nil
                }

            } else {

                enPassantTarget = nil
                enPassantCaptureSquare = nil
            }
            
            currentTurn = (currentTurn == .white)
                ? .black
                : .white
            
        }
    }
    
    // Misc
    
     func promotePendingPawn(to type: PieceType) {
        guard let coords = pendingPromotion else { return }
        
        // Execute the move with the chosen piece type
        executeMove(from: coords.from, to: coords.to, promotionType: type)
        pendingPromotion = nil
    }

     func executeMove(from: (Int, Int), to: (Int, Int), promotionType: PieceType?) {
        guard var movedPiece = board[from.0][from.1] else { return }
        
        // If a promotion type was provided, change the piece
        if let promotionType = promotionType {
            movedPiece = ChessPiece(type: promotionType, color: movedPiece.color)
        }
        
        movedPiece.hasMoved = true
        board[to.0][to.1] = movedPiece
        board[from.0][from.1] = nil
        
        // ... (En Passant / Castling logic stays here) ...

         currentTurn = opposite(currentTurn)

         evaluateGameState()
     }
        
    
    func evaluateGameState() {
        if isCheckmate(color: currentTurn) {
            gameState = "Checkmate"
            gameOver = true
        } else if isStalemate(color: currentTurn) {
            gameState = "Stalemate"
            gameOver = true
        } else if isKingInCheck(
            color: currentTurn,
            on: board
        ) {
            gameState = "Check"
            gameOver = false
        } else {
            gameState = ""
            gameOver = false
        }
    }
    
     func moveAndPromote(from: (Int, Int), to: (Int, Int), promoteTo: PieceType) {

        guard let piece = board[from.0][from.1],
              piece.color == currentTurn,
              piece.type == .pawn else { return }

        // must reach last rank
        let isPromotionRank =
            (piece.color == .white && to.0 == 0) ||
            (piece.color == .black && to.0 == 7)

        guard isPromotionRank else { return }

        let pseudoMoves = isLegal(row: from.0, col: from.1, targetBoard: board)
        let legalMoves = isCheckSafe(from: from, pseudoMoves: pseudoMoves)

        guard legalMoves.contains(where: { $0 == to }) else { return }

        history.append(board)

        // Only allow valid promotions
        guard [.queen, .rook, .bishop, .knight].contains(promoteTo) else { return }

        let promotedPiece = ChessPiece(type: promoteTo, color: piece.color)

        board[to.0][to.1] = promotedPiece
        board[from.0][from.1] = nil

         
        currentTurn = opposite(currentTurn)
         
        evaluateGameState()
    }
}

