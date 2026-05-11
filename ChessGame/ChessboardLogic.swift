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

            // EN PASSANT
            if piece.type == .pawn,
               from.1 != to.1,
               board[to.0][to.1] == nil,
               let captureSquare = enPassantCaptureSquare,
               captureSquare == (from.0, to.1) {

                board[from.0][to.1] = nil
            }
            
            // CASTLING
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

                // square pawn passes through
                enPassantTarget = (
                    (from.0 + to.0) / 2,
                    from.1
                )

                // square of pawn that can be captured via en passant
                enPassantCaptureSquare = to
            } else {
                enPassantTarget = nil
                enPassantCaptureSquare = nil
            }
            
            currentTurn = (currentTurn == .white)
                ? .black
                : .white
            
        }
    }
    
    mutating func promotePendingPawn(to type: PieceType) {
        guard let coords = pendingPromotion else { return }
        
        // Execute the move with the chosen piece type
        executeMove(from: coords.from, to: coords.to, promotionType: type)
        pendingPromotion = nil
    }

    mutating func executeMove(from: (Int, Int), to: (Int, Int), promotionType: PieceType?) {
        guard var movedPiece = board[from.0][from.1] else { return }
        
        // If a promotion type was provided, change the piece
        if let promotionType = promotionType {
            movedPiece = ChessPiece(type: promotionType, color: movedPiece.color)
        }
        
        movedPiece.hasMoved = true
        board[to.0][to.1] = movedPiece
        board[from.0][from.1] = nil
        
        // ... (En Passant / Castling logic stays here) ...

        currentTurn = (currentTurn == .white) ? .black : .white
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

        guard let piece = board[from.0][from.1] else {
            return []
        }

        var safeMoves: [(Int, Int)] = []

        for move in pseudoMoves {

            // Simulate move on temporary board
            var tempBoard = self.board

            // EN PASSANT simulation
            if piece.type == .pawn,
               from.1 != move.1,
               let captureSquare = enPassantCaptureSquare,
               captureSquare == (from.0, move.1) {

                tempBoard[from.0][move.1] = nil
            }
            
            // CASTLING simulation
            if piece.type == .king,
               abs(move.1 - from.1) == 2 {

                // Kingside
                if move.1 == 6 {

                    tempBoard[from.0][5] = tempBoard[from.0][7]
                    tempBoard[from.0][7] = nil
                }

                // Queenside
                else if move.1 == 2 {

                    tempBoard[from.0][3] = tempBoard[from.0][0]
                    tempBoard[from.0][0] = nil
                }
            }

            tempBoard[move.0][move.1] = piece
            tempBoard[from.0][from.1] = nil

            // Find king position after move
            if let kingPos = findKing(
                color: piece.color,
                on: tempBoard
            ) {

                let enemyColor: PieceColor =
                    (piece.color == .white)
                    ? .black
                    : .white

                // If king is NOT attacked, move is safe
                if !isSquareAttacked(
                    row: kingPos.0,
                    col: kingPos.1,
                    by: enemyColor,
                    on: tempBoard
                ) {

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
            
            if let target = enPassantTarget,
               target == (newRow, newCol) {
                legalMoves.append((newRow, newCol))
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
        guard let currentPiece = targetBoard[row][col] else {
            return []
        }

        // Normal king movement
        for dRow in -1...1 {
            for dCol in -1...1 {
                // Skip current square
                if dRow == 0 && dCol == 0 {
                    continue
                }

                let newRow = row + dRow
                let newCol = col + dCol

                // check bouunds (0 to 7)
                if (0..<8).contains(newRow) && (0..<8).contains(newCol) {
                    // Cannot capture own piece
                    if targetBoard[newRow][newCol]?.color != currentPiece.color {
                        legalMoves.append((newRow, newCol))
                    }
                }
            }
        }

        // CASTLING
        if !currentPiece.hasMoved {

            let enemyColor = opposite(currentPiece.color)

            // Kingside castle
            if let rook = targetBoard[row][7],
               rook.type == .rook,
               rook.color == currentPiece.color,
               !rook.hasMoved,
               targetBoard[row][5] == nil,
               targetBoard[row][6] == nil {

                // King cannot castle through check
                if !isSquareAttacked(row: row, col: 4, by: enemyColor, on: targetBoard) &&
                   !isSquareAttacked(row: row, col: 5, by: enemyColor, on: targetBoard) &&
                   !isSquareAttacked(row: row, col: 6, by: enemyColor, on: targetBoard) {

                    legalMoves.append((row, 6))
                }
            }

            // Queenside castle
            if let rook = targetBoard[row][0],
               rook.type == .rook,
               rook.color == currentPiece.color,
               !rook.hasMoved,
               targetBoard[row][1] == nil,
               targetBoard[row][2] == nil,
               targetBoard[row][3] == nil {

                // King cannot castle through check
                if !isSquareAttacked(row: row, col: 4, by: enemyColor, on: targetBoard) &&
                   !isSquareAttacked(row: row, col: 3, by: enemyColor, on: targetBoard) &&
                   !isSquareAttacked(row: row, col: 2, by: enemyColor, on: targetBoard) {

                    legalMoves.append((row, 2))
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

