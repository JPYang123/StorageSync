import Foundation
import CloudKit

final class CloudKitService {
    static let shared = CloudKitService()
    private let container: CKContainer
    private let database: CKDatabase

    private init(container: CKContainer = CKContainer.default()) {
        self.container = container
        self.database = container.privateCloudDatabase
    }

    /// 创建新记录
    func createRecord(recordType: String,
                      fields: [String: CKRecordValue],
                      completion: @escaping (Result<CKRecord, Error>) -> Void) {
        let record = CKRecord(recordType: recordType)
        fields.forEach { record[$0] = $1 }
        database.save(record) { savedRecord, error in
            if let error = error {
                completion(.failure(error))
            } else if let savedRecord = savedRecord {
                completion(.success(savedRecord))
            }
        }
    }

    /// 查询记录
    func fetchRecords(recordType: String,
                      predicate: NSPredicate = NSPredicate(value: true),
                      completion: @escaping (Result<[CKRecord], Error>) -> Void) {
        let query = CKQuery(recordType: recordType, predicate: predicate)
        let operation = CKQueryOperation(query: query)
        var results: [CKRecord] = []

        operation.recordFetchedBlock = { record in
            results.append(record)
        }
        operation.queryCompletionBlock = { _, error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(results))
            }
        }

        database.add(operation)
    }

    /// 更新记录
    func updateRecord(_ record: CKRecord,
                      with fields: [String: CKRecordValue],
                      completion: @escaping (Result<CKRecord, Error>) -> Void) {
        fields.forEach { record[$0] = $1 }
        let modifyOp = CKModifyRecordsOperation(recordsToSave: [record],
                                                 recordIDsToDelete: nil)
        modifyOp.modifyRecordsCompletionBlock = { saved, _, error in
            if let error = error {
                completion(.failure(error))
            } else if let savedRecord = saved?.first {
                completion(.success(savedRecord))
            }
        }
        database.add(modifyOp)
    }

    /// 删除记录
    func deleteRecord(recordID: CKRecord.ID,
                      completion: @escaping (Result<CKRecord.ID, Error>) -> Void) {
        database.delete(withRecordID: recordID) { deletedID, error in
            if let error = error {
                completion(.failure(error))
            } else if let deletedID = deletedID {
                completion(.success(deletedID))
            }
        }
    }
}
