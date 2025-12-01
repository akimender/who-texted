//
//  LobbyViewModel.swift
//  WhoTexted
//
//  Created by Andrew Kim on 11/29/25.
//

import Foundation
import Combine

class LobbyViewModel: ObservableObject {
    @Published var room: Room?
    @Published var players: [Player] = []

    private var cancellable: AnyCancellable?

    init() {
        cancellable = NotificationCenter.default.publisher(for: .webSocketDidReceiveData)
            .compactMap { $0.object as? Data }
            .sink { [weak self] data in
                self?.handleData(data)
            }
    }
    
    func initialize(room: Room) {
        self.room = room
        self.players = room.players
    }
    
    func sendLeaveRoom(player: Player) {
        print("LEAVING ROOM")
        guard let room = room else { return }
        
        // creates payload to send to backend to remove player (playerId) from room (roomId)
        let payload: [String: Any] = [
            "type": "leave_room",
            "playerId": player.id,
            "roomId": room.id
        ]
        
        WebSocketManager.shared.sendDictionary(payload)
    }

    private func handleData(_ data: Data) {
        print("[LobbyView] Raw:", String(data: data, encoding: .utf8)!)
        
        if let envelope = try? JSONDecoder().decode(SocketEnvelope.self, from: data) {
            print("[LobbyView] Envelope:", envelope)
            
            switch envelope.type {
            case "room_joined", "room_update": // may need to separate cases
                if let room = envelope.room {
                    DispatchQueue.main.async {
                        self.room = room
                        self.players = room.players
                    }
                }
            default:
                break
            }
        }
    }
}
