import Foundation

protocol HistoryStoring {
    func recordView(product: Product) async throws
    func items() async throws -> [HistoryListItem]
    func delete(barcode: String) async throws
    func clear() async throws
    func search(term: String) async throws -> [HistoryListItem]
}

struct HistoryListItem: Equatable, Identifiable, Sendable {
    var id: UUID
    var barcode: String
    var name: String?
    var brand: String?
    var imageUrl: String?
    var viewedAt: Date
}

protocol FavoritesStoring {
    func isFavorite(barcode: String) async throws -> Bool
    func toggle(product: Product) async throws -> Bool
    func items() async throws -> [FavoriteListItem]
    func remove(barcode: String) async throws
}

struct FavoriteListItem: Equatable, Identifiable, Sendable {
    var id: String { barcode }
    var barcode: String
    var name: String?
    var brand: String?
    var imageUrl: String?
    var nutriScore: String?
    var addedAt: Date
}

protocol SettingsStoring {
    func snapshot() async throws -> AppSettingsSnapshot
    func update(_ mutation: @escaping @Sendable (AppSettingsSnapshot) -> AppSettingsSnapshot) async throws
    func ensureBootstrapped() async throws
}

protocol CacheCleaning {
    func clearExpiredProductCache(olderThan days: Int) async throws
    func clearAllProductCache() async throws
}

struct DayListSummary: Equatable, Identifiable, Sendable {
    var id: UUID { listUUID }
    var listUUID: UUID
    var dayStart: Date
    var itemCount: Int
}

struct DayListItemRow: Equatable, Identifiable, Sendable {
    var id: UUID
    var barcode: String
    var name: String?
    var brand: String?
    var imageUrl: String?
    var nutriScore: String?
    var addedAt: Date
}

protocol DayListStoring {
    func summaries() async throws -> [DayListSummary]
    func items(dayStart: Date) async throws -> [DayListItemRow]
    func addProduct(dayStart: Date, product: Product) async throws
    func removeItem(itemId: UUID) async throws
}
