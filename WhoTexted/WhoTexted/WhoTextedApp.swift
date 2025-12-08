//
//  WhoTextedApp.swift
//  WhoTexted
//
//  Created by Andrew Kim on 11/27/25.
//

import SwiftUI

@main
struct WhoTextedApp: App {
    @StateObject var router = AppRouter()
    @StateObject var session = SessionModel()
    @StateObject var gameVM = GameViewModel()
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(router)
                .environmentObject(session)
                .environmentObject(gameVM)
        }
    }
}
