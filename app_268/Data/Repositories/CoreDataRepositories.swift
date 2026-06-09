import CoreData
import Foundation

final class SettingsRepository: SettingsStoring {
    private let stack: PersistenceControllerPayload

    init(stack: PersistenceControllerPayload) {
        self.stack = stack
    }

    func ensureBootstrapped() async throws {
        let ctx = stack.viewContext
        try await ctx.perform {
            let fr = SettingsEntity.fetchRequest()
            fr.fetchLimit = 1
            if (try ctx.fetch(fr).first) == nil {
                let s = SettingsEntity(context: ctx)
                s.singletonSlot = 0
                s.onboardingCompleted = false
                s.openFoodFactsHost = OpenFoodFactsRegion.world.host
                s.useMetricUnits = true
                s.appLanguageCode = "en"
                try ctx.save()
            }
        }
    }

    func snapshot() async throws -> AppSettingsSnapshot {
        let ctx = stack.viewContext
        return try await ctx.perform {
            let s = try Self.singleSettings(in: ctx)
            return AppSettingsSnapshot(
                onboardingCompleted: s.onboardingCompleted,
                openFoodFactsHost: s.openFoodFactsHost,
                useMetricUnits: s.useMetricUnits
            )
        }
    }

    func update(_ mutation: @escaping @Sendable (AppSettingsSnapshot) -> AppSettingsSnapshot) async throws {
        let ctx = stack.viewContext
        try await ctx.perform {
            let s = try Self.singleSettings(in: ctx)
            var snap = AppSettingsSnapshot(
                onboardingCompleted: s.onboardingCompleted,
                openFoodFactsHost: s.openFoodFactsHost,
                useMetricUnits: s.useMetricUnits
            )
            snap = mutation(snap)
            s.onboardingCompleted = snap.onboardingCompleted
            s.openFoodFactsHost = snap.openFoodFactsHost
            s.appLanguageCode = "en"
            s.useMetricUnits = snap.useMetricUnits
            if ctx.hasChanges { try ctx.save() }
        }
    }

    private static func singleSettings(in context: NSManagedObjectContext) throws -> SettingsEntity {
        let fr = SettingsEntity.fetchRequest()
        fr.fetchLimit = 1
        if let s = try context.fetch(fr).first {
            if s.openFoodFactsHost == "ru.openfoodfacts.org" {
                s.openFoodFactsHost = OpenFoodFactsRegion.world.host
                try context.save()
            }
            return s
        }
        let s = SettingsEntity(context: context)
        s.singletonSlot = 0
        s.onboardingCompleted = false
        s.openFoodFactsHost = OpenFoodFactsRegion.world.host
        s.useMetricUnits = true
        s.appLanguageCode = "en"
        try context.save()
        return s
    }
}

final class HistoryRepository: HistoryStoring {
    private let stack: PersistenceControllerPayload

    init(stack: PersistenceControllerPayload) {
        self.stack = stack
    }

    func recordView(product: Product) async throws {
        let ctx = stack.viewContext
        try await ctx.perform {
            let fr = HistoryItemEntity.fetchRequest()
            fr.predicate = NSPredicate(format: "barcode == %@", product.barcode)
            let existing = try ctx.fetch(fr).first
            let row = existing ?? HistoryItemEntity(context: ctx)
            if existing == nil { row.itemUUID = UUID() }
            row.barcode = product.barcode
            row.name = product.name
            row.brand = product.brand
            row.imageURLString = product.imageUrl
            row.viewedAt = Date()
            if ctx.hasChanges { try ctx.save() }
        }
    }

    func items() async throws -> [HistoryListItem] {
        let ctx = stack.viewContext
        return try await ctx.perform {
            let fr = HistoryItemEntity.fetchRequest()
            fr.sortDescriptors = [NSSortDescriptor(keyPath: \HistoryItemEntity.viewedAt, ascending: false)]
            return try ctx.fetch(fr).map {
                HistoryListItem(
                    id: $0.itemUUID,
                    barcode: $0.barcode,
                    name: $0.name,
                    brand: $0.brand,
                    imageUrl: $0.imageURLString,
                    viewedAt: $0.viewedAt
                )
            }
        }
    }

