import Foundation
import CloudKit

final class CloudKitService {
    static let shared = CloudKitService()
    private let container: CKContainer
    private let database: CKDatabase

    private init(container: CKContainer = CloudKitConfig.container) {
        self.container = container
        self.database = container.publicCloudDatabase
    }

    /// 创建新记录
    func createRecord(recordType: String,
                      fields: [String: CKRecordValue],
                      completion: @escaping (Result<CKRecord, Error>) -> Void) {
        DebugLogger.log("Create record type: \(recordType) fields: \(fields)")
        let record = CKRecord(recordType: recordType)
        fields.forEach { record[$0] = $1 }
        database.save(record) { savedRecord, error in
            if let error = error {
                DebugLogger.log("Create error: \(error)")
                completion(.failure(error))
            } else if let savedRecord = savedRecord {
                DebugLogger.log("Create success id: \(savedRecord.recordID)")
                completion(.success(savedRecord))
            }
        }
    }

    /// 查询记录
    func fetchRecords(recordType: String,
                      predicate: NSPredicate = NSPredicate(value: true),
                      completion: @escaping (Result<[CKRecord], Error>) -> Void) {
        DebugLogger.log("Fetch records type: \(recordType) predicate: \(predicate)")
        let query = CKQuery(recordType: recordType, predicate: predicate)
        let operation = CKQueryOperation(query: query)
        var results: [CKRecord] = []

        operation.recordFetchedBlock = { record in
            DebugLogger.log("Fetched record id: \(record.recordID)")
            results.append(record)
        }
        operation.queryCompletionBlock = { _, error in
            if let error = error {
                DebugLogger.log("Fetch error: \(error)")
                completion(.failure(error))
            } else {
                DebugLogger.log("Fetch success count: \(results.count)")
                completion(.success(results))
            }
        }

        database.add(operation)
    }

    /// 更新记录
    func updateRecord(_ record: CKRecord,
                      with fields: [String: CKRecordValue],
                      completion: @escaping (Result<CKRecord, Error>) -> Void) {
        DebugLogger.log("Update record id: \(record.recordID)")
        fields.forEach { record[$0] = $1 }
        let modifyOp = CKModifyRecordsOperation(recordsToSave: [record],
                                                 recordIDsToDelete: nil)
        modifyOp.modifyRecordsCompletionBlock = { saved, _, error in
            if let error = error {
                DebugLogger.log("Update error: \(error)")
                completion(.failure(error))
            } else if let savedRecord = saved?.first {
                DebugLogger.log("Update success id: \(savedRecord.recordID)")
                completion(.success(savedRecord))
            }
        }
        database.add(modifyOp)
    }

    /// 删除记录
    func deleteRecord(recordID: CKRecord.ID,
                      completion: @escaping (Result<CKRecord.ID, Error>) -> Void) {
        DebugLogger.log("Delete record id: \(recordID)")
        database.delete(withRecordID: recordID) { deletedID, error in
            if let error = error {
                DebugLogger.log("Delete error: \(error)")
                completion(.failure(error))
            } else if let deletedID = deletedID {
                DebugLogger.log("Delete success id: \(deletedID)")
                completion(.success(deletedID))
            }
        }
    }
}
