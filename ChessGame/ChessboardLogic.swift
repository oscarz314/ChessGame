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
            lastMove = (from, to)
            
            // Gets pseudo legal moves based on piece type and location
            let pseudoMoves = isLegal(row: from.0, col: from.1, targetBoard: self.board)
            
            //Filter for if the move puts King safety at risk (Pins, etc.)
            let legalMoves = isCheckSafe(from: from, pseudoMoves: pseudoMoves)
            
            // Checks if we have a list of legal moves for the selected piece
            if legalMoves.contains(where: { $0 == to }) {
                history.append(board)
                board[to.0][to.1] = piece
                board[from.0][from.1] = nil
                currentTurn = (currentTurn == .white) ? .black : .white
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
                (-2, -1), (-2,1),
                (2,-1), (2,1),
                (-1,-2), (1,-2),
                (-1,2), (1,2)
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
                  if let piece = targetBoard[r][c], piece.color == color {
                      // We check if the enemy piece can reach this square geometrically
                      let attacks = isLegal(row: r, col: c, targetBoard: targetBoard)
                      if attacks.contains(where: { $0.0 == row && $0.1 == col }) {
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

}

