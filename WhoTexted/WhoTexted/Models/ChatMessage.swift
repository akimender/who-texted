//
//  ChatMessage.swift
//  WhoTexted
//
//  Created by Andrew Kim on 11/28/25.
//

import Foundation

// Each chat message is linked to a Player ID (as well as assigned sender animal)
struct ChatMessage: Identifiable, Codable {
    let id: String = UUID().uuidString
    let senderId: String
    let senderDisplayName: String
    let text: String
    let timestamp: Date = Date()
}
