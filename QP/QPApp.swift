//
//  QPApp.swift
//  QP
//
//  Created by Vijay on 11/27/25.
//

import SwiftUI

@main
struct QPApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
