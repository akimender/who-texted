//
//  ResponseSubmissionView.swift
//  WhoTexted
//
//  Created by Andrew Kim on 12/2/25.
//

import SwiftUI

struct ResponseSubmissionView: View {
    @ObservedObject var viewModel: GameViewModel
    let targetPlayerName: String?
    
    var body: some View {
        VStack(spacing: 20) {
            if let target = targetPlayerName {
                Text("Respond as \(target):")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            
            TextEditor(text: $viewModel.myResponse)
                .frame(height: 120)
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
                .disabled(viewModel.hasSubmitted)
            
            Text("\(viewModel.myResponse.count) / 200 characters")
                .font(.caption)
                .foregroundColor(viewModel.myResponse.count > 200 ? .red : .secondary)
            
            Button(action: {
                viewModel.submitResponse()
            }) {
                Text(viewModel.hasSubmitted ? "Submitted ✓" : "Submit Response")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(viewModel.hasSubmitted || viewModel.myResponse.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.myResponse.count > 200
                                ? Color.gray 
                                : Color.blue)
                    .cornerRadius(12)
            }
            .disabled(viewModel.hasSubmitted || viewModel.myResponse.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.myResponse.count > 200)
            
            if viewModel.allSubmitted {
                Text("All players have submitted!")
                    .font(.subheadline)
                    .foregroundColor(.green)
                    .padding()
            } else if viewModel.hasSubmitted {
                Text("Waiting for other players...")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .padding()
            }
        }
        .padding()
    }
}

