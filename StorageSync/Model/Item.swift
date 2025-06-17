// Item.swift
import Foundation
import CoreData

class Item: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var name: String
    @NSManaged var note: String?
    @NSManaged var parent: Box
}
