//
//  ChessBoardLogicHelpers.swift
//  ChessGame
//
//  Created by Student on 5/15/26.
//

extension ChessboardLogic {
    //Helper methods
    func isSquareAttacked(
        row: Int,
        col: Int,
        by color: PieceColor,
        on targetBoard: Board
    ) -> Bool {

        for r in 0..<8 {
            for c in 0..<8 {

                guard let piece = targetBoard[r][c],
                      piece.color == color else { continue }

                switch piece.type {

                case .pawn:
                    let direction = (piece.color == .white) ? -1 : 1

                    for dCol in [-1, 1] {
                        let attackRow = r + direction
                        let attackCol = c + dCol

                        if attackRow == row && attackCol == col {
                            return true
                        }
                    }

                case .knight:
                    if islegalKnight(
                        row: r,
                        col: c,
                        targetBoard: targetBoard
                    ).contains(where: { $0 == (row, col) }) {
                        return true
                    }

                case .bishop:
                    if islegalBishop(
                        row: r,
                        col: c,
                        targetBoard: targetBoard
                    ).contains(where: { $0 == (row, col) }) {
                        return true
                    }

                case .rook:
                    if islegalRook(
                        row: r,
                        col: c,
                        targetBoard: targetBoard
                    ).contains(where: { $0 == (row, col) }) {
                        return true
                    }

                case .queen:
                    if islegalQueen(
                        row: r,
                        col: c,
                        targetBoard: targetBoard
                    ).contains(where: { $0 == (row, col) }) {
                        return true
                    }

                case .king:
                    if max(abs(r - row), abs(c - col)) == 1 {
                        return true
                    }
                }
            }
        }

        return false
    }

    func findKing(color: PieceColor, on targetBoard: Board) -> (Int, Int)? {
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
    
    func isKingInCheck(color: PieceColor, on targetBoard: Board) -> Bool {

        guard let kingPos = findKing(color: color, on: targetBoard) else {
            return false
        }

        return isSquareAttacked(
            row: kingPos.0,
            col: kingPos.1,
            by: opposite(color),
            on: targetBoard
        )
    }
    
    func hasAnyLegalMoves(color: PieceColor) -> Bool {

        for row in 0..<8 {
            for col in 0..<8 {

                guard let piece = board[row][col],
                      piece.color == color else { continue }

                let pseudoMoves = isLegal(
                    row: row,
                    col: col,
                    targetBoard: board
                )

                let safeMoves = isCheckSafe(
                    from: (row, col),
                    pseudoMoves: pseudoMoves
                )

                if !safeMoves.isEmpty {
                    return true
                }
            }
        }

        return false
    }
    
    func isCheckmate(color: PieceColor) -> Bool {

        return isKingInCheck(color: color, on: board)
            && !hasAnyLegalMoves(color: color)
    }
}
