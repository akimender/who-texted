//
//  PromptCard.swift
//  WhoTexted
//
//  Created by Andrew Kim on 11/29/25.
//

import Foundation
import SwiftUI

struct PromptCard: View {
    let prompt: Prompt

    var body: some View {
        Text(prompt.text)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(12)
            .padding(.bottom, 10)
    }
}
