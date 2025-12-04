//
//  Round.swift
//  WhoTexted
//
//  Created by Andrew Kim on 12/2/25.
//

import Foundation

struct Round: Identifiable, Codable {
    let id: String
    let roundNumber: Int
    let prompt: String
    let targetPlayerId: String
    let promptSenderId: String
    let realImpersonatorId: String
    var responses: [GameResponse]
    var votes: [Vote]
    var state: String
}

