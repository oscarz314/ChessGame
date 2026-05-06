//
//  ChessboardLogic.swift
//  ChessGame
//
//  Created by Student on 4/27/26.
//

import Foundation



typealias Board = [[ChessPiece?]]

struct ChessboardLogic {
    var board: Board = Array(
        repeating: Array(repeating: nil, count: 8),
        count: 8
    )
    
    var currentTurn: PieceColor = .white
    var history: [Board] = []
    var moveNum: Int = 0
    var whiteKingMoved: Bool = false
    var blackKingMoved: Bool = false
    var whiteLeftRookMoved = false
    var whiteRightRookMoved = false
    var blackLeftRookMoved = false
    var blackRightRookMoved = false
    var enPassantTarget: (Int, Int)? = nil
    
    //Property to keep track the previous move for highlighting
    var lastMove: (from: (Int, Int), to: (Int, Int))?
    
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
    
    mutating func setupBoard() {
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
    
    mutating func move(from: (Int, Int), to: (Int, Int)) {
            guard let piece = board[from.0][from.1], piece.color == currentTurn else { return }
            
            let pseudoMoves = isLegal(row: from.0, col: from.1, targetBoard: self.board)
            let legalMoves = isCheckSafe(from: from, pseudoMoves: pseudoMoves)
            
            guard legalMoves.contains(where: { $0 == to }) else { return }
            
            history.append(board)
            
            // EN PASSANT capture
            if piece.type == .pawn, let ep = enPassantTarget, to == ep {
                let direction = (piece.color == .white) ? 1 : -1
                let capturedRow = to.0 + direction
                board[capturedRow][to.1] = nil
            }
            
            board[to.0][to.1] = piece
            board[from.0][from.1] = nil
            
            lastMove = (from, to)
            
            // EN PASSANT: reset by default
            enPassantTarget = nil
            
            // EN PASSANT: set if pawn double moves
            if piece.type == .pawn {
                let startRow = from.0
                let endRow = to.0
                
                if abs(startRow - endRow) == 2 {
                    let middleRow = (startRow + endRow) / 2
                    enPassantTarget = (middleRow, from.1)
                }
            }
            
            currentTurn = (currentTurn == .white) ? .black : .white
            
            if piece.type == .king {
                if piece.color == .white {
                    whiteKingMoved = true
                } else {
                    blackKingMoved = true
                }
                
                //If rook has moved
                if piece.type == .rook {
                    if piece.color == .white {
                        if from == (7,0) { whiteLeftRookMoved = true }
                        if from == (7,7) { whiteRightRookMoved = true }
                    } else {
                        if from == (0,0) { blackLeftRookMoved = true }
                        if from == (0,7) { blackRightRookMoved = true }
                    }
                }
                
                // Handle castling move
                if piece.type == .king {
                    let row = from.0
                    
                    // King side castle
                    if to == (row, 6) {
                        board[row][5] = board[row][7] // move rook
                        board[row][7] = nil
                    }
                    
                    // Queen side castle
                    if to == (row, 2) {
                        board[row][3] = board[row][0] // move rook
                        board[row][0] = nil
                    }
                }
            }
        }

        
    func isLegal(row: Int, col: Int, targetBoard: Board) -> [(Int, Int)] {
            guard let piece = targetBoard[row][col] else { return [] }
            
            switch piece.type {
            case .pawn:
                return islegalPawn(row: row, col: col, targetBoard: targetBoard)
            case .bishop:
                return islegalBishop(row: row, col: col, targetBoard: targetBoard)
            case .knight:
                return islegalKnight(row: row, col: col, targetBoard: targetBoard)
            case .rook:
                return islegalRook(row: row, col: col, targetBoard: targetBoard)
            case .queen:
                return islegalQueen(row: row, col: col, targetBoard: targetBoard)
            case .king:
                return islegalKing(row: row, col: col, targetBoard: targetBoard)
            }
        }
        
    func isCheckSafe(from: (Int, Int), pseudoMoves: [(Int, Int)]) -> [(Int, Int)] {
            guard let piece = board[from.0][from.1] else { return [] }
            var safeMoves: [(Int, Int)] = []

            for move in pseudoMoves {
                // Simulate the move on a temporary board
                var tempBoard = self.board
                tempBoard[move.0][move.1] = piece
                tempBoard[from.0][from.1] = nil

                // Find our King's position on this simulated board
                if let kingPos = findKing(color: piece.color, on: tempBoard) {
                    let enemyColor: PieceColor = (piece.color == .white) ? .black : .white
                    
                    // If the enemy cannot attack the King after this move, it is legal
                    if !isSquareAttacked(row: kingPos.0, col: kingPos.1, by: enemyColor, on: tempBoard) {
                        safeMoves.append(move)
                    }
                }
            }
            return safeMoves
        }

        
    func islegalPawn(row: Int, col: Int, targetBoard:Board) -> [(Int, Int)] {
            var legalMoves: [(Int, Int)] = []
            
            guard let currentPiece = targetBoard[row][col] else { return [] }
            
            let direction = (currentPiece.color == .white) ? -1 : 1
            
            let oneStep = row + direction
            
            // move forward
            if (0..<8).contains(oneStep) && targetBoard[oneStep][col] == nil {
                legalMoves.append((oneStep, col))
                
                // move 2 spaces
                let twoStep = row + 2 * direction
                if (currentPiece.color == .white && row == 6) ||
                   (currentPiece.color == .black && row == 1) {
                    
                    if (0..<8).contains(twoStep) && targetBoard[twoStep][col] == nil {
                        legalMoves.append((twoStep, col))
                    }
                }
            }
            
            // diagonal capture
            for dCol in [-1, 1] {
                let newRow = row + direction
                let newCol = col + dCol
                
                if (0..<8).contains(newRow) && (0..<8).contains(newCol) {
                    if let target = targetBoard[newRow][newCol],
                       target.color != currentPiece.color {
                        legalMoves.append((newRow, newCol))
                    }
                }
            }
        
            // En passant
            for dCol in [-1, 1] {
                let newCol = col + dCol
                let newRow = row + direction
                
                if let target = enPassantTarget {
                    if target == (newRow, newCol) {
                        legalMoves.append((newRow, newCol))
                    }
                }
            }
            
            return legalMoves
        }
        
    func islegalBishop(row: Int, col:Int, targetBoard: Board)-> [(Int, Int)] {
            var legalMoves: [(Int, Int)] = []
            guard let piece = targetBoard[row][col] else { return [] }
            
            //4 diagonal directions: (row change, col change)
            let directions = [(-1,-1), (-1,1), (1,-1), (1,1)]
            
            for dir in directions {
                var nextRow = row + dir.0
                var nextCol = col + dir.1
                
                while (0..<8).contains(nextRow) && (0..<8).contains(nextCol) {
                    if let targetPiece = targetBoard[nextRow][nextCol] {
                        if (targetPiece.color != piece.color) {
                            legalMoves.append((nextRow, nextCol))
                        }
                        //if we hit any piece, we can't slide further
                        break
                    } else {
                        legalMoves.append((nextRow, nextCol))
                        nextRow += dir.0
                        nextCol += dir.1
                    }
                }
            }
            
            return legalMoves
        }
        
    func islegalKnight(row: Int, col:Int, targetBoard: Board)-> [(Int, Int)] {
            var legalMoves: [(Int, Int)] = []
            guard let piece = targetBoard[row][col] else { return [] }
            
            // 8 possible L-shapes the knight can make
        
            let offsets = [
                (-2, -1), (-2, 1),
                (2, -1), (2, 1),
                (-1, -2), (-1, 2),
                (1, -2), (1, 2)
            ]
            
            for offset in offsets {
                let nextRow = row + offset.0
                let nextCol = col + offset.1
                
                if (0..<8).contains(nextRow) && (0..<8).contains(nextCol) {
                    if let targetPiece = targetBoard[nextRow][nextCol] {
                        if targetPiece.color != piece.color {
                            legalMoves.append((nextRow, nextCol))
                        }
                    } else {
                        legalMoves.append((nextRow, nextCol))
                    }
                }
            }
            return legalMoves
        }
        
    func islegalRook(row: Int, col:Int, targetBoard: Board)-> [(Int, Int)] {
            var legalMoves: [(Int, Int)] = []
            guard let piece = targetBoard[row][col] else { return [] }
            
            // RIGHT
            var c = col + 1
            while c < 8 {
                if let target = targetBoard[row][c] {
                    if target.color != piece.color {
                        legalMoves.append((row, c))
                    }
                    break
                }
                legalMoves.append((row, c))
                c += 1
            }
            
            // LEFT
            c = col - 1
            while c >= 0 {
                if let target = targetBoard[row][c] {
                    if target.color != piece.color {
                        legalMoves.append((row, c))
                    }
                    break
                }
                legalMoves.append((row, c))
                c -= 1
            }
            
            // DOWN
            var r = row + 1
            while r < 8 {
                if let target = targetBoard[r][col] {
                    if target.color != piece.color {
                        legalMoves.append((r, col))
                    }
                    break
                }
                legalMoves.append((r, col))
                r += 1
            }
            
            // UP
            r = row - 1
            while r >= 0 {
                if let target = targetBoard[r][col] {
                    if target.color != piece.color {
                        legalMoves.append((r, col))
                    }
                    break
                }
                legalMoves.append((r, col))
                r -= 1
            }
            
            return legalMoves
        }
        
    func islegalQueen(row: Int, col:Int, targetBoard: Board)-> [(Int, Int)] {
            
            let legalMovesRook = islegalRook(row: row, col: col, targetBoard: targetBoard)
            let legalMovesBishop = islegalBishop(row: row, col: col, targetBoard: targetBoard)
            
            // Queen's movment = rook moves + bishop moves
            let legalMoves = legalMovesRook + legalMovesBishop
            
            return legalMoves
        }
        
    func islegalKing(row: Int, col:Int, targetBoard: Board) -> [(Int, Int)] {
            var legalMoves: [(Int, Int)] = []
            let currentPiece = targetBoard[row][col]
            
            for dRow in -1...1 {
                for dCol in -1...1 {
                    // Skip the current square
                    if dRow == 0 && dCol == 0 { continue }
                    
                    let newRow = row + dRow
                    let newCol = col + dCol
                    
                    // Check bounds (0 to 7)
                    if newRow >= 0 && newRow < 8 && newCol >= 0 && newCol < 8 {
                        if targetBoard[newRow][newCol]?.color != currentPiece?.color {
                            legalMoves.append((newRow, newCol))
                        }
                    }
                }
            }
        
        // Castling
        if let piece = currentPiece {
            let row = (piece.color == .white) ? 7 : 0
            
            // Checks king moved based on color
            let kingMoved = (piece.color == .white) ? whiteKingMoved : blackKingMoved
            
            if !kingMoved && row == row {
                
                // king side short castle
                let rookMovedRight = (piece.color == .white) ? whiteRightRookMoved : blackRightRookMoved
                
                if !rookMovedRight &&
                   targetBoard[row][5] == nil &&
                   targetBoard[row][6] == nil {
                    
                    // squares not attacked
                    if !isSquareAttacked(row: row, col: 4, by: opposite(piece.color), on: targetBoard) &&
                       !isSquareAttacked(row: row, col: 5, by: opposite(piece.color), on: targetBoard) &&
                       !isSquareAttacked(row: row, col: 6, by: opposite(piece.color), on: targetBoard) {
                        
                        legalMoves.append((row, 6))
                    }
                }
                
                // queen side long castle
                let rookMovedLeft = (piece.color == .white) ? whiteLeftRookMoved : blackLeftRookMoved
                
                if !rookMovedLeft &&
                   targetBoard[row][1] == nil &&
                   targetBoard[row][2] == nil &&
                   targetBoard[row][3] == nil {
                    
                    // squares not attacked
                    if !isSquareAttacked(row: row, col: 4, by: opposite(piece.color), on: targetBoard) &&
                       !isSquareAttacked(row: row, col: 3, by: opposite(piece.color), on: targetBoard) &&
                       !isSquareAttacked(row: row, col: 2, by: opposite(piece.color), on: targetBoard) {
                        
                        legalMoves.append((row, 2))
                    }
                }
            }
        }
            
        
            return legalMoves
        }
    
    mutating func moveAndPromote(from: (Int, Int), to: (Int, Int), promoteTo: PieceType) {

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

        currentTurn = (currentTurn == .white) ? .black : .white
    }
    
    //Helper methods
    func isSquareAttacked(row: Int, col: Int, by color: PieceColor, on targetBoard: Board) -> Bool {
        
        for r in 0..<8 {
            for c in 0..<8 {
                guard let piece = targetBoard[r][c], piece.color == color else { continue }
                
                if piece.type == .pawn {
                    let direction = (piece.color == .white) ? -1 : 1
                    
                    for dCol in [-1, 1] {
                        let attackRow = r + direction
                        let attackCol = c + dCol
                        
                        if attackRow == row && attackCol == col {
                            return true
                        }
                    }
                    
                } else {
                    let attacks = isLegal(row: r, col: c, targetBoard: targetBoard)
                    
                    if attacks.contains(where: { $0 == (row, col) }) {
                        return true
                    }
                }
            }
        }
        
        return false
    }

   private func findKing(color: PieceColor, on targetBoard: Board) -> (Int, Int)? {
          for r in 0..<8 {
              for c in 0..<8 {
                  if let p = targetBoard[r][c], p.type == .king, p.color == color {
                      return (r, c)
                  }
              }
          }
          return nil
      }
    
    func opposite(_ color: PieceColor) -> PieceColor {
        return color == .white ? .black : .white
    }

}

