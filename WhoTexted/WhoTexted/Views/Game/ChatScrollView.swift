//
//  ChatScrollView.swift
//  WhoTexted
//
//  Created by Andrew Kim on 11/29/25.
//

import Foundation
import SwiftUI

struct ChatScrollView: View {
    let messages: [ChatMessage]
    let currentPlayer: Player

    var body: some View {
        ScrollView {
            LazyVStack {
                ForEach(messages) { msg in
                    ChatBubble(
                        message: msg,
                        isCurrentUser: msg.senderId == currentPlayer.id
                    )
                }
            }
        }
    }
}
