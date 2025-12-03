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
    var player: Player?

    private var cancellable: AnyCancellable?

    init() {
        
        cancellable = NotificationCenter.default.publisher(for: .webSocketDidReceiveData)
            .compactMap { $0.object as? Data }
            .sink { [weak self] data in
                self?.handleServerResponse(data)
            }
    }
    
    func initialize(room: Room, player: Player) {
        self.room = room
        self.players = room.players
        
        self.player = player
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
    
    // send to backend that room (based on roomId) wants to transition to game state
    func sendStartGame() {
        guard let room = room else { return }
        
        let payload: [String: Any] = [
            "type": "start_game",
            "roomId": room.id
        ]
        
        WebSocketManager.shared.sendDictionary(payload)
    }

    private func handleServerResponse(_ data: Data) {
        print("[LobbyView] Raw:", String(data: data, encoding: .utf8)!)
        
        do {
            let envelope = try JSONDecoder().decode(SocketEnvelope.self, from: data)
            
            print("[LobbyView] Envelope:", envelope)
            
            switch envelope.type {
            case "game_start":
                handleGameStarting(envelope)
                
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
        } catch {
            print("Failed to decode SocketEnvelope:", error)
            print("Raw JSON:", String(data: data, encoding: .utf8) ?? "nil")
        }
    }
    
    private func handleGameStarting(_ envelope: SocketEnvelope) {
        guard let room = envelope.room else {
            print("[LobbyView] Envelope is missing room")
            return
        }
        
        DispatchQueue.main.async {
            AppState.shared.screen = .game(room: room, player: self.player!)
        }
    }
}
