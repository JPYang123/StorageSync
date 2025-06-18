// SyncManager.swift
import Foundation
import CoreData
import CloudKit

final class SyncManager {
    static let shared = SyncManager()
    
    let container: NSPersistentCloudKitContainer
    // 如果你有自己封装的 CloudKitConfig，也可以继续用它；这里示例直接用 CKContainer
    private let ckContainer = CKContainer(identifier: "iCloud.com.JPYang.SafePass")
    private let subscriptionID = "com.yourapp.familysync"

    private init() {
        // 1. 初始化 Core Data + 模型
        let model = Self.makeModel()
        container = NSPersistentCloudKitContainer(
            name: "StorageSyncModel",
            managedObjectModel: model
        )

        // 2. 打开第一个 store 描述
        guard let desc = container.persistentStoreDescriptions.first else {
            fatalError("找不到 persistentStoreDescriptions")
        }
        // 开启历史记录和远程变更推送
        desc.setOption(true as NSNumber,
                       forKey: NSPersistentHistoryTrackingKey)
        desc.setOption(true as NSNumber,
                       forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)

        // 3. 为该 store 配置 CloudKit 容器和数据库范围
        if let existingOptions = desc.cloudKitContainerOptions {
            existingOptions.databaseScope = CKDatabase.Scope.private  // ← 改这里
        } else {
            let options = NSPersistentCloudKitContainerOptions(
                containerIdentifier: "iCloud.com.JPYang.SafePass"
            )
            options.databaseScope = CKDatabase.Scope.private          // ← 以及这里
            desc.cloudKitContainerOptions = options
        }

        // 4. 加载 store
        container.loadPersistentStores { _, error in
            if let error = error { fatalError("Store load error: \(error)") }
            DebugLogger.log("Persistent stores loaded")
        }

        // 5. 订阅远程变更通知（注意 selector 要带 ":"）
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleRemoteChange(_:)),
            name: .NSPersistentStoreRemoteChange,
            object: container.persistentStoreCoordinator
        )

        registerSubscription()
    }

    @objc private func handleRemoteChange(_ note: Notification) {
        DebugLogger.log("Remote change received")

        // 1️⃣ 从通知中取出 userInfo
        guard let userInfo = note.userInfo else { return }

        // 2️⃣ 在主线程 context 所在队列合并远程变更
        container.viewContext.perform {
            NSManagedObjectContext.mergeChanges(
                fromRemoteContextSave: userInfo,
                into: [self.container.viewContext]
            )
        }
    }

    private func registerSubscription() {
        let sub = CKDatabaseSubscription(subscriptionID: subscriptionID)
        let info = CKSubscription.NotificationInfo()
        info.shouldSendContentAvailable = true
        info.alertBody = "Storage updated"
        info.soundName = "default"
        sub.notificationInfo = info

        let op = CKModifySubscriptionsOperation(
            subscriptionsToSave: [sub],
            subscriptionIDsToDelete: []
        )
        op.modifySubscriptionsCompletionBlock = { _, _, error in
            if let error = error {
                DebugLogger.log("Subscribe error: \(error)")
            } else {
                DebugLogger.log("Subscription registered")
            }
        }
        ckContainer.privateCloudDatabase.add(op)
    }

    func saveContext() {
        let ctx = container.viewContext
        guard ctx.hasChanges else { return }
        do {
            try ctx.save()
            DebugLogger.log("Context saved")
        } catch {
            DebugLogger.log("Save error: \(error)")
        }
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
