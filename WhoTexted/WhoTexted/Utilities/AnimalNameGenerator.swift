//
//  AnimalNameGenerator.swift
//  WhoTexted
//
//  Created by Andrew Kim on 11/29/25.
//

import Foundation

struct AnimalNameGenerator {
    
    // Bank of anonymous names to use for users
    static let names = [
        "Panda", "Walrus", "Giraffe", "Otter", "Falcon",
        "Tiger", "Rhino", "Koala", "Hawk", "Lion"
    ]

    // Returns an un-assigned anonymous name
    static func generate(existing: [String]) -> String {
        for name in names {
            if !existing.contains(name) {
                return name
            }
        }
        return "Player\(Int.random(in: 100...999))"
    }
}
