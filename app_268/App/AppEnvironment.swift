import Combine
import SwiftUI

@MainActor
final class AppEnvironment: ObservableObject {
    @Published private(set) var onboardingCompleted: Bool = false

    let stack: PersistenceControllerPayload
    let settingsRepository: SettingsRepository
    let historyRepository: HistoryRepository
    let favoritesRepository: FavoritesRepository
    let dayListRepository: DayListRepository
    let cacheRepository: CacheRepository
    let apiClient: OpenFoodFactsClient
    let productRepository: ProductRepository

    let fetchProductUseCase: FetchProductUseCase
    let searchProductsUseCase: SearchProductsUseCase
    let toggleFavoriteUseCase: ToggleFavoriteUseCase
    let addProductToDayListUseCase: AddProductToDayListUseCase
    let loadHomeUseCase: LoadHomeUseCase
    let warningEngine: WarningEngine

    let coordinator: AppCoordinator

    private var cancellables = Set<AnyCancellable>()

    init(stack: PersistenceControllerPayload = PersistenceController.shared) {
        self.stack = stack
        let settings = SettingsRepository(stack: stack)
        let history = HistoryRepository(stack: stack)
        let favorites = FavoritesRepository(stack: stack)
        let dayLists = DayListRepository(stack: stack)
        let cache = CacheRepository(stack: stack)
        let api = OpenFoodFactsClient()
        let products = ProductRepository(stack: stack, api: api, settings: settings)

        settingsRepository = settings
        historyRepository = history
        favoritesRepository = favorites
        dayListRepository = dayLists
        cacheRepository = cache
        apiClient = api
        productRepository = products

        fetchProductUseCase = FetchProductUseCase(products: products, history: history)
        searchProductsUseCase = SearchProductsUseCase(products: products)
        toggleFavoriteUseCase = ToggleFavoriteUseCase(favorites: favorites)
        addProductToDayListUseCase = AddProductToDayListUseCase(dayLists: dayLists)
        loadHomeUseCase = LoadHomeUseCase(history: history, settings: settings)
        warningEngine = WarningEngine()

        coordinator = AppCoordinator()
        coordinator.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }.store(in: &cancellables)
    }

    func bootstrap() async {
        try? await settingsRepository.ensureBootstrapped()
        try? await cacheRepository.clearExpiredProductCache(olderThan: 7)
        await refreshOnboardingFlag()
    }

    func refreshOnboardingFlag() async {
        do {
            let s = try await settingsRepository.snapshot()
            onboardingCompleted = s.onboardingCompleted
        } catch {
            onboardingCompleted = false
        }
    }
}
