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

    private func handleData(_ data: Data) {
        if let room = try? JSONDecoder().decode(Room.self, from: data) {
            self.room = room
            self.players = room.players
        }
    }
}
