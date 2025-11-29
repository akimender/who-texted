//
//  RoomJoinedResponse.swift
//  WhoTexted
//
//  Created by Andrew Kim on 11/29/25.
//

import Foundation

struct RoomJoinedResponse: Codable {
    let type: String // "room_joined"
    let playerId: String // assigned server-side
    let roomId: String
    let isHost: Bool
    let displayName: String // server-assigned anonymous name
    let room: Room // full room state after join
}
