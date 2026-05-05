import Foundation

struct AppAPIConfiguration: Sendable {
    static let userAgent = "Fooduch/1.0 (https://openfoodfacts.org)"

    var host: String

    init(host: String) {
        self.host = host
    }

    func productURL(barcode: String) -> URL {
        URL(string: "https://\(host)/api/v2/product/\(barcode).json")!
    }
}

enum OpenFoodFactsClientError: Error, Sendable {
    case invalidResponse
    case httpStatus(Int)
    case productMissing
    case decoding
}

final class OpenFoodFactsClient {
    private let session: URLSession
    private let jsonDecoder: JSONDecoder

    init(session: URLSession? = nil) {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 25
        config.timeoutIntervalForResource = 45
        self.session = session ?? URLSession(configuration: config)
        let dec = JSONDecoder()
        dec.keyDecodingStrategy = .convertFromSnakeCase
        self.jsonDecoder = dec
    }

    func fetchProduct(host: String, barcode: String) async throws -> Product {
        let url = AppAPIConfiguration(host: host).productURL(barcode: barcode)
        let data = try await get(url: url)
        let dto = try jsonDecoder.decode(ProductResponseDTO.self, from: data)
        guard let p = dto.product else {
            throw OpenFoodFactsClientError.productMissing
        }
        if dto.status == 0 {
            throw OpenFoodFactsClientError.productMissing
        }
        return ProductMapper.map(dto: p, fallbackBarcode: barcode)
    }

    /// Uses [search-a-licious](https://search.openfoodfacts); classic `cgi/search.pl` often returns 503 for anonymous clients.
    func search(host _: String, query: String, page: Int, pageSize: Int) async throws -> ProductSearchPage {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2 else {
            return ProductSearchPage(items: [], totalCount: 0, page: page, pageSize: pageSize, hasMore: false)
        }
        var c = URLComponents(string: "https://search.openfoodfacts.org/search")!
        c.queryItems = [
            URLQueryItem(name: "q", value: trimmed),
            URLQueryItem(name: "page_size", value: String(pageSize)),
            URLQueryItem(name: "page", value: String(page)),
        ]
        guard let url = c.url else {
            throw OpenFoodFactsClientError.invalidResponse
        }
        let data = try await get(url: url)
        let dto = try jsonDecoder.decode(SearchAliciousResponseDTO.self, from: data)
        return SearchAliciousMapper.map(dto: dto, page: page, pageSize: pageSize)
    }

    private func get(url: URL) async throws -> Data {
        var request = URLRequest(url: url)
        request.setValue(AppAPIConfiguration.userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        var lastError: Error?
        for attempt in 0 ..< 2 {
            do {
                let (data, response) = try await session.data(for: request)
                guard let http = response as? HTTPURLResponse else {
                    throw OpenFoodFactsClientError.invalidResponse
                }
                if (500 ... 599).contains(http.statusCode), attempt == 0 {
                    continue
                }
                guard (200 ... 299).contains(http.statusCode) else {
                    throw OpenFoodFactsClientError.httpStatus(http.statusCode)
                }
                return data
            } catch {
                lastError = error
                if attempt == 0, shouldRetry(error: error) {
                    continue
                }
                throw error
            }
        }
        throw lastError ?? OpenFoodFactsClientError.invalidResponse
    }

    private func shouldRetry(error: Error) -> Bool {
        if let urlErr = error as? URLError {
            switch urlErr.code {
            case .timedOut, .cannotFindHost, .cannotConnectToHost, .networkConnectionLost, .dnsLookupFailed:
                return true
            default:
                return false
            }
        }
        return false
    }
}
