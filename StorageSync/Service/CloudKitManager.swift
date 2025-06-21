// CloudKitManager.swift
import Foundation
import CloudKit

final class CloudKitManager {
    static let shared = CloudKitManager()
    private let db = CKContainer.default().publicCloudDatabase

    // Cache all items locally for search
    private var allItemsCache: [Item] = []
    private var lastCacheUpdate = Date.distantPast
    private let cacheTimeout: TimeInterval = 30 // 30 seconds

    private init() {
        subscribe(recordType: "Box", id: "boxes-sub")
        subscribe(recordType: "Item", id: "items-sub")
        subscribe(recordType: "Photo", id: "photos-sub")
    }

    private func subscribe(recordType: String, id: String) {
        let sub = CKQuerySubscription(recordType: recordType,
                                      predicate: NSPredicate(value: true),
                                      subscriptionID: id,
                                      options: [.firesOnRecordCreation, .firesOnRecordUpdate, .firesOnRecordDeletion])
        let info = CKSubscription.NotificationInfo()
        info.shouldSendContentAvailable = true
        sub.notificationInfo = info
        db.save(sub) { _, err in
            if let ck = err as? CKError, ck.code != .serverRejectedRequest {
                print("Subscribe \(recordType) error: \(err!.localizedDescription)")
            }
        }
    }

    func handleRemoteNotification(_ userInfo: [AnyHashable: Any]) {
        guard let recType = (userInfo["_subscriptionID"] as? String) else { return }
        switch recType {
        case "boxes-sub": NotificationCenter.default.post(name: .boxesDidChange, object: nil)
        case "items-sub": NotificationCenter.default.post(name: .itemsDidChange, object: nil)
        case "photos-sub": NotificationCenter.default.post(name: .photosDidChange, object: nil)
        default: break
        }
    }

    // Generic fetch
    private func fetch<T>(recordType: String,
                          predicate: NSPredicate,
                          map: @escaping (CKRecord) -> T,
                          completion: @escaping (Result<[T], Error>) -> Void) {
        let q = CKQuery(recordType: recordType, predicate: predicate)
        let op = CKQueryOperation(query: q)
        var result: [T] = []
        op.recordFetchedBlock = { rec in result.append(map(rec)) }
        op.queryCompletionBlock = { _, err in
            DispatchQueue.main.async {
                if let err = err { completion(.failure(err)) }
                else { completion(.success(result)) }
            }
        }
        db.add(op)
    }

    // Fetch Boxes
    func fetchBoxes(_ completion: @escaping (Result<[Box], Error>) -> Void) {
        fetch(recordType: "Box", predicate: NSPredicate(value: true), map: Box.init, completion: completion)
    }
    
    // Fetch Items
    func fetchItems(for boxID: CKRecord.ID,
                    _ completion: @escaping (Result<[Item], Error>) -> Void) {
        fetch(recordType: "Item",
              predicate: NSPredicate(format: "box == %@", boxID),
              map: Item.init,
              completion: completion)
    }

    /// FIXED: Search items using cache approach (no sorting issues)
    func searchItems(keyword: String, _ completion: @escaping (Result<[Item], Error>) -> Void) {
        let trimmed = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
        print("🔍 Searching for: '\(trimmed)'")
        
        // If cache is fresh, search locally
        if Date().timeIntervalSince(lastCacheUpdate) < cacheTimeout && !allItemsCache.isEmpty {
            print("📋 Using cached search")
            let filtered = filterItemsLocally(keyword: trimmed)
            completion(.success(filtered))
            return
        }
        
        // Otherwise, fetch all items and cache them
        print("🌐 Fetching fresh data for search")
        fetchAllItemsAndCache { [weak self] result in
            switch result {
            case .success:
                let filtered = self?.filterItemsLocally(keyword: trimmed) ?? []
                completion(.success(filtered))
            case .failure(let error):
                print("❌ Fallback search failed: \(error)")
                completion(.failure(error))
            }
        }
    }

