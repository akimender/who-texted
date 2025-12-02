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
                // Title
                Text("Who Texted?")
                    .font(.largeTitle)
                
                // Enter Username field (Required)
                TextField("Enter username", text: $vm.username)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 200)

                // Option to create a new room
                Button("Create Room") {
                    vm.createRoom()
                }
                .disabled(vm.username.isEmpty)   // require username
                .buttonStyle(.borderedProminent)

                // Option to join an existing room
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
        }
    }
}
