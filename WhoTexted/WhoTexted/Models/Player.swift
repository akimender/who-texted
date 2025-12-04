//
//  Player.swift
//  WhoTexted
//
//  Created by Andrew Kim on 11/28/25.
//

import Foundation

// Player model
struct Player: Identifiable, Codable, Equatable {
    let id: String
    var username: String // assigned by user
    var displayName: String? // assigned server-side
    var isHost: Bool = false
    var points: Int = 0
}
