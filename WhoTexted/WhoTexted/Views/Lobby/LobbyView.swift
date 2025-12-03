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
    let room: Room
    @StateObject var vm = LobbyViewModel()

    var body: some View {
        VStack {
            Text("Lobby")
                .font(.title)
                .padding()
            
            Text("Room Code: \(vm.room?.id ?? "")") // room is optional

            List(vm.players) { p in
                HStack {
                    Text(p.username)
                    if p.isHost { Text("(Host)") }
                }
            }

            if player.isHost {
                Button("Start game") {
                    vm.sendStartGame()
                }
                .buttonStyle(.borderedProminent)
                .padding()
            }
            
            Button("Leave Room") {
                vm.sendLeaveRoom(player: player)
                AppState.shared.screen = .home
            }
            .foregroundColor(.red)
            .padding(.top)
        }
        .onAppear{
            vm.initialize(room: room, player: player)
        }
    }
}

