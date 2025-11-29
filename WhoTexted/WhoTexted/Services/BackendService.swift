//
//  BackendService.swift
//  WhoTexted
//
//  Created by Andrew Kim on 11/29/25.
//

import Foundation

class BackendService {
    static let shared = BackendService()
    private let ws = WebSocketManager.shared

    func connect() {
        ws.connect()
    }

    func disconnect() {
        ws.disconnect()
    }
}
