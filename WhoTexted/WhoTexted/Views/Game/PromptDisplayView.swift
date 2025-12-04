//
//  PromptDisplayView.swift
//  WhoTexted
//
//  Created by Andrew Kim on 12/2/25.
//

import SwiftUI

struct PromptDisplayView: View {
    let promptText: String?
    let targetPlayerName: String?
    
    var body: some View {
        VStack(spacing: 20) {
            if let target = targetPlayerName {
                Text("You are responding as:")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Text(target)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
            }
            
            if let prompt = promptText {
                HStack {
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(prompt)
                            .font(.body)
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color.blue)
                            .cornerRadius(18)
                    }
                    .padding(.horizontal)
                }
            }
            
            Text("Get ready to respond...")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .padding()
    }
}

