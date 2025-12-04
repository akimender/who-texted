//
//  Room.swift
//  WhoTexted
//
//  Created by Andrew Kim on 11/28/25.
//

import Foundation

// Room model
// Uniquely identifiable and can store multiple players
// Tracks current round number and current prompt
struct Room: Identifiable, Codable {
    var id: String
    var hostId: String // linked to id of Player that is host
    var players: [Player]
    var state: GameState = .lobby
    var currentRound: Int = 0
    var maxRounds: Int = 5
    var currentPrompt: String?  // Changed from Prompt? to String? to match backend
    var currentRoundData: Round?
    var rounds: [Round] = []
}
