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

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
