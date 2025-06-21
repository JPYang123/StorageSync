// Photo.swift
import Foundation
import CloudKit

struct Photo: Identifiable {
    let id: CKRecord.ID; var asset: CKAsset; var boxRef: CKRecord.ID
    init(record: CKRecord) {
        id = record.recordID
        asset = record["image"] as! CKAsset
        if let ref = record["box"] as? CKRecord.Reference {
            boxRef = ref.recordID
        } else {
            boxRef = CKRecord.ID(recordName: UUID().uuidString)
        }
    }
    init(imageURL: URL, boxRef: CKRecord.ID) {
        id = CKRecord.ID(recordName: UUID().uuidString)
        asset = CKAsset(fileURL: imageURL)
        self.boxRef = boxRef
    }
    func toRecord() -> CKRecord {
        let r = CKRecord(recordType: "Photo", recordID: id)
        r["image"] = asset
        r["box"] = CKRecord.Reference(recordID: boxRef, action: .deleteSelf)
        return r
    }
}
