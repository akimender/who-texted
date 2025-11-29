//
//  HomeView.swift
//  WhoTexted
//
//  Created by Andrew Kim on 11/29/25.
//

import Foundation
import SwiftUI

struct HomeView: View {
    @StateObject var vm = HomeViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                Text("Who Texted?")
                    .font(.largeTitle)
                
                TextField("Enter username", text: $vm.username)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 200)

                Button("Create Room") {
                    vm.createRoom()
                }
                .disabled(vm.username.isEmpty)   // require username
                .buttonStyle(.borderedProminent)

                VStack {
                    TextField("Enter room code", text: $vm.roomCode)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 200)

                    Button("Join Room") {
                        vm.joinRoom()
                    }
                    .disabled(vm.username.isEmpty || vm.roomCode.isEmpty)
                    .buttonStyle(.bordered)
                }

                Spacer()
            }
            .navigationDestination(isPresented: $vm.canEnterRoom) {
                // Player is guaranteed safe here
                if let player = vm.player {
                    LobbyView(player: player)
                } else {
                    ProgressView("Loading...")
                }
            }
        }
    }
}
