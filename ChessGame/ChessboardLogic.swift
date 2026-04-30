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
        let legalMoves = isLegal(row: to.0, col: to.1)
        var moveIsLegal = false
        
        for moves in legalMoves{
            if (from == moves){
                moveIsLegal = true
            }
        }
        
        if(moveIsLegal){
            // Update board, history moves,
            guard let piece = board[from.0][from.1] else { return }
            
            //only move if the piece color matches the turn
            guard piece.color == currentTurn else {return}
            
            history.append(board)
            board[to.0][to.1] = piece
            board[from.0][from.1] = nil
            
            //Switch the turn
            currentTurn = (currentTurn == .white) ? .black : .white
        }
    }
    
    func isLegal(row: Int, col:Int) -> [(Int, Int)]{
        var legalMoves: [(Int, Int)] = []
        
        // Check which legal moves
        if(board[row][col]?.type == .pawn){
            legalMoves = islegalPawn(row: row, col: col)
        }
        else if(board[row][col]?.type == .bishop){
            legalMoves = islegalBishop(row: row, col: col)
        }
        else if(board[row][col]?.type == .knight){
            legalMoves = islegalKnight(row: row, col: col)
        }
        else if(board[row][col]?.type == .rook){
            legalMoves = islegalRook(row: row, col: col)
        }
        if(board[row][col]?.type == .queen){
            legalMoves = islegalQueen(row: row, col: col)
        }
        else{
            legalMoves = islegalKing(row: row, col: col)
        }
        
        // Check if king is in check
        
        return legalMoves
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
        return legalMoves
    }
    
    func islegalQueen(row: Int, col:Int)-> [(Int, Int)] {
        var legalMoves: [(Int, Int)] = []
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



