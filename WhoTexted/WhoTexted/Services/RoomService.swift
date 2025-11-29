//
//  RoomService.swift
//  WhoTexted
//
//  Created by Andrew Kim on 11/29/25.
//

import Foundation

struct CreateRoomRequest: Codable {
    let type = "create_room"
    let username: String
}

struct JoinRoomRequest: Codable {
    let type = "join_room"
    let roomId: String
    let username: String
}

class RoomService {
    static let shared = RoomService()

    func createRoom(playerId: String, username: String) {
        let req = CreateRoomRequest(username: username)
        WebSocketManager.shared.send(req)
    }

    func joinRoom(roomId: String, playerId: String, username: String) {
        let req = JoinRoomRequest(roomId: roomId, username: username)
        WebSocketManager.shared.send(req)
    }
}
