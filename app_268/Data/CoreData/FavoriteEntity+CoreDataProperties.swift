import CoreData
import Foundation

extension FavoriteEntity {
    @nonobjc class func fetchRequest() -> NSFetchRequest<FavoriteEntity> {
        NSFetchRequest<FavoriteEntity>(entityName: "FavoriteEntity")
    }

    @NSManaged var addedAt: Date
    @NSManaged var barcode: String
    @NSManaged var brand: String?
    @NSManaged var imageURLString: String?
    @NSManaged var name: String?
    @NSManaged var nutriScore: String?
}
