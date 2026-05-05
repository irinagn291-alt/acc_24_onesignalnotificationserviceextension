import CoreData
import Foundation

extension HistoryItemEntity {
    @nonobjc class func fetchRequest() -> NSFetchRequest<HistoryItemEntity> {
        NSFetchRequest<HistoryItemEntity>(entityName: "HistoryItemEntity")
    }

    @NSManaged var barcode: String
    @NSManaged var brand: String?
    @NSManaged var itemUUID: UUID
    @NSManaged var imageURLString: String?
    @NSManaged var name: String?
    @NSManaged var viewedAt: Date
}
