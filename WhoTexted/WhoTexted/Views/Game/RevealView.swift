//
//  RevealView.swift
//  WhoTexted
//
//  Created by Andrew Kim on 12/2/25.
//

import SwiftUI

struct RevealView: View {
    @ObservedObject var viewModel: GameViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Reveal")
                .font(.title)
                .fontWeight(.bold)
                .padding()
            
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(viewModel.responses) { response in
                        RevealBubble(
                            response: response,
                            players: viewModel.room?.players ?? [],
                            isReal: response.isReal
                        )
                    }
                }
                .padding()
            }
            
            if let realResponse = viewModel.responses.first(where: { $0.isReal }) {
                VStack(spacing: 8) {
                    Text("The Real Response:")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text(realResponse.text)
                        .font(.body)
                        .padding()
                        .background(Color.green.opacity(0.2))
                        .cornerRadius(12)
                }
                .padding()
            }
        }
    }
}

struct RevealBubble: View {
    let response: GameResponse
    let players: [Player]
    let isReal: Bool
    
    var playerName: String {
        guard let playerId = response.playerId else { return "Unknown" }
        let player = players.first { $0.id == playerId }
        return player?.displayName ?? player?.username ?? "Unknown"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(playerName)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                
                if isReal {
                    Text("REAL")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.green)
                        .cornerRadius(4)
                }
                
                Spacer()
                
                Text("\(response.voteCount) vote\(response.voteCount == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Spacer()
                
                Text(response.text)
                    .font(.body)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(isReal ? Color.green : Color.gray)
                    .cornerRadius(18)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

