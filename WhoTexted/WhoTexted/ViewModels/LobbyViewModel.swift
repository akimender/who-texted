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
    
    @Published var goingToGame: Bool = false
    
    var router: AppRouter?
    var session: SessionModel?

    private var cancellable: AnyCancellable?

    init() {
        // Ensure WebSocket is connected
        if !WebSocketManager.shared.isConnected {
            print("[LobbyView] WebSocket not connected, attempting to connect...")
            WebSocketManager.shared.connect()
        } else {
            print("[LobbyView] WebSocket already connected")
        }
        
        cancellable = NotificationCenter.default.publisher(for: .webSocketDidReceiveData)
            .compactMap { $0.object as? Data }
            .receive(on: DispatchQueue.main)
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
            case "game_start", "round_setup", "prompt_display":
                // Game is starting - transition to game view
                // Handle all these cases because:
                // - round_setup: sent to responding players (not target)
                // - prompt_display: sent to all players (including target)
                handleGameStarting(envelope)
                
            case "room_joined", "room_update": // may need to separate cases
                if let room = envelope.room {
                    // Update session model to keep it in sync
                    session?.updateRoom(room)
                    
                    if room.state == .lobby {
                        // Still in lobby - just update room data
                        self.room = room
                        self.players = room.players
                    } else if room.state == .playing || room.state == .finished {
                        // Room state changed to game state - transition to game
                        // This handles the case where room_update is sent before round_setup/prompt_display
                        print("[LobbyView] Room state changed to \(room.state.rawValue), transitioning to game")
                        handleGameStarting(envelope)
                    } else {
                        // Handle any other state changes
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
        
        guard let player = self.player else {
            print("[LobbyView] Player is nil")
            return
        }
        
        guard let router = router, let session = session else {
            print("[LobbyView] Router or session is nil")
            return
        }
        
        print("[LobbyView] Transitioning to game with room state: \(room.state.rawValue), message type: \(envelope.type)")
        
        // Update session with latest room data
        session.updateRoom(room)
        session.setPlayer(player)
        
        // Navigate to game
        router.navigateToGame(roomId: room.id)
    }
}
