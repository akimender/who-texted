//
//  RootView.swift
//  WhoTexted
//
//  Created by Andrew Kim on 12/2/25.
//

import Foundation
import SwiftUI

struct RootView: View {
    @EnvironmentObject var router: AppRouter
    @EnvironmentObject var session: SessionModel

    var body: some View {
        switch router.route {
        case .home:
            HomeView()
            
        case .lobby(let roomId):
            if let room = session.currentRoom, room.id == roomId,
               let player = session.currentPlayer {
                LobbyView(player: player, room: room)
            } else {
                // Fallback: show loading or error
                VStack {
                    Text("Loading lobby...")
                    ProgressView()
                }
            }
            
        case .game(let roomId):
            if let room = session.currentRoom, room.id == roomId,
               let player = session.currentPlayer {
                GameView(player: player, room: room)
            } else {
                // Fallback: show loading or error
                VStack {
                    Text("Loading game...")
                    ProgressView()
                }
            }
        }
    }
}
