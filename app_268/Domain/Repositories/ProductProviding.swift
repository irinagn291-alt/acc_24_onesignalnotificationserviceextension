import Foundation

enum ProductSource: Sendable {
    case network
    case cache
    case cacheWhenOffline
}

struct ResolvedProduct: Sendable {
    var product: Product
    var source: ProductSource
}

protocol ProductProviding {
    func fetchProduct(barcode: String, preferNetwork: Bool) async throws -> ResolvedProduct
    func search(query: String, page: Int, pageSize: Int) async throws -> ProductSearchPage
}
