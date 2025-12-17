//
//  InstructionsView.swift
//  WhoTexted
//
//  Created by Andrew Kim on 12/17/25.
//

import Foundation
import SwiftUI

struct InstructionsView: View {
    let targetPlayerName: String?
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Respond as \(targetPlayerName ?? "target player")")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Wait for the incoming message...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

#Preview {
    InstructionsView(targetPlayerName: "Alice")
}
