//
//  QPApp.swift
//  QP
//
//  Created by Vijay on 11/27/25.
//

import SwiftUI

@main
struct QPApp: App {
    @StateObject private var appState = AppState()
    let persistenceController = PersistenceController.shared

    init() {
        configureURLCache()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
    
    private func configureURLCache() {
        let memory = 60 * 1024 * 1024
        let disk = 250 * 1024 * 1024
        URLCache.shared.memoryCapacity = memory
        URLCache.shared.diskCapacity = disk
    }
}
