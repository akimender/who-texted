//
//  GameResponse.swift
//  WhoTexted
//
//  Created by Andrew Kim on 12/2/25.
//

import Foundation

struct GameResponse: Identifiable, Codable {
    let id: String
    let playerId: String?  // Nil during voting phase (anonymous)
    let text: String
    let isReal: Bool
    var voteCount: Int
}

