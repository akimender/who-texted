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
// Needs expansion to enable proper live-time functionality
struct Room: Identifiable, Codable {
    var id: String
    var hostId: String
    var players: [Player]
    var state: GameState = .lobby
    var currentRound: Int = 0
    var currentPrompt: Prompt?
}
