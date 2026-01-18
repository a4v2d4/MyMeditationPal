//
//  ContentView.swift
//  MyMeditationPal
//
//  Created by Aaron Van Doren on 1/18/26.
//

import SwiftUI
import CoreData

struct ContentView: View {
    var body: some View {
        DashboardView()
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
