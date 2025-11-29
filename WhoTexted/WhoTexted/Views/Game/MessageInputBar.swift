//
//  MessageInputBar.swift
//  WhoTexted
//
//  Created by Andrew Kim on 11/29/25.
//

import Foundation
import SwiftUI

struct MessageInputBar: View {
    @Binding var text: String
    var onSend: () -> Void

    var body: some View {
        HStack {
            TextField("Type...", text: $text)
                .textFieldStyle(.roundedBorder)

            Button("Send") {
                onSend()
            }
            .disabled(text.isEmpty)
        }
        .padding(.top, 8)
    }
}
