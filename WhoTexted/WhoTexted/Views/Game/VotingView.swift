//
//  VotingView.swift
//  WhoTexted
//
//  Created by Andrew Kim on 12/2/25.
//

import SwiftUI

struct VotingView: View {
    @ObservedObject var viewModel: GameViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Which response is the real one?")
                .font(.title2)
                .fontWeight(.semibold)
                .padding()
            
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(viewModel.responses) { response in
                        ResponseBubble(
                            text: response.text,
                            isSelected: viewModel.selectedVoteResponseId == response.id,
                            onTap: {
                                if !viewModel.hasVoted {
                                    viewModel.selectedVoteResponseId = response.id
                                }
                            }
                        )
                    }
                }
                .padding()
            }
            
            Button(action: {
                viewModel.submitVote()
            }) {
                Text(viewModel.hasVoted ? "Voted ✓" : "Submit Vote")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(viewModel.hasVoted || viewModel.selectedVoteResponseId == nil
                                ? Color.gray
                                : Color.blue)
                    .cornerRadius(12)
            }
            .disabled(viewModel.hasVoted || viewModel.selectedVoteResponseId == nil)
            .padding(.horizontal)
            
            if viewModel.allVoted {
                Text("All players have voted!")
                    .font(.subheadline)
                    .foregroundColor(.green)
                    .padding()
            } else if viewModel.hasVoted {
                Text("Waiting for other players...")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .padding()
            }
        }
    }
}

struct ResponseBubble: View {
    let text: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        HStack {
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(text)
                    .font(.body)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(isSelected ? Color.green : Color.gray)
                    .cornerRadius(18)
            }
            .padding(.horizontal)
            .onTapGesture {
                onTap()
            }
        }
    }
}

