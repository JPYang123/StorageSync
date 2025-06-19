// StorageSyncApp.swift
import SwiftUI
import UIKit

@main
struct StorageSyncApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            BoxListView()
                .environment(\.managedObjectContext, SyncManager.shared.container.viewContext)
        }
    }
}
