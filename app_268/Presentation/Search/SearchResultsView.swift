import Combine
import SwiftUI

@MainActor
final class SearchResultsViewModel: ObservableObject {
    @Published var query: String
    @Published private(set) var items: [ProductListItem] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var hasMore = true

    private var page = 1
    private let pageSize = 20
    private let env: AppEnvironment
    private var debounceTask: Task<Void, Never>?

    init(initialQuery: String, env: AppEnvironment) {
        query = initialQuery
        self.env = env
    }

    func scheduleQueryDebounce() {
        debounceTask?.cancel()
        debounceTask = Task {
            try? await Task.sleep(for: .milliseconds(650))
            guard !Task.isCancelled else { return }
            await reloadFromStart()
        }
    }

    func reloadFromStart() async {
        let t = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard t.count >= 2 else {
            items = []
            errorMessage = "Enter at least 2 characters"
            return
        }
        page = 1
        hasMore = true
        items = []
        await loadPage(append: false)
    }

    func loadMoreIfNeeded(current item: ProductListItem?) async {
        guard let item, let last = items.last else { return }
        guard item.barcode == last.barcode, hasMore, !isLoading else { return }
        page += 1
        await loadPage(append: true)
    }

    private func loadPage(append: Bool) async {
        let t = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard t.count >= 2 else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let res = try await env.searchProductsUseCase.execute(query: t, page: page, pageSize: pageSize)
            if append {
                items.append(contentsOf: res.items)
            } else {
                items = res.items
            }
            hasMore = res.hasMore
            if items.isEmpty {
                errorMessage = "No products found"
            }
        } catch FoodScanError.networkUnavailable {
            errorMessage = "Could not load data. Check your internet connection"
        } catch {
            errorMessage = "Search failed"
        }
    }
}

struct SearchResultsView: View {
    @EnvironmentObject private var env: AppEnvironment
    @StateObject private var model: SearchResultsViewModel
    @State private var selectedFilter: SearchFilter = .all

    private enum SearchFilter: String, CaseIterable, Identifiable {
        case all = "All"
        case bestNutri = "Best Nutri-Score"
        case lowSugar = "Lower sugar"
        case allergens = "Allergen info"

        var id: String { rawValue }
    }

    init(initialQuery: String, env: AppEnvironment) {
        _model = StateObject(wrappedValue: SearchResultsViewModel(initialQuery: initialQuery, env: env))
    }

    var body: some View {
        VStack(spacing: 0) {
            SearchField(
                text: $model.query,
                placeholder: "Search products",
                onSubmit: { Task { await model.reloadFromStart() } }
            )
            .padding(.horizontal, AppTheme.Spacing.xl)
            .padding(.vertical, AppTheme.Spacing.md)
            .background(AppTheme.Colors.background)
            .onChange(of: model.query) { _, _ in model.scheduleQueryDebounce() }

            filterChips

            ScrollView {
                LazyVStack(spacing: AppTheme.Spacing.md) {
                    if model.isLoading && model.items.isEmpty {
                        ForEach(0 ..< 4, id: \.self) { _ in
                            ProductCardSkeleton()
                        }
                    } else if let err = model.errorMessage, model.items.isEmpty {
                        EmptyState(
                            icon: "magnifyingglass",
                            title: "No results",
                            description: err,
                            actionTitle: "Scan barcode",
                            onAction: { env.coordinator.isScannerPresented = true }
                        )
                        .padding(.horizontal, AppTheme.Spacing.xl)
                    } else {
                        ForEach(displayedItems) { item in
                            NavigationLink(value: HomeRoute.product(item.barcode)) {
                                ProductCard(
                                    name: item.name,
                                    brand: item.brand,
                                    imageURL: item.imageUrl.flatMap(URL.init(string:)),
                                    nutriScore: item.nutriScore,
                                    calories: item.energyKcal100g,
                                    sugar: item.sugars100g,
                                    salt: item.salt100g,
                                    onTap: {},
                                    wrapsInButton: false
                                )
                            }
                            .buttonStyle(.plain)
                            .task {
                                await model.loadMoreIfNeeded(current: item)
                            }
                        }
                        if model.isLoading, !model.items.isEmpty {
                            ProgressView()
                                .tint(AppTheme.Colors.primary)
                                .frame(maxWidth: .infinity)
                                .padding()
                        }
                    }
                }
                .padding(.horizontal, AppTheme.Spacing.xl)
                .padding(.bottom, MainTabView.tabBarClearance)
            }
        }
        .background(AppTheme.Colors.background.ignoresSafeArea())
        .navigationTitle("Search")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AppTheme.Colors.background, for: .navigationBar)
        .task {
            await model.reloadFromStart()
        }
    }

    private var displayedItems: [ProductListItem] {
        switch selectedFilter {
        case .all:
            return model.items
        case .bestNutri:
            let order = ["a", "b", "c", "d", "e"]
            return model.items.sorted { a, b in
                let ia = order.firstIndex(of: a.nutriScore?.lowercased() ?? "z") ?? 99
                let ib = order.firstIndex(of: b.nutriScore?.lowercased() ?? "z") ?? 99
                return ia < ib
            }
        case .lowSugar:
            return model.items.filter { ($0.sugars100g ?? 0) < 5 }
        case .allergens:
            return model.items
        }
    }

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppTheme.Spacing.sm) {
                ForEach(SearchFilter.allCases) { f in
                    Button {
                        selectedFilter = f
                    } label: {
                        Text(f.rawValue)
                            .font(.system(size: 12, weight: .heavy, design: .rounded))
                            .foregroundStyle(selectedFilter == f ? AppTheme.Colors.textLight : AppTheme.Colors.text)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 9)
                            .background(selectedFilter == f ? AppTheme.Colors.primary : AppTheme.Colors.surface)
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(selectedFilter == f ? AppTheme.Colors.primary : AppTheme.Colors.border, lineWidth: 1)
                            )
                    }
                    .buttonStyle(ScaleButtonStyle(scale: 0.97))
                }
            }
            .padding(.horizontal, AppTheme.Spacing.xl)
            .padding(.bottom, AppTheme.Spacing.sm)
        }
    }
}
