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
    let message: ChatMessage
}

class ChatService {
    static let shared = ChatService()

    func sendMessage(roomId: String, message: ChatMessage) {
        let req = SendMessageRequest(roomId: roomId, message: message)
        WebSocketManager.shared.send(req)
    }
}
