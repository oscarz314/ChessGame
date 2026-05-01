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
            guard let piece = board[from.0][from.1] else { return }
            
            // Only move if correct turn
            guard piece.color == currentTurn else { return }
            
            let legalMoves = isLegal(row: from.0, col: from.1)
            
            if legalMoves.contains(where: { $0 == to }) {
                history.append(board)
                
                lastMove = (from, to)
                
                board[to.0][to.1] = piece
                board[from.0][from.1] = nil
                
                currentTurn = (currentTurn == .white) ? .black : .white
            }
        }

    func isLegal(row: Int, col: Int) -> [(Int, Int)] {
        guard let piece = board[row][col] else { return [] }
        
        switch piece.type {
        case .pawn:
            return islegalPawn(row: row, col: col)
        case .bishop:
            return islegalBishop(row: row, col: col)
        case .knight:
            return islegalKnight(row: row, col: col)
        case .rook:
            return islegalRook(row: row, col: col)
        case .queen:
            return islegalQueen(row: row, col: col)
        case .king:
            return islegalKing(row: row, col: col)
        }
    }
    
    func islegalPawn(row: Int, col:Int) -> [(Int, Int)] {
        var legalMoves: [(Int, Int)] = []
        let currentPiece = board[row][col]
        var moveDirection: Int

        //Determine move direction
        if (currentPiece?.color == .white){
            moveDirection = 1
        }
        else{
            moveDirection = -1
        }
        
        // Check if can move twice else check once
        if (row == 6 || row == 1){
            if(board[row - (2 * moveDirection)][col] == nil){
                legalMoves.append((row - (2 * moveDirection), col))
            }
        }
        
        // Check moving forwards
        if(board[row - (1 * moveDirection)][col] == nil){
            legalMoves.append((row - (1 * moveDirection), col))
        }
        
        // Check if can capture sideways
        if(col + 1 <= 7 && board[row - (1 * moveDirection)][col + 1] != nil && board[row - (1 * moveDirection)][col + 1]?.color != currentPiece?.color){ // Check right side
            legalMoves.append((row - (1 * moveDirection), col + 1))
        }
        
        if(col - 1 >= 0 && board[row - (1 * moveDirection)][col - 1] != nil && board[row - (1 * moveDirection)][col - 1]?.color != currentPiece?.color){ // Check left side
            legalMoves.append((row - (1 * moveDirection), col - 1))
        }
        
        return legalMoves
    }
    
    func islegalBishop(row: Int, col:Int)-> [(Int, Int)] {
        var legalMoves: [(Int, Int)] = []
        guard let piece = board[row][col] else { return [] }
        
        //4 diagonal directions: (row change, col change)
        let directions = [(-1,-1), (-1,1), (1,-1), (1,1)]
        
        for dir in directions {
            var nextRow = row + dir.0
            var nextCol = col + dir.1
            
            while (0..<8).contains(nextRow) && (0..<8).contains(nextCol) {
                if let targetPiece = board[nextRow][nextCol] {
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
    
    func islegalKnight(row: Int, col:Int)-> [(Int, Int)] {
        var legalMoves: [(Int, Int)] = []
        guard let piece = board[row][col] else { return [] }
        
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
                if let targetPiece = board[nextRow][nextCol] {
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
    
    func islegalRook(row: Int, col:Int)-> [(Int, Int)] {
        var legalMoves: [(Int, Int)] = []
        guard let piece = board[row][col] else { return [] }
        
        // RIGHT
        var c = col + 1
        while c < 8 {
            if let target = board[row][c] {
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
            if let target = board[row][c] {
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
            if let target = board[r][col] {
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
            if let target = board[r][col] {
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
    
    func islegalQueen(row: Int, col:Int)-> [(Int, Int)] {
        
        var legalMovesRook = islegalRook(row: row, col: col)
        var legalMovesBishop = islegalBishop(row: row, col: col)
        
        // Queen's movment = rook moves + bishop moves
        let legalMoves = legalMovesRook + legalMovesBishop
        
        return legalMoves
    }
    
    func islegalKing(row: Int, col:Int) -> [(Int, Int)] {
        var legalMoves: [(Int, Int)] = []
        let currentPiece = board[row][col]
        
        for dRow in -1...1 {
                for dCol in -1...1 {
                    // Skip the current square
                    if dRow == 0 && dCol == 0 { continue }
                    
                    let newRow = row + dRow
                    let newCol = col + dCol
                    
                    // Check bounds (0 to 7)
                    if newRow >= 0 && newRow < 8 && newCol >= 0 && newCol < 8 {
                        if board[newRow][newCol]?.color != currentPiece?.color {
                            legalMoves.append((newRow, newCol))
                        }
                    }
                }
            }
        
        return legalMoves
    }
    
    mutating func moveAndPromote(from: (Int, Int), to: (Int, Int), promoteTo: PieceType) {
            guard let piece = board[from.0][from.1] else { return }
            
            guard piece.color == currentTurn else { return }
            
            history.append(board)
            
            let promotedPiece = ChessPiece(type: promoteTo, color: piece.color)
            
            // Place the new piece at the destination
            board[to.0][to.1] = promotedPiece
            
            // Clear the starting position
            board[from.0][from.1] = nil
            
            currentTurn = (currentTurn == .white) ? .black : .white
        }
}



