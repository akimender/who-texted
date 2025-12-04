//
//  ScoringView.swift
//  WhoTexted
//
//  Created by Andrew Kim on 12/2/25.
//

import SwiftUI

struct ScoringView: View {
    @ObservedObject var viewModel: GameViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Round Scores")
                .font(.title)
                .fontWeight(.bold)
                .padding()
            
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(viewModel.room?.players ?? [], id: \.id) { player in
                        let points = viewModel.roundScores[player.id] ?? 0
                        ScoreRow(
                            player: player,
                            points: points
                        )
                    }
                }
                .padding()
            }
            
            VStack(spacing: 8) {
                Text("Total Scores")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                ForEach(viewModel.room?.players.sorted(by: { ($0.points) > ($1.points) }) ?? [], id: \.id) { player in
                    HStack {
                        Text(player.displayName ?? player.username)
                            .font(.body)
                        Spacer()
                        Text("\(player.points) pts")
                            .font(.body)
                            .fontWeight(.semibold)
                    }
                    .padding(.horizontal)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .padding(.horizontal)
            
            if let currentPlayer = viewModel.room?.players.first(where: { $0.id == AppState.shared.currentPlayerId }),
               currentPlayer.isHost {
                Button(action: {
                    viewModel.nextRound()
                }) {
                    Text("Next Round")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
            } else {
                Text("Waiting for host to start next round...")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .padding()
            }
        }
    }
}

struct ScoreRow: View {
    let player: Player
    let points: Int
    
    var body: some View {
        HStack {
            Text(player.displayName ?? player.username)
                .font(.body)
            Spacer()
            Text("+\(points)")
                .font(.body)
                .fontWeight(.semibold)
                .foregroundColor(points > 0 ? .green : .gray)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

