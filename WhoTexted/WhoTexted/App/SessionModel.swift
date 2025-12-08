//
//  SessionModel.swift
//  WhoTexted
//
//  Created by Andrew Kim on 12/8/25.
//

import Foundation

@MainActor
class SessionModel: ObservableObject {
    @Published var currentPlayer: Player?
    @Published var currentRoom: Room?
    
    var currentPlayerId: String? {
        get { currentPlayer?.id }
        set {
            // Update currentPlayer when ID changes
            if let playerId = newValue, let room = currentRoom {
                currentPlayer = room.players.first { $0.id == playerId }
            } else if newValue == nil {
                currentPlayer = nil
            }
        }
    }
    
    func updateRoom(_ room: Room) {
        self.currentRoom = room
        // Update currentPlayer if we have a playerId
        if let playerId = currentPlayerId {
            self.currentPlayer = room.players.first { $0.id == playerId }
        }
    }
    
    func setPlayer(_ player: Player) {
        self.currentPlayer = player
    }
    
    func clearSession() {
        self.currentPlayer = nil
        self.currentRoom = nil
    }
}
