//
//  SocketEnvelope.swift
//  WhoTexted
//
//  Created by Andrew Kim on 11/29/25.
//

import Foundation

// Sends updates about Room information
struct SocketEnvelope: Codable {
    let type: String
    let playerId: String?
    let roomId: String?
    let displayName: String?
    let isHost: Bool?
    let room: Room?
    
    // Game-specific fields
    let targetPlayerName: String?
    let promptSenderName: String?
    let promptText: String?
    let yourRole: String?
    let allSubmitted: Bool?
    let allVoted: Bool?
    let responses: [GameResponse]?
    let votes: [Vote]?
    let scores: [String: Int]?
    let finalScores: [String: Int]?
    let winner: Player?
    let roundSummary: [String: String]?
}
