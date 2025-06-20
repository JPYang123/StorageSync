// Item.swift
import Foundation
import CloudKit

struct Item: Identifiable {
    let id: CKRecord.ID; var name: String; var boxRef: CKRecord.ID
    init(record: CKRecord) {
        id = record.recordID
        name = record["name"] as? String ?? ""
        boxRef = (record["box"] as? CKRecord.Reference)?.recordID ?? CKRecord.ID(recordName: "")
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
