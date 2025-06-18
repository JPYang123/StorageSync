//
//  StorageSyncApp.swift
//  StorageSync
//
//  Created by Jiping Yang on 6/16/25.
//

import SwiftUI
import UIKit

@main
struct StorageSyncApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            BoxListView()
        }
    }
}
