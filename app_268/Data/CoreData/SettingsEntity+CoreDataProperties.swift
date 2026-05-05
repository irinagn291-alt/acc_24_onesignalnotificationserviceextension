import CoreData
import Foundation

extension SettingsEntity {
    @nonobjc class func fetchRequest() -> NSFetchRequest<SettingsEntity> {
        NSFetchRequest<SettingsEntity>(entityName: "SettingsEntity")
    }

    @NSManaged var appLanguageCode: String?
    @NSManaged var singletonSlot: Int16
    @NSManaged var onboardingCompleted: Bool
    @NSManaged var openFoodFactsHost: String
    @NSManaged var useMetricUnits: Bool
}
