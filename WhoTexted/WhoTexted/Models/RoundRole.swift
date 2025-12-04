//
//  RoundRole.swift
//  WhoTexted
//
//  Created by Andrew Kim on 12/2/25.
//

import Foundation

enum RoundRole: String, Codable {
    case realImpersonator = "real_impersonator"
    case fakeResponder = "fake_responder"
    case none
}

