// Item.swift
import Foundation
import CloudKit

struct Item: Identifiable {
    let id: CKRecord.ID; var name: String; var boxRef: CKRecord.ID
    init(record: CKRecord) {
        id = record.recordID
        name = record["name"] as? String ?? ""
        if let ref = record["box"] as? CKRecord.Reference {
            boxRef = ref.recordID
        } else {
            // Generate a dummy ID to avoid empty reference crashes
            boxRef = CKRecord.ID(recordName: UUID().uuidString)
        }
    }
    init(name: String, boxRef: CKRecord.ID) {
        id = CKRecord.ID(recordName: UUID().uuidString); self.name = name; self.boxRef = boxRef
    }
    func toRecord() -> CKRecord {
        let r = CKRecord(recordType: "Item", recordID: id)
        r["name"] = name as NSString
        r["box"] = CKRecord.Reference(recordID: boxRef, action: .deleteSelf)
        return r
    }
}
