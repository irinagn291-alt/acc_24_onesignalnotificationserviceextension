import CoreData
import Foundation

extension DayListEntity {
    @nonobjc class func fetchRequest() -> NSFetchRequest<DayListEntity> {
        NSFetchRequest<DayListEntity>(entityName: "DayListEntity")
    }

    @NSManaged var listUUID: UUID
    @NSManaged var dayStart: Date
}
