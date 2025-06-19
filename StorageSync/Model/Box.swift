// Box.swift
import Foundation
import CoreData
import CloudKit

@objc(Box)
class Box: NSManagedObject {
    @NSManaged var id: UUID?
    @NSManaged var title: String?
    @NSManaged var barcode: String?
    @NSManaged var items: Set<Item>
    @NSManaged var photos: Set<Photo>
    @NSManaged var ckShare: CKShare?
    
    override func awakeFromInsert() {
        super.awakeFromInsert()
        if id == nil {
            id = UUID()
        }
        if title == nil {
            title = ""
        }
    }
}
