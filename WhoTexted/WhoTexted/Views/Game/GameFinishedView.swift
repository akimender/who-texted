//
//  GameFinishedView.swift
//  WhoTexted
//
//  Created by Andrew Kim on 12/2/25.
//

import SwiftUI

struct GameFinishedView: View {
    @ObservedObject var viewModel: GameViewModel
    @EnvironmentObject var router: AppRouter
    @EnvironmentObject var session: SessionModel
    
    var body: some View {
        VStack(spacing: 30) {
            Text("Game Over!")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding()
            
            if let winner = viewModel.winner {
                VStack(spacing: 12) {
                    Text("Winner:")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text(winner.displayName ?? winner.username)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    
                    Text("\(winner.points) points")
                        .font(.title2)
                        .foregroundColor(.green)
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(16)
            }
            
            Text("Final Scores")
                .font(.title2)
                .fontWeight(.semibold)
            
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(viewModel.room?.players.sorted(by: { ($0.points) > ($1.points) }) ?? [], id: \.id) { player in
                        FinalScoreRow(
                            player: player,
                            isWinner: player.id == viewModel.winner?.id
                        )
                    }
                }
                .padding()
            }
            
            Button(action: {
                // Navigate back to home
                session.clearSession()
                router.navigateToHome()
            }) {
                Text("Back to Home")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
        }
        .padding()
    }
}

struct FinalScoreRow: View {
    let player: Player
    let isWinner: Bool
    
    var body: some View {
        HStack {
            Text(player.displayName ?? player.username)
                .font(.body)
                .fontWeight(isWinner ? .bold : .regular)
            Spacer()
            Text("\(player.points) pts")
                .font(.body)
                .fontWeight(.semibold)
                .foregroundColor(isWinner ? .green : .primary)
        }
        .padding()
        .background(isWinner ? Color.green.opacity(0.2) : Color(.systemGray6))
        .cornerRadius(8)
    }
}

