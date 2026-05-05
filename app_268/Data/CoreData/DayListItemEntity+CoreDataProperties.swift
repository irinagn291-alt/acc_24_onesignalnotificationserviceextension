import CoreData
import Foundation

extension DayListItemEntity {
    @nonobjc class func fetchRequest() -> NSFetchRequest<DayListItemEntity> {
        NSFetchRequest<DayListItemEntity>(entityName: "DayListItemEntity")
    }

    @NSManaged var itemUUID: UUID
    @NSManaged var listUUID: UUID
    @NSManaged var sortIndex: Int32
    @NSManaged var barcode: String
    @NSManaged var brand: String?
    @NSManaged var imageURLString: String?
    @NSManaged var name: String?
    @NSManaged var nutriScore: String?
    @NSManaged var addedAt: Date
}
