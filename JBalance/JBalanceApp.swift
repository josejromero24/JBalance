//
//  JBalanceApp.swift
//  JBalance
//
//  Created by JJ Romero Alvarez on 10/05/2026.
//

import SwiftUI
import CoreData

@main
struct JBalanceApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
