// Photo.swift
import Foundation
import CoreData

@objc(Photo)
class Photo: NSManagedObject {
    @NSManaged var id: UUID?
    @NSManaged var localURL: URL?
    @NSManaged var box: Box?
    
    override func awakeFromInsert() {
        super.awakeFromInsert()
        if id == nil {
            id = UUID()
        }
    }
}
