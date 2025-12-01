//
//  LobbyView.swift
//  WhoTexted
//
//  Created by Andrew Kim on 11/29/25.
//

import Foundation
import SwiftUI

struct LobbyView: View {
    let player: Player
    let initialRoom: Room
    @StateObject var vm = LobbyViewModel()

    var body: some View {
        VStack {
            Text("Lobby")
                .font(.title)
                .padding()

            List(vm.players) { p in
                HStack {
                    Text(p.username)
                    if p.isHost { Text("(Host)") }
                }
            }

            if player.isHost {
                NavigationLink("Start Game") {
                    GameView(player: player)
                }
                .buttonStyle(.borderedProminent)
                .padding()
            }
        }
        .onAppear{
            vm.initialize(room: initialRoom)
        }
        .onDisappear{
            vm.sendLeaveRoom(player: player) // triggers when players leave lobbyview
        }
    }
}

