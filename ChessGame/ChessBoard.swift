//
//  ChessBoard.swift
//  ChessGame
//
//  Created by Student on 4/27/26.
//

import Foundation
import SwiftUI

struct ChessBoard: View {
    //Board size 8 by 8
    let size = 8
    
    //Test piece
    
    var body: some View {
        HStack{
            GeometryReader{ geo in
                //Geometry reader used to read the board size and square size relative to the grid
                let boardSize = min(geo.size.width, geo.size.height)
                let squareSize = boardSize / CGFloat(size)
                
                ZStack{
                    // Make grid
                    Grid(horizontalSpacing: 0, verticalSpacing: 0) {
                        ForEach(0..<size, id: \.self) { row in
                            GridRow {
                                ForEach(0..<size, id: \.self) { column in
                                    Rectangle()
                                        .fill(isDark(row: row, col: column) ? Color.green : Color.white)
                                        .aspectRatio(1, contentMode: .fit)
                                }
                            }
                        }
                    }
                    .border(Color.black, width: 2)
                    .padding()
                }
                .frame(width: boardSize, height: boardSize)
            }
            .aspectRatio(1, contentMode: .fit)
            .padding()
        }
    }
    
    //Decide which square is dark
    func isDark(row: Int, col: Int) -> Bool {
            return (row + col) % 2 != 0
        }
}

#Preview {
    ChessBoard()
}
