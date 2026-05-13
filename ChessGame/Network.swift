//
//  Network.swift
//  ChessGame
//
//  Created by Student on 5/12/26.
//

import Foundation

// MARK: - API Response

struct ChessAPIResponse: Codable {

    let from: String
    let to: String

    let san: String?

    let move: String?
    let lan: String?

    let promotion: Bool?
    let isPromotion: Bool?

    let isCapture: Bool?
    let isCastling: Bool?

    let fen: String?
    let depth: Int?
    let eval: Double?
}

// MARK: - Network Service

class ChessNetworkService {

    static let shared = ChessNetworkService()

    private let apiURL = URL(string: "https://chess-api.com/v1")!

    func fetchBotMove(
        fen: String,
        completion: @escaping (ChessAPIResponse?) -> Void
    ) {

        var request = URLRequest(url: apiURL)

        request.httpMethod = "POST"

        request.addValue(
            "application/json",
            forHTTPHeaderField: "Content-Type"
        )

        let body: [String: Any] = [
            "fen": fen,
            "depth": 12
        ]

        do {

            request.httpBody = try JSONSerialization.data(
                withJSONObject: body
            )

        } catch {

            print("JSON Encoding Error:", error)

            completion(nil)

            return
        }

        URLSession.shared.dataTask(with: request) {
            data,
            response,
            error in

            // NETWORK ERROR
            if let error = error {

                print("Request Error:", error)

                DispatchQueue.main.async {
                    completion(nil)
                }

                return
            }

            // NO DATA
            guard let data = data else {

                print("No data returned")

                DispatchQueue.main.async {
                    completion(nil)
                }

                return
            }

            // DEBUG RAW RESPONSE
            if let raw = String(data: data, encoding: .utf8) {

                print("RAW RESPONSE:")
                print(raw)
            }

            do {

                let decoded = try JSONDecoder().decode(
                    ChessAPIResponse.self,
                    from: data
                )

                DispatchQueue.main.async {
                    completion(decoded)
                }

            } catch {

                print("Decoding Error:", error)

                DispatchQueue.main.async {
                    completion(nil)
                }
            }

        }.resume()
    }
}
