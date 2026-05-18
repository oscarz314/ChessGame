//
//  HomeView.swift
//  ChessGame
//
//  Created by Student on 5/13/26.
//

import SwiftUI

struct HomeView: View {
    @State private var botLevel: Int = 5
    @State private var botLevelText: String = "5"
    @State private var isPressed = false
    
    @AppStorage("losses") private var losses = 0
    
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
                            .scaleEffect(isPressed ? 1.2 : 1.0)
                            .animation(.easeInOut(duration: 0.2), value: isPressed)
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { _ in isPressed = true }
                                    .onEnded { _ in isPressed = false }
                            )
                        
                        Text("Swift Chess")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Losses: \(losses)")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 50)
                    
                    Spacer()
                    
                    //Bot level
                    VStack(spacing: 10) {
                        Text("Bot Analysis Depth (1 - 20)")
                            .font(.headline)
                        
                        TextField("Enter bot level", text: $botLevelText)
                            .keyboardType(.numberPad)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 200)
                            .multilineTextAlignment(.center)
                            .onChange(of: botLevelText) { _, newValue in
                                // Format numbers
                                let filtered = newValue.filter { $0.isNumber }
                                
                                // Validate and Clamp
                                if let value = Int(filtered) {
                                    let clamped = min(max(value, 1), 20)
                                    
                                    // Only update if it actually changed to avoid infinite loop
                                    if String(clamped) != newValue {
                                        botLevel = clamped
                                        botLevelText = String(clamped)
                                    } else {
                                        botLevel = clamped
                                    }
                                } else if filtered.isEmpty {
                                    // Handle empty case, e.g., set to 1 or leave empty
                                    botLevel = 1
                                } else {
                                    // If filtered resulted in non-empty but invalid Int (unlikely with .isNumber)
                                    botLevelText = filtered
                                }
                            }
                    }
                    
                    // Start Button
                    NavigationLink {
                        // This opens your existing ChessBoard file
                        ChessBoard(botLevel: botLevel)
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

