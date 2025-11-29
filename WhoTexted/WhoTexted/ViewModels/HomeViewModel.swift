//
//  HomeViewModel.swift
//  WhoTexted
//
//  Created by Andrew Kim on 11/29/25.
//

import Foundation
import Combine

class HomeViewModel: ObservableObject {
    @Published var username: String = ""
    @Published var roomCode: String = ""
    @Published var player: Player?
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
        if let response = try? JSONDecoder().decode(RoomJoinedResponse.self, from: data) {
            self.player = Player(
                id: response.playerId,
                username: username,
                displayName: response.displayName,
                isHost: response.isHost
            )
            
            self.canEnterRoom = true
        }
    }
}
