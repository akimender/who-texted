//
//  GameView.swift
//  WhoTexted
//

import Foundation
import SwiftUI

struct GameView: View {
    let player: Player
    let room: Room
    @EnvironmentObject var vm: GameViewModel
    @EnvironmentObject var session: SessionModel

    var body: some View {
        Group {
            // Per spec: Use Round.state for game phases, Room.state only for "lobby", "playing", "finished"
            let currentRoundState = vm.room?.currentRoundData?.state ?? room.currentRoundData?.state
            
            if let roundState = currentRoundState {
                // Use Round.state for game phases (per spec)
                switch roundState {
                    
                case "instructions":
                    InstructionsView(targetPlayerName: vm.targetPlayerName)
                    
//                case "prompt":
//                    PromptDisplayView(
//                        promptText: vm.promptText,
//                        targetPlayerName: vm.targetPlayerName
//                    )
                    
                case "responding":
                    ResponseSubmissionView(
                        viewModel: vm,
                        targetPlayerName: vm.targetPlayerName
                    )
                    
                case "voting":
                    VotingView(viewModel: vm)
                    
                case "reveal":
                    RevealView(viewModel: vm)
                    
                case "scoring":
                    ScoringView(viewModel: vm)
                    
                default:
                    // Show round setup if we have role info but round state not set yet
                    if vm.currentRole != nil || vm.targetPlayerName != nil {
                        RoundSetupView(
                            targetPlayerName: vm.targetPlayerName,
                            promptSenderName: vm.promptSenderName,
                            role: vm.currentRole,
                            roundNumber: vm.room?.currentRound ?? room.currentRound
                        )
                    } else {
                        VStack {
                            Text("Waiting for game to start...")
                                .foregroundColor(.gray)
                            Text("Round state: \(roundState)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            } else {
                // No round data yet - show setup or waiting
                // Check if room state is "playing" - if so, show setup view
                if vm.room?.state == .playing || room.state == .playing {
                    if vm.currentRole != nil || vm.targetPlayerName != nil {
                        RoundSetupView(
                            targetPlayerName: vm.targetPlayerName,
                            promptSenderName: vm.promptSenderName,
                            role: vm.currentRole,
                            roundNumber: vm.room?.currentRound ?? room.currentRound
                        )
                    } else {
                        VStack {
                            Text("Setting up round...")
                                .foregroundColor(.gray)
                            Text("Room state: \(vm.room?.state.rawValue ?? room.state.rawValue)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                } else {
                    VStack {
                        Text("Waiting for game to start...")
                            .foregroundColor(.gray)
                        Text("Room state: \(vm.room?.state.rawValue ?? room.state.rawValue)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Round \(vm.room?.currentRound ?? room.currentRound)")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // Initialize view model with room and session
            vm.room = room
            vm.session = session
        }
    }
}
