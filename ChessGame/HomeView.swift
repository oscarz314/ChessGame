//
//  HomeView.swift
//  ChessGame
//
//  Created by Student on 5/13/26.
//

import SwiftUI

struct HomeView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                // Background Color
                Color(uiColor: .systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 30) {
                    // Logo or Title
                    VStack {
                        Image(systemName: "crown.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80, height: 80)
                            .foregroundColor(.yellow)
                        
                        Text("Swift Chess")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                    }
                    .padding(.top, 50)
                    
                    Spacer()
                    
                    // Start Button
                    NavigationLink {
                        // This opens your existing ChessBoard file
                        ChessBoard()
                            .navigationBarTitleDisplayMode(.inline)
                    } label: {
                        Text("Start Game")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(width: 200, height: 50)
                            .background(Color.blue)
                            .cornerRadius(12)
                            .shadow(radius: 5)
                    }
                    
                    Text("Play against Level 3 Bot")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Main Menu")
        }
    }
}

#Preview {
    HomeView()
}

