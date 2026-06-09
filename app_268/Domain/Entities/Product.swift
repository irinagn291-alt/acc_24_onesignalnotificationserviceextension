import Foundation

struct Nutriments: Equatable, Codable, Sendable {
    var energyKcal100g: Double?
    var proteins100g: Double?
    var fat100g: Double?
    var saturatedFat100g: Double?
    var carbohydrates100g: Double?
    var sugars100g: Double?
    var fiber100g: Double?
    var salt100g: Double?
    var sodium100g: Double?
}

struct Product: Equatable, Codable, Identifiable, Sendable {
    var id: String { barcode }
    var barcode: String
    var name: String
    var genericName: String?
    var brand: String?
    var quantity: String?
    var categories: [String]
    var countries: [String]
    var imageUrl: String?
    var ingredientsText: String?
    var allergens: [String]
    var traces: [String]
    var additives: [String]
    var nutriScore: String?
    var novaGroup: Int?
    var ecoScore: String?
    var nutriments: Nutriments
    var labels: [String]
    var packaging: [String]
    var stores: [String]
    var url: String?
    var manufacturingPlaces: String?
    var origins: String?
    var brandsTags: [String]
    var palmOilIngredients: Bool
    var veganTags: [String]
    var vegetarianTags: [String]

    static func placeholder(barcode: String) -> Product {
        Product(
            barcode: barcode,
            name: "",
            genericName: nil,
            brand: nil,
            quantity: nil,
            categories: [],
            countries: [],
            imageUrl: nil,
            ingredientsText: nil,
            allergens: [],
            traces: [],
            additives: [],
            nutriScore: nil,
            novaGroup: nil,
            ecoScore: nil,
            nutriments: Nutriments(),
            labels: [],
            packaging: [],
            stores: [],
            url: nil,
            manufacturingPlaces: nil,
            origins: nil,
            brandsTags: [],
            palmOilIngredients: false,
            veganTags: [],
            vegetarianTags: []
        )
    }
}

struct ProductListItem: Equatable, Identifiable, Sendable {
    var id: String { barcode }
    var barcode: String
    var name: String
    var brand: String?
    var imageUrl: String?
    var nutriScore: String?
    var energyKcal100g: Double?
    var sugars100g: Double?
    var salt100g: Double?
}

struct ProductSearchPage: Sendable {
    var items: [ProductListItem]
    var totalCount: Int
    var page: Int
    var pageSize: Int
    var hasMore: Bool
}

enum ProductWarningKind: String, Equatable, Sendable {
    case highSugar
    case highSalt
    case highSaturatedFat
    case ultraProcessed
    case palmOil
}

struct ProductWarning: Equatable, Identifiable, Sendable {
    var id: String { "\(kind.rawValue)-\(message)" }
    var kind: ProductWarningKind
    var severity: ProductWarningSeverity
    var message: String
}

enum ProductWarningSeverity: Sendable {
    case danger
    case caution
    case info
}

enum OpenFoodFactsRegion: String, CaseIterable, Identifiable, Sendable {
    case world = "world"
    case argentina = "ar"
    case australia = "au"
    case austria = "at"
    case belarus = "by"
    case belgium = "be"
    case brazil = "br"
    case bulgaria = "bg"
    case canada = "ca"
    case croatia = "hr"
    case czechia = "cz"
    case denmark = "dk"
    case estonia = "ee"
    case finland = "fi"
    case france = "fr"
    case germany = "de"
    case greece = "gr"
    case hungary = "hu"
    case india = "in"
    case ireland = "ie"
    case israel = "il"
    case italy = "it"
    case japan = "jp"
    case kazakhstan = "kz"
    case latvia = "lv"
    case lithuania = "lt"
    case mexico = "mx"
    case netherlands = "nl"
    case newZealand = "nz"
    case norway = "no"
    case poland = "pl"
    case portugal = "pt"
    case romania = "ro"
    case serbia = "rs"
    case slovakia = "sk"
    case slovenia = "si"
    case southAfrica = "za"
    case southKorea = "kr"
    case spain = "es"
    case sweden = "se"
    case switzerland = "ch"
    case turkey = "tr"
    case ukraine = "ua"
    case uae = "ae"
    case uk = "uk"
    case usa = "us"
    case vietnam = "vn"

    var id: String { rawValue }

    var host: String { "\(rawValue).openfoodfacts.org" }

    var displayTitle: String {
        switch self {
        case .world: "World (world)"
        case .argentina: "Argentina (ar)"
        case .australia: "Australia (au)"
        case .austria: "Austria (at)"
        case .belarus: "Belarus (by)"
        case .belgium: "Belgium (be)"
        case .brazil: "Brazil (br)"
        case .bulgaria: "Bulgaria (bg)"
        case .canada: "Canada (ca)"
        case .croatia: "Croatia (hr)"
        case .czechia: "Czechia (cz)"
        case .denmark: "Denmark (dk)"
        case .estonia: "Estonia (ee)"
        case .finland: "Finland (fi)"
        case .france: "France (fr)"
        case .germany: "Germany (de)"
        case .greece: "Greece (gr)"
        case .hungary: "Hungary (hu)"
        case .india: "India (in)"
        case .ireland: "Ireland (ie)"
        case .israel: "Israel (il)"
        case .italy: "Italy (it)"
        case .japan: "Japan (jp)"
        case .kazakhstan: "Kazakhstan (kz)"
        case .latvia: "Latvia (lv)"
        case .lithuania: "Lithuania (lt)"
        case .mexico: "Mexico (mx)"
        case .netherlands: "Netherlands (nl)"
        case .newZealand: "New Zealand (nz)"
        case .norway: "Norway (no)"
        case .poland: "Poland (pl)"
        case .portugal: "Portugal (pt)"
        case .romania: "Romania (ro)"
        case .serbia: "Serbia (rs)"
        case .slovakia: "Slovakia (sk)"
        case .slovenia: "Slovenia (si)"
        case .southAfrica: "South Africa (za)"
        case .southKorea: "South Korea (kr)"
        case .spain: "Spain (es)"
        case .sweden: "Sweden (se)"
        case .switzerland: "Switzerland (ch)"
        case .turkey: "Turkey (tr)"
        case .ukraine: "Ukraine (ua)"
        case .uae: "United Arab Emirates (ae)"
        case .uk: "United Kingdom (uk)"
        case .usa: "United States (us)"
        case .vietnam: "Vietnam (vn)"
        }
    }
}

struct AppSettingsSnapshot: Equatable, Sendable {
    var onboardingCompleted: Bool
    var openFoodFactsHost: String
    var useMetricUnits: Bool
}

extension AppSettingsSnapshot {
    static let `default` = AppSettingsSnapshot(
        onboardingCompleted: false,
        openFoodFactsHost: OpenFoodFactsRegion.world.host,
        useMetricUnits: true
    )
}

enum FoodScanError: Error, Equatable, Sendable {
    case productNotFound
    case networkUnavailable
    case serverUnavailable
    case decodingFailed
    case invalidBarcode
}
