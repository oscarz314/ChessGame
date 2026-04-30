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
        if(col + 1 <= 8 && board[row - (1 * moveDirection)][col + 1] != nil){ // Check right side
            legalMoves.append((row - (1 * moveDirection), col))
        }
        
        if(col - 1 >= 0 && board[row - (1 * moveDirection)][col - 1] != nil){ // Check left side
            legalMoves.append((row - (1 * moveDirection), col))
        }
        
        return legalMoves
    }
    
    func islegalBishop(row: Int, col:Int)-> [(Int, Int)] {
        var legalMoves: [(Int, Int)] = []
        return legalMoves
    }
    
    func islegalKnight(row: Int, col:Int)-> [(Int, Int)] {
        var legalMoves: [(Int, Int)] = []
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



