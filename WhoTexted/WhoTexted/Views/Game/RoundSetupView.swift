//
//  RoundSetupView.swift
//  WhoTexted
//
//  Created by Andrew Kim on 12/2/25.
//

import SwiftUI

struct RoundSetupView: View {
    let targetPlayerName: String?
    let promptSenderName: String?
    let role: RoundRole?
    let roundNumber: Int
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Round \(roundNumber)")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Starting...")
                .font(.title2)
                .foregroundColor(.gray)
            
            if let target = targetPlayerName {
                VStack(spacing: 8) {
                    Text("You are impersonating:")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text(target)
                        .font(.title)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)
            }
            
            if let sender = promptSenderName {
                Text("Message from: \(sender)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            if let role = role {
                VStack(spacing: 8) {
                    Text("Your Role:")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text(role == .realImpersonator ? "Real Impersonator" : "Fake Responder")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(role == .realImpersonator ? .green : .orange)
                }
                .padding()
                .background(role == .realImpersonator ? Color.green.opacity(0.1) : Color.orange.opacity(0.1))
                .cornerRadius(12)
                
                Text(role == .realImpersonator 
                     ? "Write an authentic response as this person would."
                     : "Write a believable fake response to mislead others.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
        .padding()
    }
}

