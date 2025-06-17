import Foundation
import CoreData

class Photo: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var localURL: URL
    @NSManaged var box: Box
}
