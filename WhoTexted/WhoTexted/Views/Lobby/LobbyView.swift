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
    @EnvironmentObject var router: AppRouter
    @EnvironmentObject var session: SessionModel

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
                session.clearSession()
                router.navigateToHome()
            }
            .foregroundColor(.red)
            .padding(.top)
            
            // REMOVE (JUST FOR TESTING)
            if vm.goingToGame {
                Text("GOING TO GAME")
            }
            
            Text("there should be text above this when the game starts")

        }
        .onAppear{
            vm.router = router
            vm.session = session
            vm.initialize(room: room, player: player)
        }
    }
}

