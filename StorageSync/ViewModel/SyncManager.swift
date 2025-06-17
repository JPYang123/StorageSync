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
        let model = Self.makeModel()
        container = NSPersistentCloudKitContainer(name: "StorageSyncModel", managedObjectModel: model)
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

    private static func makeModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()

        // MARK: Box entity
        let boxEntity = NSEntityDescription()
        boxEntity.name = "Box"
        boxEntity.managedObjectClassName = NSStringFromClass(Box.self)

        let boxId = NSAttributeDescription()
        boxId.name = "id"
        boxId.attributeType = .UUIDAttributeType
        boxId.isOptional = true

        let boxTitle = NSAttributeDescription()
        boxTitle.name = "title"
        boxTitle.attributeType = .stringAttributeType
        boxTitle.isOptional = true

        let boxBarcode = NSAttributeDescription()
        boxBarcode.name = "barcode"
        boxBarcode.attributeType = .stringAttributeType
        boxBarcode.isOptional = true

        let boxShare = NSAttributeDescription()
        boxShare.name = "ckShare"
        boxShare.attributeType = .transformableAttributeType
        boxShare.attributeValueClassName = NSStringFromClass(CKShare.self)
        boxShare.valueTransformerName = NSValueTransformerName.secureUnarchiveFromDataTransformerName.rawValue
        boxShare.isOptional = true

        // MARK: Item entity
        let itemEntity = NSEntityDescription()
        itemEntity.name = "Item"
        itemEntity.managedObjectClassName = NSStringFromClass(Item.self)

        let itemId = NSAttributeDescription()
        itemId.name = "id"
        itemId.attributeType = .UUIDAttributeType
        itemId.isOptional = true

        let itemName = NSAttributeDescription()
        itemName.name = "name"
        itemName.attributeType = .stringAttributeType
        itemName.isOptional = true

        let itemNote = NSAttributeDescription()
        itemNote.name = "note"
        itemNote.attributeType = .stringAttributeType
        itemNote.isOptional = true

        // MARK: Photo entity
        let photoEntity = NSEntityDescription()
        photoEntity.name = "Photo"
        photoEntity.managedObjectClassName = NSStringFromClass(Photo.self)

        let photoId = NSAttributeDescription()
        photoId.name = "id"
        photoId.attributeType = .UUIDAttributeType
        photoId.isOptional = true

        let photoURL = NSAttributeDescription()
        photoURL.name = "localURL"
        photoURL.attributeType = .URIAttributeType
        photoURL.isOptional = true

        // Relationships setup
        let itemParent = NSRelationshipDescription()
        itemParent.name = "parent"
        itemParent.destinationEntity = boxEntity
        itemParent.minCount = 1
        itemParent.maxCount = 1
        itemParent.deleteRule = .nullifyDeleteRule

        let photoBox = NSRelationshipDescription()
        photoBox.name = "box"
        photoBox.destinationEntity = boxEntity
        photoBox.minCount = 1
        photoBox.maxCount = 1
        photoBox.deleteRule = .nullifyDeleteRule

        let boxItems = NSRelationshipDescription()
        boxItems.name = "items"
        boxItems.destinationEntity = itemEntity
        boxItems.minCount = 0
        boxItems.maxCount = 0
        boxItems.deleteRule = .cascadeDeleteRule

        let boxPhotos = NSRelationshipDescription()
        boxPhotos.name = "photos"
        boxPhotos.destinationEntity = photoEntity
        boxPhotos.minCount = 0
        boxPhotos.maxCount = 0
        boxPhotos.deleteRule = .cascadeDeleteRule

        // Inverse relationships
        itemParent.inverseRelationship = boxItems
        boxItems.inverseRelationship = itemParent

        photoBox.inverseRelationship = boxPhotos
        boxPhotos.inverseRelationship = photoBox

        // Assign properties
        boxEntity.properties = [boxId, boxTitle, boxBarcode, boxShare, boxItems, boxPhotos]
        itemEntity.properties = [itemId, itemName, itemNote, itemParent]
        photoEntity.properties = [photoId, photoURL, photoBox]

        model.entities = [boxEntity, itemEntity, photoEntity]
        return model
    }
}
