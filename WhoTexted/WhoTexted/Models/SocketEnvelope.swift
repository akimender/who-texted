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
}
