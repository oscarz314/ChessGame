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
    
    init() {
        setupBoard()
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
        board[to.0][to.1] = piece
        board[from.0][from.1] = nil
    }
}



