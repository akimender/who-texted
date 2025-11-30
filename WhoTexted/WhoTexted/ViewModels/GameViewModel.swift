//
//  GameViewModel.swift
//  WhoTexted
//
//  Created by Andrew Kim on 11/29/25.
//

import Foundation
import Combine

class GameViewModel: ObservableObject {
    @Published var room: Room?
    @Published var messages: [ChatMessage] = []
    @Published var prompt: Prompt?
    @Published var timeRemaining: Int = 10

    private var timer: Timer?
    private var cancellable: AnyCancellable?

    init() {
        cancellable = NotificationCenter.default.publisher(for: .webSocketDidReceiveData)
            .compactMap { $0.object as? Data }
            .sink { [weak self] data in
                self?.handleData(data)
            }
    }

    private func handleData(_ data: Data) {
        // Decode envelope first
        if let envelope = try? JSONDecoder().decode(SocketEnvelope.self, from: data) {

            switch envelope.type {

            case "chat_message":
                if let message = decodeMessage(from: data) {
                    DispatchQueue.main.async {
                        self.messages.append(message)
                    }
                }

            case "room_update", "room_joined":
                if let room = envelope.room {
                    DispatchQueue.main.async {
                        self.room = room
                        self.prompt = room.currentPrompt
                    }
                }

            default:
                break
            }
        }
    }

    private func decodeMessage(from data: Data) -> ChatMessage? {
        return try? JSONDecoder().decode(ChatMessage.self, from: data)
    }

    func sendMessage(text: String, sender: Player) {
        guard let room = room else { return }
        guard let displayName = sender.displayName else { return }

        let msg = ChatMessage(senderId: sender.id, senderDisplayName: displayName, text: text)
        ChatService.shared.sendMessage(roomId: room.id, message: msg)
    }
}
