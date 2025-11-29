//
//  GameView.swift
//  WhoTexted
//
//  Created by Andrew Kim on 11/29/25.
//

import Foundation
import SwiftUI

struct GameView: View {
    let player: Player
    @StateObject var vm = GameViewModel()
    @State private var messageText = ""

    var body: some View {
        VStack {
            if let prompt = vm.prompt {
                PromptCard(prompt: prompt)
            }

            ChatScrollView(messages: vm.messages, currentPlayer: player)

            MessageInputBar(text: $messageText) {
                vm.sendMessage(text: messageText, sender: player)
                messageText = ""
            }
        }
        .padding()
        .onAppear {
            vm.startTimer()
        }
    }
}
