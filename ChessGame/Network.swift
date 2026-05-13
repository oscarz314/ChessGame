//
//  Network.swift
//  ChessGame
//
//  Created by Student on 5/12/26.
//

import Foundation

struct ChessAPIResponse: Codable {
    let from: String
    let to: String
    let san: String?        // Algebraic notation (e.g., "Nf3")
    let promotion: String?  // "q", "r", "b", "n"
}

class ChessNetworkService {
    static let shared = ChessNetworkService()
    
    // Updated to the correct base URL
    private let apiURL = URL(string: "https://chess-api.com/v1")!
    
    func fetchBotMove(fen: String, completion: @escaping (ChessAPIResponse?) -> Void) {
        var request = URLRequest(url: apiURL)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Ensure level is an Int (3) rather than a String ("3")
        let body: [String: Any] = [
            "fen": fen,
            "level": 3
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, _, error in
            guard let data = data, error == nil else {
                completion(nil)
                return
            }
            
            do {
                let response = try JSONDecoder().decode(ChessAPIResponse.self, from: data)
                DispatchQueue.main.async {
                    completion(response)
                }
            } catch {
                print("Decoding Error: \(error)")
                completion(nil)
            }
        }.resume()
    }
}

