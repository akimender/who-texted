//
//  GameState.swift
//  WhoTexted
//
//  Created by Andrew Kim on 11/28/25.
//

import Foundation

// 4 different stages in a game
// Lobby -> Playing -> Reveal -> Finished
enum GameState: String, Codable {
    case lobby
    case playing
    case reveal
    case finished
}
