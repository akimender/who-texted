//
//  AppState.swift
//  WhoTexted
//
//  Created by Andrew Kim on 12/2/25.
//

import Foundation

enum AppScreen {
    case home
    case lobby(room: Room, player: Player)
    case game(room: Room, player: Player)
}

class AppState: ObservableObject {
    static let shared = AppState()
    @Published var screen: AppScreen = .home
    var currentPlayerId: String? // save player id locally

    private init() {}
}
