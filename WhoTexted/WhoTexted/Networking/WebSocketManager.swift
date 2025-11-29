//
//  WebSocketManager.swift
//  WhoTexted
//
//  Created by Andrew Kim on 11/29/25.
//

import Foundation

class WebSocketManager: ObservableObject {
    static let shared = WebSocketManager()

    @Published var isConnected = false
    private var webSocketTask: URLSessionWebSocketTask?

    private init() {}

    func connect() {
        let url = URL(string: "ws://YOUR-SERVER-URL/ws")!   // replace with backend URL
        webSocketTask = URLSession.shared.webSocketTask(with: url)
        webSocketTask?.resume()

        listen()
        isConnected = true
    }

    func disconnect() {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        isConnected = false
    }

    func send<T: Codable>(_ message: T) {
        guard let data = try? JSONEncoder().encode(message) else { return }
        let wsMessage = URLSessionWebSocketTask.Message.data(data)
        webSocketTask?.send(wsMessage) { error in
            if let error = error {
                print("WS send error: \(error)")
            }
        }
    }

    private func listen() {
        webSocketTask?.receive { [weak self] result in
            switch result {
            case .failure(let error):
                print("WS receive error: \(error)")
            case .success(let message):
                switch message {
                case .data(let data):
                    NotificationCenter.default.post(
                        name: .webSocketDidReceiveData,
                        object: data
                    )
                case .string(let text):
                    guard let data = text.data(using: .utf8) else { break }
                    NotificationCenter.default.post(
                        name: .webSocketDidReceiveData,
                        object: data
                    )
                @unknown default:
                    break
                }
            }

            self?.listen()
        }
    }
}

extension Notification.Name {
    static let webSocketDidReceiveData = Notification.Name("webSocketDidReceiveData")
}
