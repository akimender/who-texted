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

    func handleData(_ data: Data) {
        if let incomingMessage = try? JSONDecoder().decode(ChatMessage.self, from: data) {
            messages.append(incomingMessage)
            return
        }

        if let room = try? JSONDecoder().decode(Room.self, from: data) {
            self.room = room
            self.prompt = room.currentPrompt
        }
    }

    func startTimer() {
        timeRemaining = 10
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { t in
            self.timeRemaining -= 1
            if self.timeRemaining <= 0 {
                t.invalidate()
            }
        }
    }

    func sendMessage(text: String, sender: Player) {
        guard let room = room else { return }
        guard let displayName = sender.displayName else {
            print("Error: sender has no displayName yet")
            return
        }
        
        let msg = ChatMessage(senderId: sender.id, senderDisplayName: displayName, text: text)
        ChatService.shared.sendMessage(roomId: room.id, message: msg)
    }
}
