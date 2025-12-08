//
//  AppRouter.swift
//  WhoTexted
//
//  Created by Andrew Kim on 12/8/25.
//

import Foundation

@MainActor
class AppRouter: ObservableObject {
    @Published var route: AppRoute = .home
    
    func navigateToLobby(roomId: String) {
        route = .lobby(roomId: roomId)
    }
    
    func navigateToGame(roomId: String) {
        route = .game(roomId: roomId)
    }
    
    func navigateToHome() {
        route = .home
    }
}

enum AppRoute {
    case home
    case lobby(roomId: String)
    case game(roomId: String)
}
