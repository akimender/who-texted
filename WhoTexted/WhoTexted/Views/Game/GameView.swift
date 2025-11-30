//
//  GameView.swift
//  WhoTexted
//

import Foundation
import SwiftUI

struct GameView: View {
    let player: Player
    @StateObject private var vm = GameViewModel()
    @State private var messageText = ""

    var body: some View {
        VStack(spacing: 16) {

            // Prompt
            if let prompt = vm.prompt {
                PromptCard(prompt: prompt)
            } else {
                Text("Waiting for prompt...")
                    .font(.headline)
                    .foregroundColor(.gray)
            }

            // Messages
            ChatScrollView(messages: vm.messages, currentPlayer: player)

            // Input bar
            MessageInputBar(text: $messageText) {
                vm.sendMessage(text: messageText, sender: player)
                messageText = ""
            }
        }
        .padding()
        .navigationTitle("Round \(vm.room?.currentRound ?? 1)")
        .navigationBarTitleDisplayMode(.inline)
    }
}
