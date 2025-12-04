//
//  GameService.swift
//  WhoTexted
//
//  Created by Andrew Kim on 12/2/25.
//

import Foundation

struct SubmitResponseRequest: Codable {
    let type = "submit_response"
    let roomId: String
    let text: String
}

struct SubmitVoteRequest: Codable {
    let type = "submit_vote"
    let roomId: String
    let responseId: String
}

struct NextRoundRequest: Codable {
    let type = "next_round"
    let roomId: String
}

class GameService {
    static let shared = GameService()
    
    func submitResponse(roomId: String, text: String) {
        let req = SubmitResponseRequest(roomId: roomId, text: text)
        WebSocketManager.shared.send(req)
    }
    
    func submitVote(roomId: String, responseId: String) {
        let req = SubmitVoteRequest(roomId: roomId, responseId: responseId)
        WebSocketManager.shared.send(req)
    }
    
    func nextRound(roomId: String) {
        let req = NextRoundRequest(roomId: roomId)
        WebSocketManager.shared.send(req)
    }
}