    /// FIXED: Fetch without sorting to avoid CloudKit errors
    private func fetchAllItemsAndCache(completion: @escaping (Result<Void, Error>) -> Void) {
        let query = CKQuery(recordType: "Item", predicate: NSPredicate(value: true))
        // REMOVED: query.sortDescriptors - This was causing the "not marked sortable" error
        
        let operation = CKQueryOperation(query: query)
        operation.resultsLimit = 500
        operation.qualityOfService = .userInitiated
        
        var fetchedItems: [Item] = []
        
        operation.recordFetchedBlock = { record in
            guard let name = record["name"] as? String,
                  !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                  record["box"] as? CKRecord.Reference != nil else {
                print("⚠️ Skipping invalid item: \(record.recordID)")
                return
            }
            
            fetchedItems.append(Item(record: record))
        }
        
        operation.queryCompletionBlock = { cursor, error in
            DispatchQueue.main.async { [weak self] in
                if let error = error {
                    print("❌ Failed to fetch items: \(error)")
                    completion(.failure(error))
                } else {
                    print("✅ Cached \(fetchedItems.count) items")
                    self?.allItemsCache = fetchedItems
                    self?.lastCacheUpdate = Date()
                    completion(.success(()))
                }
            }
        }
        
        db.add(operation)
    }

    /// Filter cached items locally
    private func filterItemsLocally(keyword: String) -> [Item] {
        guard !keyword.isEmpty else { return [] }
        
        let filtered = allItemsCache.filter { item in
            item.name.localizedCaseInsensitiveContains(keyword)
        }
        
        print("🔍 Local search found \(filtered.count) items for '\(keyword)'")
        return filtered
    }

    /// Force refresh cache (call this when items are added/modified)
    func refreshItemsCache() {
        lastCacheUpdate = Date.distantPast
        print("🔄 Cache invalidated")
    }

    // Fetch Photos
    func fetchPhotos(for boxID: CKRecord.ID,
                     _ completion: @escaping (Result<[Photo], Error>) -> Void) {
        fetch(recordType: "Photo",
              predicate: NSPredicate(format: "box == %@", boxID),
              map: Photo.init,
              completion: completion)
    }

    // Save Generic
    private func save(_ record: CKRecord,
                      completion: @escaping (Result<CKRecord, Error>) -> Void) {
        db.save(record) { rec, err in
            DispatchQueue.main.async {
                if let rec = rec { completion(.success(rec)) }
                else { completion(.failure(err!)) }
            }
        }
    }

    func saveBox(_ box: Box, _ cb: @escaping (Result<Box, Error>) -> Void) {
        save(box.toRecord()) { res in cb(res.map(Box.init)) }
    }

    func saveItem(_ item: Item, _ cb: @escaping (Result<Item, Error>) -> Void) {
         save(item.toRecord()) { [weak self] res in
             switch res {
             case .success(let record):
                 let savedItem = Item(record: record)
                 self?.refreshItemsCache() // Refresh cache when new item added
                 cb(.success(savedItem))
             case .failure(let error):
                 cb(.failure(error))
             }
         }
     }

    func savePhoto(_ photo: Photo, _ cb: @escaping (Result<Photo, Error>) -> Void) {
        save(photo.toRecord()) { res in cb(res.map(Photo.init)) }
    }

    func delete(recordID: CKRecord.ID, completion: @escaping (Result<CKRecord.ID, Error>) -> Void) {
        db.delete(withRecordID: recordID) { [weak self] id, err in
            DispatchQueue.main.async {
                if let id = id {
                    print("✅ Successfully deleted record \(id.recordName)")
                    self?.refreshItemsCache() // Refresh cache when item deleted
                    completion(.success(id))
                } else if let err = err {
                    print("❌ Failed to delete record \(recordID.recordName): \(err)")
                    completion(.failure(err))
                }
            }
        }
    }

    /// Debug: Print all items in database
    func debugPrintAllItems() {
        fetchAllItemsAndCache { result in
            switch result {
            case .success:
                print("📋 All items in database:")
                for (index, item) in self.allItemsCache.enumerated() {
                    print("  \(index + 1). '\(item.name)' (ID: \(item.id.recordName))")
                }
                if self.allItemsCache.isEmpty {
                    print("  No items found in database!")
                }
            case .failure(let error):
                print("❌ Failed to fetch items: \(error)")
            }
        }
    }

    /// Simple test to verify CloudKit connection
    func testCloudKitConnection(_ completion: @escaping (Bool) -> Void) {
        let testQuery = CKQuery(recordType: "Box", predicate: NSPredicate(value: true))
        let operation = CKQueryOperation(query: testQuery)
        operation.resultsLimit = 1
        
        var hasData = false
        operation.recordFetchedBlock = { _ in hasData = true }
        operation.queryCompletionBlock = { _, error in
            DispatchQueue.main.async {
                if error != nil {
                    print("❌ CloudKit connection failed: \(error!)")
                    completion(false)
                } else {
                    print("✅ CloudKit connection working, has data: \(hasData)")
                    completion(true)
                }
            }
        }
        
        db.add(operation)
    }
}
