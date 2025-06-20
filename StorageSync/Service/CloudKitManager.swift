import Foundation
import CloudKit

// 2. CloudKitManager - use public database and universal subscription
final class CloudKitManager {
    static let shared = CloudKitManager()
    private let db = CKContainer.default().publicCloudDatabase

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
        save(item.toRecord()) { res in cb(res.map(Item.init)) }
    }
    func savePhoto(_ photo: Photo, _ cb: @escaping (Result<Photo, Error>) -> Void) {
        save(photo.toRecord()) { res in cb(res.map(Photo.init)) }
    }

    func delete(recordID: CKRecord.ID,
                completion: @escaping (Result<CKRecord.ID, Error>) -> Void) {
        db.delete(withRecordID: recordID) { id, err in
            DispatchQueue.main.async {
                if let id = id {
                    print("✅ Successfully deleted record \(id.recordName)")
                    completion(.success(id))
                } else if let err = err {
                    print("❌ Failed to delete record \(recordID.recordName): \(err)")
                    completion(.failure(err))
                }
            }
        }
    }
}
