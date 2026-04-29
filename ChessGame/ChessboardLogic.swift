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
        
        //only move if the piece color matches the turn
        guard piece.color == currentTurn else {return}
        
        history.append(board)
        board[to.0][to.1] = piece
        board[from.0][from.1] = nil
        
        //Switch the turn
        currentTurn = (currentTurn == .white) ? .black : .white
    }
    
    func isLegal(row: Int, col:Int){
        if(board[row][col]?.type == .pawn){
            
        }
        else if(board[row][col]?.type == .bishop){
            
        }
        else if(board[row][col]?.type == .knight){
            
        }
        else if(board[row][col]?.type == .rook){
            
        }
        if(board[row][col]?.type == .queen){
            
        }
        else{
            
        }
    }
    
    func islegalPawn(row: Int, col:Int) -> [(Int, Int)] {
        var legalMoves: [(Int, Int)] = []
        let currentPiece = board[row][col]

        // Check if can move twice else check once
        if (currentPiece?.color == .white && row == 6){
            if(board[row - 2][col] == nil){
                legalMoves.append((row - 2, col))
            }
        }
        
        if(board[row - 1][col] == nil){
            legalMoves.append((row - 1, col))
        }
        
        //Check if can capture sideways
        
        return legalMoves
    }
    
    func islegalBishop(row: Int, col:Int)-> [[(Int, Int)]] {
        return [[(0, 0)]]
    }
    
    func islegaKnight(row: Int, col:Int)-> [[(Int, Int)]] {
        return [[(0, 0)]]
    }
    
    func islegalRook(row: Int, col:Int)-> [[(Int, Int)]] {
        return [[(0, 0)]]
    }
    
    func islegalQueen(row: Int, col:Int)-> [[(Int, Int)]] {
        return [[(0, 0)]]
    }
    
    func islegalKing(row: Int, col:Int)-> [[(Int, Int)]] {
        return [[(0, 0)]]
    }
}



