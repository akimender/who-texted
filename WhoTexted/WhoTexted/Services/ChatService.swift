//
//  ChatService.swift
//  WhoTexted
//
//  Created by Andrew Kim on 11/29/25.
//

import Foundation

struct SendMessageRequest: Codable {
    let type = "send_message"
    let roomId: String
    let text: String  // Changed from message: ChatMessage to text: String to match backend
}

class ChatService {
    static let shared = ChatService()

    func sendMessage(roomId: String, text: String) {
        let req = SendMessageRequest(roomId: roomId, text: text)
        WebSocketManager.shared.send(req)
    }
}
