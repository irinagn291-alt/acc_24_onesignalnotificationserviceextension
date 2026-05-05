import Foundation

struct FetchProductUseCase {
    private let products: ProductProviding
    private let history: HistoryStoring

    init(products: ProductProviding, history: HistoryStoring) {
        self.products = products
        self.history = history
    }

    func execute(barcode: String, preferNetwork: Bool = true) async throws -> ResolvedProduct {
        let resolved = try await products.fetchProduct(barcode: barcode, preferNetwork: preferNetwork)
        try await history.recordView(product: resolved.product)
        return resolved
    }
}

struct SearchProductsUseCase {
    private let products: ProductProviding

    init(products: ProductProviding) {
        self.products = products
    }

    func execute(query: String, page: Int, pageSize: Int = 20) async throws -> ProductSearchPage {
        try await products.search(query: query, page: page, pageSize: pageSize)
    }
}

struct ToggleFavoriteUseCase {
    private let favorites: FavoritesStoring

    init(favorites: FavoritesStoring) {
        self.favorites = favorites
    }

    func execute(product: Product) async throws -> Bool {
        try await favorites.toggle(product: product)
    }
}

struct AddProductToDayListUseCase {
    private let dayLists: DayListStoring

    init(dayLists: DayListStoring) {
        self.dayLists = dayLists
    }

    func execute(day: Date, product: Product) async throws {
        try await dayLists.addProduct(dayStart: day, product: product)
    }
}

struct LoadHomeUseCase {
    private let history: HistoryStoring
    private let settings: SettingsStoring

    init(history: HistoryStoring, settings: SettingsStoring) {
        self.history = history
        self.settings = settings
    }

    func recentHistory(limit: Int = 8) async throws -> [HistoryListItem] {
        let items = try await history.items()
        return Array(items.prefix(limit))
    }

    func settingsSnapshot() async throws -> AppSettingsSnapshot {
        try await settings.snapshot()
    }
}
