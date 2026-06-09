import CoreData
import Foundation

final class ProductRepository: ProductProviding {
    private let stack: PersistenceControllerPayload
    private let api: OpenFoodFactsClient
    private let settings: SettingsStoring
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let cacheDays = 7

    init(stack: PersistenceControllerPayload, api: OpenFoodFactsClient, settings: SettingsStoring) {
        self.stack = stack
        self.api = api
        self.settings = settings
    }

    func fetchProduct(barcode: String, preferNetwork: Bool) async throws -> ResolvedProduct {
        let trimmed = barcode.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw FoodScanError.invalidBarcode }

        let snap = try await settings.snapshot()
        let host = snap.openFoodFactsHost

        if !preferNetwork, let cached = try await loadCache(barcode: trimmed), !isExpired(cached.cachedAt) {
            return ResolvedProduct(product: cached.product, source: .cache)
        }

        do {
            let product = try await api.fetchProduct(host: host, barcode: trimmed)
            try await saveCache(product: product)
            return ResolvedProduct(product: product, source: .network)
        } catch {
            if let cached = try await loadCache(barcode: trimmed) {
                return ResolvedProduct(product: cached.product, source: .cacheWhenOffline)
            }
            if case OpenFoodFactsClientError.productMissing = error {
                throw FoodScanError.productNotFound
            }
            if error is DecodingError {
                throw FoodScanError.decodingFailed
            }
            if let url = error as? URLError {
                switch url.code {
                case .notConnectedToInternet, .dataNotAllowed:
                    throw FoodScanError.networkUnavailable
                default:
                    break
                }
            }
            throw FoodScanError.networkUnavailable
        }
    }

    func search(query: String, page: Int, pageSize: Int) async throws -> ProductSearchPage {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard q.count >= 2 else {
            return ProductSearchPage(items: [], totalCount: 0, page: page, pageSize: pageSize, hasMore: false)
        }
        let snap = try await settings.snapshot()
        do {
            return try await api.search(host: snap.openFoodFactsHost, query: q, page: page, pageSize: pageSize)
        } catch {
            if error is DecodingError {
                throw FoodScanError.decodingFailed
            }
            if let url = error as? URLError, url.code == .notConnectedToInternet || url.code == .dataNotAllowed {
                throw FoodScanError.networkUnavailable
            }
            throw FoodScanError.networkUnavailable
        }
    }

    private func isExpired(_ date: Date) -> Bool {
        let limit = Calendar.current.date(byAdding: .day, value: -cacheDays, to: Date()) ?? Date.distantPast
        return date < limit
    }

    private struct CachePair {
        var product: Product
        var cachedAt: Date
    }

    private func loadCache(barcode: String) async throws -> CachePair? {
        let ctx = stack.viewContext
        let dec = decoder
        return try await ctx.perform {
            let fr = CachedProductEntity.fetchRequest()
            fr.fetchLimit = 1
            fr.predicate = NSPredicate(format: "barcode == %@", barcode)
            guard let e = try ctx.fetch(fr).first else { return nil }
            guard let product = try? dec.decode(Product.self, from: e.payloadJSON) else { return nil }
            return CachePair(product: product, cachedAt: e.cachedAt)
        }
    }

    private func saveCache(product: Product) async throws {
        let data = try encoder.encode(product)
        let ctx = stack.newBackgroundContext()
        try await ctx.perform {
            let fr = CachedProductEntity.fetchRequest()
            fr.predicate = NSPredicate(format: "barcode == %@", product.barcode)
            let e = (try ctx.fetch(fr).first) ?? CachedProductEntity(context: ctx)
            e.barcode = product.barcode
            e.payloadJSON = data
            e.cachedAt = Date()
            if ctx.hasChanges {
                try ctx.save()
            }
        }
    }
}
