//
//  GameState.swift
//  WhoTexted
//
//  Created by Andrew Kim on 11/28/25.
//

import Foundation


enum GameState: String, Codable {
    case lobby
    case roundSetup = "roundSetup"
    case setup = "setup"
    case prompt = "prompt"
    case responding = "responding"
    case voting = "voting"
    case reveal = "reveal"
    case scoring = "scoring"
    case finished = "finished"
}
