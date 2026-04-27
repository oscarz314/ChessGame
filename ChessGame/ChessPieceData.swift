import SwiftUI
import Foundation

enum PieceType: String {
    case pawn, knight, bishop, rook, queen, king
}

enum PieceColor: String {
    case white, black
}

struct ChessPiece: Identifiable, Hashable {
    let id = UUID()
    let type: PieceType
    let color: PieceColor
    
    var imageName: String {
        "\(color.rawValue)_\(type.rawValue)"
    }
}
