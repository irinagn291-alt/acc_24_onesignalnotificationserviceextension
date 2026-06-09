import CoreData
import Foundation

extension CachedProductEntity {
    @nonobjc class func fetchRequest() -> NSFetchRequest<CachedProductEntity> {
        NSFetchRequest<CachedProductEntity>(entityName: "CachedProductEntity")
    }

    @NSManaged var barcode: String
    @NSManaged var cachedAt: Date
    @NSManaged var payloadJSON: Data
}
