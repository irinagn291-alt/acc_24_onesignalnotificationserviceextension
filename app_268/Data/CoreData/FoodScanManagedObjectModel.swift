import CoreData
import Foundation

enum FoodScanManagedObjectModel {
    static func make() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()
        model.entities = [
            cachedProductEntity,
            dayListEntity,
            dayListItemEntity,
            favoriteEntity,
            historyItemEntity,
            settingsEntity,
        ]
        return model
    }

    private static var dayListEntity: NSEntityDescription {
        let e = NSEntityDescription()
        e.name = "DayListEntity"
        e.managedObjectClassName = NSStringFromClass(DayListEntity.self)
        e.properties = [
            uuid("listUUID", optional: false),
            date("dayStart", optional: false),
        ]
        return e
    }

    private static var dayListItemEntity: NSEntityDescription {
        let e = NSEntityDescription()
        e.name = "DayListItemEntity"
        e.managedObjectClassName = NSStringFromClass(DayListItemEntity.self)
        e.properties = [
            uuid("itemUUID", optional: false),
            uuid("listUUID", optional: false),
            int32("sortIndex", optional: false, default: 0),
            string("barcode", optional: false),
            string("brand", optional: true),
            string("imageURLString", optional: true),
            string("name", optional: true),
            string("nutriScore", optional: true),
            date("addedAt", optional: false),
        ]
        return e
    }

    private static var cachedProductEntity: NSEntityDescription {
        let e = NSEntityDescription()
        e.name = "CachedProductEntity"
        e.managedObjectClassName = NSStringFromClass(CachedProductEntity.self)
        e.properties = [
            string("barcode", optional: false),
            date("cachedAt", optional: false),
            data("payloadJSON", optional: false),
        ]
        return e
    }

    private static var favoriteEntity: NSEntityDescription {
        let e = NSEntityDescription()
        e.name = "FavoriteEntity"
        e.managedObjectClassName = NSStringFromClass(FavoriteEntity.self)
        e.properties = [
            date("addedAt", optional: false),
            string("barcode", optional: false),
            string("brand", optional: true),
            string("imageURLString", optional: true),
            string("name", optional: true),
            string("nutriScore", optional: true),
        ]
        return e
    }

    private static var historyItemEntity: NSEntityDescription {
        let e = NSEntityDescription()
        e.name = "HistoryItemEntity"
        e.managedObjectClassName = NSStringFromClass(HistoryItemEntity.self)
        e.properties = [
            string("barcode", optional: false),
            string("brand", optional: true),
            uuid("itemUUID", optional: false),
            string("imageURLString", optional: true),
            string("name", optional: true),
            date("viewedAt", optional: false),
        ]
        return e
    }

    private static var settingsEntity: NSEntityDescription {
        let e = NSEntityDescription()
        e.name = "SettingsEntity"
        e.managedObjectClassName = NSStringFromClass(SettingsEntity.self)
        e.properties = [
            string("appLanguageCode", optional: true),
            int16("singletonSlot", optional: false, default: 0),
            bool("onboardingCompleted", optional: false, default: false),
            string("openFoodFactsHost", optional: false, default: "world.openfoodfacts.org"),
            bool("useMetricUnits", optional: false, default: true),
        ]
        return e
    }

    private static func string(_ name: String, optional: Bool, default defaultValue: String? = nil) -> NSAttributeDescription {
        let a = NSAttributeDescription()
        a.name = name
        a.attributeType = .stringAttributeType
        a.isOptional = optional
        a.defaultValue = defaultValue as NSString?
        return a
    }

    private static func date(_ name: String, optional: Bool) -> NSAttributeDescription {
        let a = NSAttributeDescription()
        a.name = name
        a.attributeType = .dateAttributeType
        a.isOptional = optional
        return a
    }

    private static func data(_ name: String, optional: Bool) -> NSAttributeDescription {
        let a = NSAttributeDescription()
        a.name = name
        a.attributeType = .binaryDataAttributeType
        a.isOptional = optional
        return a
    }

    private static func uuid(_ name: String, optional: Bool) -> NSAttributeDescription {
        let a = NSAttributeDescription()
        a.name = name
        a.attributeType = .UUIDAttributeType
        a.isOptional = optional
        return a
    }

    private static func int16(_ name: String, optional: Bool, default defaultValue: Int16) -> NSAttributeDescription {
        let a = NSAttributeDescription()
        a.name = name
        a.attributeType = .integer16AttributeType
        a.isOptional = optional
        a.defaultValue = NSNumber(value: defaultValue)
        return a
    }

    private static func int32(_ name: String, optional: Bool, default defaultValue: Int32) -> NSAttributeDescription {
        let a = NSAttributeDescription()
        a.name = name
        a.attributeType = .integer32AttributeType
        a.isOptional = optional
        a.defaultValue = NSNumber(value: defaultValue)
        return a
    }

    private static func bool(_ name: String, optional: Bool, default defaultValue: Bool) -> NSAttributeDescription {
        let a = NSAttributeDescription()
        a.name = name
        a.attributeType = .booleanAttributeType
        a.isOptional = optional
        a.defaultValue = NSNumber(value: defaultValue)
        return a
    }
}