    func delete(barcode: String) async throws {
        let ctx = stack.viewContext
        try await ctx.perform {
            let fr = HistoryItemEntity.fetchRequest()
            fr.predicate = NSPredicate(format: "barcode == %@", barcode)
            for o in try ctx.fetch(fr) { ctx.delete(o) }
            if ctx.hasChanges { try ctx.save() }
        }
    }

    func clear() async throws {
        let ctx = stack.viewContext
        try await ctx.perform {
            let fr = HistoryItemEntity.fetchRequest()
            for o in try ctx.fetch(fr) { ctx.delete(o) }
            if ctx.hasChanges { try ctx.save() }
        }
    }

    func search(term: String) async throws -> [HistoryListItem] {
        let t = term.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let all = try await items()
        guard !t.isEmpty else { return all }
        return all.filter { item in
            (item.name ?? "").lowercased().contains(t)
                || (item.brand ?? "").lowercased().contains(t)
                || item.barcode.lowercased().contains(t)
        }
    }
}

final class FavoritesRepository: FavoritesStoring {
    private let stack: PersistenceControllerPayload

    init(stack: PersistenceControllerPayload) {
        self.stack = stack
    }

    func isFavorite(barcode: String) async throws -> Bool {
        let ctx = stack.viewContext
        return try await ctx.perform {
            let fr = FavoriteEntity.fetchRequest()
            fr.fetchLimit = 1
            fr.predicate = NSPredicate(format: "barcode == %@", barcode)
            return try ctx.fetch(fr).first != nil
        }
    }

    func toggle(product: Product) async throws -> Bool {
        let ctx = stack.viewContext
        return try await ctx.perform {
            let fr = FavoriteEntity.fetchRequest()
            fr.fetchLimit = 1
            fr.predicate = NSPredicate(format: "barcode == %@", product.barcode)
            if let e = try ctx.fetch(fr).first {
                ctx.delete(e)
                if ctx.hasChanges { try ctx.save() }
                return false
            }
            let n = FavoriteEntity(context: ctx)
            n.barcode = product.barcode
            n.name = product.name
            n.brand = product.brand
            n.imageURLString = product.imageUrl
            n.nutriScore = product.nutriScore
            n.addedAt = Date()
            try ctx.save()
            return true
        }
    }

    func items() async throws -> [FavoriteListItem] {
        let ctx = stack.viewContext
        return try await ctx.perform {
            let fr = FavoriteEntity.fetchRequest()
            fr.sortDescriptors = [NSSortDescriptor(keyPath: \FavoriteEntity.addedAt, ascending: false)]
            return try ctx.fetch(fr).map {
                FavoriteListItem(
                    barcode: $0.barcode,
                    name: $0.name,
                    brand: $0.brand,
                    imageUrl: $0.imageURLString,
                    nutriScore: $0.nutriScore,
                    addedAt: $0.addedAt
                )
            }
        }
    }

    func remove(barcode: String) async throws {
        let ctx = stack.viewContext
        try await ctx.perform {
            let fr = FavoriteEntity.fetchRequest()
            fr.predicate = NSPredicate(format: "barcode == %@", barcode)
            for o in try ctx.fetch(fr) { ctx.delete(o) }
            if ctx.hasChanges { try ctx.save() }
        }
    }
}

final class CacheRepository: CacheCleaning {
    private let stack: PersistenceControllerPayload

    init(stack: PersistenceControllerPayload) {
        self.stack = stack
    }

    func clearExpiredProductCache(olderThan days: Int) async throws {
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        let ctx = stack.newBackgroundContext()
        try await ctx.perform {
            let fr = CachedProductEntity.fetchRequest()
            fr.predicate = NSPredicate(format: "cachedAt < %@", cutoff as CVarArg)
            for o in try ctx.fetch(fr) { ctx.delete(o) }
            if ctx.hasChanges { try ctx.save() }
        }
    }

    func clearAllProductCache() async throws {
        let ctx = stack.newBackgroundContext()
        try await ctx.perform {
            let fr = CachedProductEntity.fetchRequest()
            for o in try ctx.fetch(fr) { ctx.delete(o) }
            if ctx.hasChanges { try ctx.save() }
        }
    }
}
