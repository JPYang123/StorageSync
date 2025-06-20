// Box.swift
import Foundation
import CloudKit

struct Box: Identifiable {
    let id: CKRecord.ID; var title: String; var createdAt: Date
    init(record: CKRecord) {
        id = record.recordID
        title = record["title"] as? String ?? ""
        createdAt = record.creationDate ?? Date()
    }
    init(title: String) { id = CKRecord.ID(recordName: UUID().uuidString); self.title = title; createdAt = Date() }
    func toRecord() -> CKRecord {
        let r = CKRecord(recordType: "Box", recordID: id)
        r["title"] = title as NSString
        return r
    }
}
