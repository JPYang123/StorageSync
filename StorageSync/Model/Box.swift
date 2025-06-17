import Foundation
import CoreData
import CloudKit

class Box: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var title: String
    @NSManaged var barcode: String?
    @NSManaged var items: Set<Item>
    @NSManaged var photos: Set<Photo>
    @NSManaged var ckShare: CKShare?   // CKShare 支持
}
