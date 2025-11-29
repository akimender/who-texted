//
//  HomeViewModel.swift
//  WhoTexted
//
//  Created by Andrew Kim on 11/29/25.
//

import Foundation
import Combine

class HomeViewModel: ObservableObject {
    @Published var username: String = "" // needs to be filled out by user
    @Published var roomCode: String = "" // only needs to be filled out to join a room
    @Published var player: Player? // player is assigned when player attempts to create room or join room
    @Published var canEnterRoom: Bool = false
    
    private var cancellable: AnyCancellable?
    
    init() {
        WebSocketManager.shared.connect()
        
        cancellable = NotificationCenter.default.publisher(
            for: .webSocketDidReceiveData
        )
        .compactMap { $0.object as? Data }
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
        
        if let response = try? JSONDecoder().decode(RoomJoinedResponse.self, from: data) {
            
            self.player = Player(
                id: response.playerId,
                username: username,
                displayName: response.displayName,
                isHost: response.isHost
            )
            
            DispatchQueue.main.async {
                self.canEnterRoom = true
            }
            
            return
        }
        
        print("[HomeVM] Failed to decode response")
    }
}
