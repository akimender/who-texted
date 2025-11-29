//
//  ChatBubble.swift
//  WhoTexted
//
//  Created by Andrew Kim on 11/29/25.
//

import Foundation
import SwiftUI

struct ChatBubble: View {
    let message: ChatMessage
    let isCurrentUser: Bool

    var body: some View {
        HStack {
            if isCurrentUser { Spacer() }

            VStack(alignment: .leading) {
                Text(message.senderDisplayName)
                    .font(.caption)
                    .foregroundColor(.gray)

                Text(message.text)
                    .padding(10)
                    .background(isCurrentUser ? Color.blue : Color.gray.opacity(0.3))
                    .foregroundColor(isCurrentUser ? .white : .black)
                    .cornerRadius(12)
            }

            if !isCurrentUser { Spacer() }
        }
        .padding(.vertical, 4)
    }
}
