//
//  WebSocketManager.swift
//  WhoTexted
//

import Foundation

class WebSocketManager: NSObject, ObservableObject, URLSessionWebSocketDelegate {
    static let shared = WebSocketManager()

    @Published var isConnected = false // tracks whether websocket connection is open or closed (changes will update views)
    private var webSocketTask: URLSessionWebSocketTask? // actual websocket connection to be used - assigned by connect()

    private override init() {}

    // MARK: - CONNECT
    func connect() {
        guard webSocketTask == nil else { return }

        let url = URL(string: "ws://localhost:8000/ws")!

        let session = URLSession(
            configuration: .default,
            delegate: self,
            delegateQueue: OperationQueue()
        )

        webSocketTask = session.webSocketTask(with: url) // start connection handshake with server via url
        webSocketTask?.resume()

        print("[WS] Connecting to \(url.absoluteString)")
        listen() // start the receive loop
    }

    // MARK: - DISCONNECT
    func disconnect() {
        webSocketTask?.cancel(with: .goingAway, reason: nil) // stops the websocket task
        webSocketTask = nil
        isConnected = false
        print("[WS] Disconnected")
    }

    // MARK: - SEND
    func send<T: Codable>(_ message: T) {
        guard isConnected else {
            print("[WS] Cannot send, socket not connected")
            return
        }

        guard let webSocketTask else { return }
        guard let data = try? JSONEncoder().encode(message) else {
            print("[WS] Failed to encode message")
            return
        }

        webSocketTask.send(.string(String(data: data, encoding: .utf8)!)) { error in
            if let error = error {
                print("[WS] Send error:", error)
            }
        }
    }

    // MARK: - LISTEN LOOP
    private func listen() {
        guard let webSocketTask else { return }

        webSocketTask.receive { [weak self] result in
            guard let self else { return }

            switch result {
            case .failure(let error):
                print("[WS] Receive error:", error)
                self.isConnected = false

            case .success(let message):
                print("[WS] Received:", message)

                switch message {
                case .data(let data):
                    NotificationCenter.default.post(
                        name: .webSocketDidReceiveData,
                        object: data
                    )

                case .string(let text):
                    if let data = text.data(using: .utf8) {
                        NotificationCenter.default.post(
                            name: .webSocketDidReceiveData,
                            object: data
                        )
                    }

                default:
                    break
                }
            }

            // keep listening forever
            self.listen()
        }
    }

    // MARK: - DELEGATE (DETECT CONNECTION OPEN)
    func urlSession(_ session: URLSession,
                    webSocketTask: URLSessionWebSocketTask,
                    didOpenWithProtocol protocol: String?) {
        print("[WS] Connected!")
        DispatchQueue.main.async {
            self.isConnected = true
        }
    }
    
    func sendDictionary(_ dict: [String: Any]) {
        print("ATTEMPTING TO SEND DICTIONARY")
        
        // Ensure socket connection
        guard isConnected else {
            print("[WS] Cannot send, socket not connected")
            return
        }

        // Serialize dictionary to JSONObject
        guard let data = try? JSONSerialization.data(withJSONObject: dict) else {
            print("[WS] Failed to encode dictionary")
            return
        }

        // Send JSONObject to backend
        webSocketTask?.send(.string(String(data: data, encoding: .utf8)!)) { error in
            if let error = error {
                print("[WS] Send error:", error)
            }
        }
    }

    func urlSession(_ session: URLSession,
                    webSocketTask: URLSessionWebSocketTask,
                    didCloseWith closeCode: URLSessionWebSocketTask.CloseCode,
                    reason: Data?) {
        print("[WS] Connection closed")
        DispatchQueue.main.async {
            self.isConnected = false
        }
    }
}

extension Notification.Name {
    static let webSocketDidReceiveData = Notification.Name("webSocketDidReceiveData")
}
