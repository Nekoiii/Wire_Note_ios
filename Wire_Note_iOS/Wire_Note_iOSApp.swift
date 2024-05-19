//
//  Wire_Note_iOSApp.swift
//  Wire_Note_iOS
//
//  Created by John Smith on 2024/05/19.
//

import SwiftUI

@main
struct Wire_Note_iOSApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
