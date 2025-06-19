// Item.swift
import Foundation
import CoreData

@objc(Item)
class Item: NSManagedObject {
    @NSManaged var id: UUID?
    @NSManaged var name: String?
    @NSManaged var note: String?
    @NSManaged var parent: Box?
    
    override func awakeFromInsert() {
        super.awakeFromInsert()
        if id == nil {
            id = UUID()
        }
        if name == nil {
            name = ""
        }
    }
}
