// StorageSyncApp.swift
import SwiftUI
import UIKit

@main
struct StorageSyncApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    var body: some Scene {
        WindowGroup { BoxListView() }
    }
}
