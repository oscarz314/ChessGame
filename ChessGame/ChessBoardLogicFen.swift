//
//  ChessBoardLogicFen.swift
//  ChessGame
//
//  Created by Student on 5/15/26.
//

extension ChessboardLogic {
    func coordinateFromUCI(_ uci: String) -> (Int, Int) {
        let files = Array("abcdefgh")

        let fileChar = uci.first!
        let rankChar = uci.last!

        let col = files.firstIndex(of: fileChar) ?? 0
        let row = 8 - (Int(String(rankChar)) ?? 1)

        return (row, col)
    }
    
    func generateFEN() -> String {
        var fen = ""

        // 1. Piece Placement (Rank 8 down to Rank 1)
        for r in 0..<8 {
            var emptyCount = 0
            for c in 0..<8 {
                if let piece = board[r][c] {
                    if emptyCount > 0 {
                        fen += "\(emptyCount)"
                        emptyCount = 0
                    }
                    fen += pieceToFENChar(piece)
                } else {
                    emptyCount += 1
                }
            }
            if emptyCount > 0 {
                fen += "\(emptyCount)"
            }
            if r < 7 {
                fen += "/"
            }
        }

        // 2. Active Color
        fen += " \(currentTurn == .white ? "w" : "b")"

        // 3. Castling Availability
        var castling = ""
        // White
        if let whiteKing = board[7][4], whiteKing.type == .king, !whiteKing.hasMoved {
            if let rook = board[7][7], rook.type == .rook, !rook.hasMoved { castling += "K" }
            if let rook = board[7][0], rook.type == .rook, !rook.hasMoved { castling += "Q" }
        }
        // Black
        if let blackKing = board[0][4], blackKing.type == .king, !blackKing.hasMoved {
            if let rook = board[0][7], rook.type == .rook, !rook.hasMoved { castling += "k" }
            if let rook = board[0][0], rook.type == .rook, !rook.hasMoved { castling += "q" }
        }
        fen += " \(castling.isEmpty ? "-" : castling)"

        // 4. En Passant Target Square
        if let target = enPassantTarget {
            let colChar = Character(UnicodeScalar(97 + target.1)!) // Convert 0-7 to a-h
            let rowChar = "\(8 - target.0)"
            fen += " \(colChar)\(rowChar)"
        } else {
            fen += " -"
        }

        // 5. Halfmove Clock (50-move rule) and Fullmove Number
        // Note: moveNum is half-moves. Fullmove starts at 1 and increments after Black moves.
        let fullMoveNumber = (history.count / 2) + 1
        fen += " \(moveNum) \(fullMoveNumber)"

        return fen
    }

    
    private func pieceToFENChar(_ piece: ChessPiece) -> String {
        var char: String
        switch piece.type {
        case .pawn:   char = "p"
        case .knight: char = "n"
        case .bishop: char = "b"
        case .rook:   char = "r"
        case .queen:  char = "q"
        case .king:   char = "k"
        }
        return piece.color == .white ? char.uppercased() : char.lowercased()
    }
    
    func executeBotMove(
        fromUCI: String,
        toUCI: String,
        promotion: String?
    ) {

        let from = coordinateFromUCI(fromUCI)
        let to = coordinateFromUCI(toUCI)

        // Promotion move
        if let promotion = promotion {

            let type: PieceType

            switch promotion.lowercased() {

            case "q":
                type = .queen

            case "r":
                type = .rook

            case "b":
                type = .bishop

            case "n":
                type = .knight

            default:
                type = .queen
            }

            moveAndPromote(
                from: from,
                to: to,
                promoteTo: type
            )

        } else {

            move(from: from, to: to)
        }
    }
}
