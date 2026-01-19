//
//  MyMeditationPalApp.swift
//  MyMeditationPal
//
//  Created by   on 1/18/26.
//

import SwiftUI

@main
struct MyMeditationPalApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
