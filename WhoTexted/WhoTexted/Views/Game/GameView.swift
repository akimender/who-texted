//
//  GameView.swift
//  WhoTexted
//

import Foundation
import SwiftUI

struct GameView: View {
    let player: Player
    let room: Room
    @StateObject private var vm = GameViewModel()

    var body: some View {
        Group {
            // Use vm.room?.state instead of room.state to get the latest state from WebSocket updates
            switch vm.room?.state ?? room.state {
            case .roundSetup:
                RoundSetupView(
                    targetPlayerName: vm.targetPlayerName,
                    promptSenderName: vm.promptSenderName,
                    role: vm.currentRole,
                    roundNumber: vm.room?.currentRound ?? room.currentRound
                )
                
            case .prompt:
                PromptDisplayView(
                    promptText: vm.promptText,
                    targetPlayerName: vm.targetPlayerName
                )
                
            case .responding:
                ResponseSubmissionView(
                    viewModel: vm,
                    targetPlayerName: vm.targetPlayerName
                )
                
            case .voting:
                VotingView(viewModel: vm)
                
            case .reveal:
                RevealView(viewModel: vm)
                
            case .scoring:
                ScoringView(viewModel: vm)
                
            case .finished:
                GameFinishedView(viewModel: vm)
                
            default:
                VStack {
                    Text("Waiting for game to start...")
                        .foregroundColor(.gray)
                    Text("State: \(vm.room?.state.rawValue ?? room.state.rawValue)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("Round \(vm.room?.currentRound ?? room.currentRound)")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // Initialize view model with room
            vm.room = room
        }
    }
}
