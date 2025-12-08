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
    @Published var timeRemaining: Int = 10
    
    // Game state properties
    @Published var currentRole: RoundRole?
    @Published var targetPlayerName: String?
    @Published var promptSenderName: String?
    @Published var promptText: String?
    @Published var responses: [GameResponse] = []
    @Published var myResponse: String = ""
    @Published var hasSubmitted: Bool = false
    @Published var selectedVoteResponseId: String?
    @Published var hasVoted: Bool = false
    @Published var roundScores: [String: Int] = [:]
    @Published var finalScores: [String: Int] = [:]
    @Published var winner: Player?
    @Published var allSubmitted: Bool = false
    @Published var allVoted: Bool = false
    
    var session: SessionModel?

    private var timer: Timer?
    private var cancellable: AnyCancellable?

    init() {
        cancellable = NotificationCenter.default.publisher(for: .webSocketDidReceiveData)
            .compactMap { $0.object as? Data }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] data in
                self?.handleData(data)
            }
    }

    private func handleData(_ data: Data) {
        guard let envelope = try? JSONDecoder().decode(SocketEnvelope.self, from: data) else {
            print("[GameVM] Failed to decode envelope")
            return
        }

        DispatchQueue.main.async {
            switch envelope.type {
            case "round_setup":
                self.handleRoundSetup(envelope)
                
            case "prompt_display":
                self.handlePromptDisplay(envelope)
                
            case "response_submitted":
                self.handleResponseSubmitted(envelope)
                
            case "voting_phase":
                self.handleVotingPhase(envelope)
                
            case "vote_submitted":
                self.handleVoteSubmitted(envelope)
                
            case "reveal_phase":
                self.handleRevealPhase(envelope)
                
            case "scoring_phase":
                self.handleScoringPhase(envelope)
                
            case "round_complete":
                self.handleRoundComplete(envelope)
                
            case "game_finished":
                self.handleGameFinished(envelope)
                
            case "room_update", "room_joined":
                if let room = envelope.room {
                    self.room = room
                    // Update session model to keep it in sync
                    session?.updateRoom(room)
                    // Update responses if available
                    if let roundData = room.currentRoundData {
                        self.responses = roundData.responses
                    }
                    // If room state changed to playing, ensure we have the latest data
                    if room.state == .playing && room.currentRoundData != nil {
                        // Room is in game - make sure we're showing the right view
                        print("[GameVM] Room state is playing, round state: \(room.currentRoundData?.state ?? "none")")
                    }
                }
                
            case "chat_message":
                if let message = self.decodeMessage(from: data) {
                    self.messages.append(message)
                }
                
            default:
                print("[GameVM] Unknown message type: \(envelope.type)")
            }
        }
    }
    
    private func handleRoundSetup(_ envelope: SocketEnvelope) {
        if let room = envelope.room {
            self.room = room
        }
        self.targetPlayerName = envelope.targetPlayerName
        self.promptSenderName = envelope.promptSenderName
        if let roleString = envelope.yourRole {
            self.currentRole = RoundRole(rawValue: roleString) ?? .none
        }
        self.hasSubmitted = false
        self.hasVoted = false
        self.selectedVoteResponseId = nil
        self.myResponse = ""
    }
    
    private func handlePromptDisplay(_ envelope: SocketEnvelope) {
        if let room = envelope.room {
            self.room = room
        }
        self.promptText = envelope.promptText
        self.targetPlayerName = envelope.targetPlayerName
    }
    
    private func handleResponseSubmitted(_ envelope: SocketEnvelope) {
        if let room = envelope.room {
            self.room = room
        }
        self.hasSubmitted = true
        self.allSubmitted = envelope.allSubmitted ?? false
    }
    
    private func handleVotingPhase(_ envelope: SocketEnvelope) {
        if let room = envelope.room {
            self.room = room
        }
        self.responses = envelope.responses ?? []
        self.hasVoted = false
        self.selectedVoteResponseId = nil
    }
    
    private func handleVoteSubmitted(_ envelope: SocketEnvelope) {
        if let room = envelope.room {
            self.room = room
        }
        self.hasVoted = true
        self.allVoted = envelope.allVoted ?? false
    }
    
    private func handleRevealPhase(_ envelope: SocketEnvelope) {
        if let room = envelope.room {
            self.room = room
        }
        self.responses = envelope.responses ?? []
    }
    
    private func handleScoringPhase(_ envelope: SocketEnvelope) {
        if let room = envelope.room {
            self.room = room
        }
        self.roundScores = envelope.scores ?? [:]
    }
    
    private func handleRoundComplete(_ envelope: SocketEnvelope) {
        if let room = envelope.room {
            self.room = room
        }
        // Reset for next round
        self.roundScores = [:]
        self.responses = []
    }
    
    private func handleGameFinished(_ envelope: SocketEnvelope) {
        if let room = envelope.room {
            self.room = room
        }
        self.finalScores = envelope.finalScores ?? [:]
        self.winner = envelope.winner
    }

    private func decodeMessage(from data: Data) -> ChatMessage? {
        return try? JSONDecoder().decode(ChatMessage.self, from: data)
    }

    func submitResponse() {
        guard let room = room else { return }
        guard !myResponse.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        guard !hasSubmitted else { return }
        
        GameService.shared.submitResponse(roomId: room.id, text: myResponse)
    }
    
    func submitVote() {
        guard let room = room else { return }
        guard let responseId = selectedVoteResponseId else { return }
        guard !hasVoted else { return }
        
        GameService.shared.submitVote(roomId: room.id, responseId: responseId)
    }
    
    func nextRound() {
        guard let room = room else { return }
        guard let currentPlayer = session?.currentPlayer else { return }
        guard currentPlayer.isHost else { return }
        
        GameService.shared.nextRound(roomId: room.id)
    }
}
