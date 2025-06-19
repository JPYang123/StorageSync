// SyncManager.swift
import Foundation
import CoreData
import CloudKit

final class SyncManager {
    static let shared = SyncManager()
    
    let container: NSPersistentCloudKitContainer
    private let ckContainer = CloudKitConfig.container
    
    private init() {
        let model = Self.createManagedObjectModel()
        container = NSPersistentCloudKitContainer(name: "StorageSyncModel", managedObjectModel: model)
        
        guard let description = container.persistentStoreDescriptions.first else {
            fatalError("Failed to retrieve a persistent store description.")
        }
        
        // Configure for CloudKit
        description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        
        // CloudKit configuration
        let options = NSPersistentCloudKitContainerOptions(containerIdentifier: "iCloud.com.JPYang.SafePass")
        options.databaseScope = .private
        description.cloudKitContainerOptions = options
        
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Store load error: \(error)")
            }
            DebugLogger.log("Persistent stores loaded successfully")
        }
        
        // Configure the view context
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        // Listen for remote changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleRemoteChange),
            name: .NSPersistentStoreRemoteChange,
            object: container.persistentStoreCoordinator
        )
    }
    
    @objc private func handleRemoteChange(_ notification: Notification) {
        DebugLogger.log("Remote change received")
        container.viewContext.perform {
            // Refresh objects from the persistent store
            self.container.viewContext.refreshAllObjects()
        }
    }
    
    @MainActor
    func handleRemoteNotification(_ userInfo: [AnyHashable: Any]) async {
        // Let NSPersistentCloudKitContainer handle the remote notification
        DebugLogger.log("Handling CloudKit remote notification")
        container.viewContext.refreshAllObjects()
    }
    
    func saveContext() {
        let context = container.viewContext
        
        guard context.hasChanges else { return }
        
        do {
            try context.save()
            DebugLogger.log("Context saved successfully")
        } catch {
            DebugLogger.log("Save error: \(error)")
            // Handle the error appropriately
            context.rollback()
        }
    }
    
    // MARK: - Core Data Model Creation
    private static func createManagedObjectModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()
        
        // MARK: - Box Entity
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
        
        // MARK: - Item Entity
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
        
        // MARK: - Photo Entity
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
        
        // MARK: - Relationships
        let itemParent = NSRelationshipDescription()
        itemParent.name = "parent"
        itemParent.destinationEntity = boxEntity
        itemParent.minCount = 0
        itemParent.maxCount = 1
        itemParent.deleteRule = .nullifyDeleteRule
        
        let photoBox = NSRelationshipDescription()
        photoBox.name = "box"
        photoBox.destinationEntity = boxEntity
        photoBox.minCount = 0
        photoBox.maxCount = 1
        photoBox.deleteRule = .nullifyDeleteRule
        
        let boxItems = NSRelationshipDescription()
        boxItems.name = "items"
        boxItems.destinationEntity = itemEntity
        boxItems.minCount = 0
        boxItems.maxCount = 0 // 0 means unlimited
        boxItems.deleteRule = .cascadeDeleteRule
        
        let boxPhotos = NSRelationshipDescription()
        boxPhotos.name = "photos"
        boxPhotos.destinationEntity = photoEntity
        boxPhotos.minCount = 0
        boxPhotos.maxCount = 0 // 0 means unlimited
        boxPhotos.deleteRule = .cascadeDeleteRule
        
        // Set inverse relationships
        itemParent.inverseRelationship = boxItems
        boxItems.inverseRelationship = itemParent
        photoBox.inverseRelationship = boxPhotos
        boxPhotos.inverseRelationship = photoBox
        
        // Assign properties to entities
        boxEntity.properties = [boxId, boxTitle, boxBarcode, boxShare, boxItems, boxPhotos]
        itemEntity.properties = [itemId, itemName, itemNote, itemParent]
        photoEntity.properties = [photoId, photoURL, photoBox]
        
        // Add entities to model
        model.entities = [boxEntity, itemEntity, photoEntity]
        
        return model
    }
}
