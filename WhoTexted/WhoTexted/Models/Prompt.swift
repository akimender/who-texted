//
//  Prompt.swift
//  WhoTexted
//
//  Created by Andrew Kim on 11/28/25.
//

import Foundation

// each prompt is uniquely identifiable and is linked to a player by ID
struct Prompt: Identifiable, Codable {
    let id: String = UUID().uuidString
    let text: String
    let targetPlayerId: String
}
