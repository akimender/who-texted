//
//  HomeViewModel.swift
//  WhoTexted
//
//  Created by Andrew Kim on 11/29/25.
//

import Foundation
import Combine

class HomeViewModel: ObservableObject {
    var router: AppRouter?
    var session: SessionModel?
    @Published var username: String = "" // needs to be filled out by user
    @Published var roomCode: String = "" // only needs to be filled out to join a room
    
    private var cancellable: AnyCancellable?
    
    init() {
        WebSocketManager.shared.connect()
        
        cancellable = NotificationCenter.default.publisher(
            for: .webSocketDidReceiveData
        )
        .compactMap { $0.object as? Data }
        .receive(on: DispatchQueue.main)
        .sink { [weak self] data in
            self?.handleServerResponse(data)
        }
    }

    func createRoom() {
        guard !username.isEmpty else { return }
        
        let request = CreateRoomRequest(username: username)
        WebSocketManager.shared.send(request)
    }

    func joinRoom() {
        guard !username.isEmpty else { return }
        guard !roomCode.isEmpty else { return }

        let request = JoinRoomRequest(roomId: roomCode, username: username)
        WebSocketManager.shared.send(request)
    }
    
    private func handleServerResponse(_ data: Data) {
        print("[HomeVM] RAW:", String(data: data, encoding: .utf8) ?? "nil")
        
        guard let envelope = try? JSONDecoder().decode(SocketEnvelope.self, from: data) else {
            print("[HomeVM] Failed to decode envelope")
            print("Raw JSON:", String(data: data, encoding: .utf8) ?? "nil")
            return
        }

        switch envelope.type {
            case "room_joined":
                print("[HomeVM] Received room_joined")
                handleRoomJoined(envelope)

            case "room_update":
                print("[HomeVM] Ignoring room_update")

            default:
                print("[HomeVM] Unknown message type:", envelope.type)
        }
    }
    
    // Handles message in RoomJoinedResponse
    private func handleRoomJoined(_ envelope: SocketEnvelope) {
        guard
            let playerId = envelope.playerId,
            let room = envelope.room,
            let displayName = envelope.displayName,
            let isHost = envelope.isHost,
            let router = router,
            let session = session
        else { return }
        
        let player = Player(
            id: playerId,
            username: username,
            displayName: displayName,
            isHost: isHost
        )
        
        // Update session with room and player
        session.updateRoom(room)
        session.setPlayer(player)
        
        // Navigate to lobby
        router.navigateToLobby(roomId: room.id)
    }
}
