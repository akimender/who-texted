//
//  RootView.swift
//  WhoTexted
//
//  Created by Andrew Kim on 12/2/25.
//

import Foundation
import SwiftUI

struct RootView: View {
    @StateObject private var appState = AppState.shared

    var body: some View {
        switch appState.screen {

        case .home:
            HomeView()

        case .lobby(let room, let player):
            LobbyView(player: player, room: room)

        case .game(let room, let player):
            GameView(player: player, room: room)
        }
    }
}
