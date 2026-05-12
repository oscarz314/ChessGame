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
    let fen: String // The board after the AI moves
    let move: String // e.g., "e7e5"
}

class ChessNetworkService {
    static let shared = ChessNetworkService()
    private let apiURL = URL(string: "https://chess-api.com/v1/play")!
    
    func fetchBotMove(fen: String, completion: @escaping (ChessAPIResponse?) -> Void) {
        var request = URLRequest(url: apiURL)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Settings: You can change the 'level' here
        let body: [String: Any] = [
            "fen": fen,
            "level": "3"
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, _, error in
            guard let data = data, error == nil else {
                completion(nil)
                return
            }
            
            print(String(data: data, encoding: .utf8) ?? "No response")

            let response = try? JSONDecoder().decode(
                ChessAPIResponse.self,
                from: data
            )
            DispatchQueue.main.async {
                completion(response)
            }
        }.resume()
    }
}

