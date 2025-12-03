//
//  GameState.swift
//  WhoTexted
//
//  Created by Andrew Kim on 11/28/25.
//

import Foundation


enum GameState: String, Codable {
    case lobby
    case setup
    case prompt
    case responding
    case voting
    case reveal
    case scoring
    case finished
}
