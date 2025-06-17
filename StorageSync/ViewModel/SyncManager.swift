// SyncManager.swift
import Foundation
import CoreData
import CloudKit

final class SyncManager {
    static let shared = SyncManager()
    let container: NSPersistentCloudKitContainer
    private let ckContainer = CKContainer.default()
    private let subscriptionID = "com.yourapp.familysync"

    private init() {
        container = NSPersistentCloudKitContainer(name: "StorageSyncModel")
        let desc = container.persistentStoreDescriptions.first
        desc?.setOption(true as NSNumber,
                        forKey: NSPersistentHistoryTrackingKey)
        desc?.setOption(true as NSNumber,
                        forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)

        container.loadPersistentStores { _, error in
            if let error = error { fatalError("Store load error: \(error)") }
        }
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleRemoteChange),
            name: .NSPersistentStoreRemoteChange,
            object: container.persistentStoreCoordinator
        )
        registerSubscription()
    }

    @objc private func handleRemoteChange(_ note: Notification) {
        container.viewContext.perform {
            self.container.viewContext.mergeChanges(fromContextDidSave: note)
        }
    }

    private func registerSubscription() {
        let sub = CKDatabaseSubscription(subscriptionID: subscriptionID)
        let info = CKSubscription.NotificationInfo()
        info.shouldSendContentAvailable = true
        sub.notificationInfo = info

        let op = CKModifySubscriptionsOperation(
            subscriptionsToSave: [sub],
            subscriptionIDsToDelete: []
        )
        ckContainer.privateCloudDatabase.add(op)
    }

    func saveContext() {
        let ctx = container.viewContext
        guard ctx.hasChanges else { return }
        do { try ctx.save() }
        catch { print("Save error: \(error)") }
    }
}
