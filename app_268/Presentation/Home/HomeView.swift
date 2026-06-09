import Combine
import SwiftUI

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var query: String = ""
    @Published private(set) var recent: [HistoryListItem] = []
    @Published private(set) var isLoadingRecent = false

    private let env: AppEnvironment

    init(env: AppEnvironment) {
        self.env = env
    }

    func reload() async {
        isLoadingRecent = true
        defer { isLoadingRecent = false }
        do {
            recent = try await env.loadHomeUseCase.recentHistory(limit: 8)
        } catch {
            recent = []
        }
    }
}

private enum QuickFilter: String, CaseIterable, Identifiable {
    case sugarFree = "No added sugar"
    case glutenFree = "Gluten-free"
    case vegan = "Vegan"

    var id: String { rawValue }

    var searchQuery: String {
        switch self {
        case .sugarFree: "no added sugar"
        case .glutenFree: "gluten-free"
        case .vegan: "vegan"
        }
    }
}

struct HomeView: View {
    @EnvironmentObject private var env: AppEnvironment
    @StateObject private var model: HomeViewModel
    @FocusState private var searchFocused: Bool

    init(env: AppEnvironment) {
        _model = StateObject(wrappedValue: HomeViewModel(env: env))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xl) {
                headerBlock

                SearchField(
                    text: $model.query,
                    placeholder: "Search product, brand, or category",
                    onSubmit: submitSearch
                )
                .focused($searchFocused)

                Button {
                    submitSearch()
                } label: {
                    Text("Search")
                        .font(.system(size: 15, weight: .heavy, design: .rounded))
                        .foregroundStyle(trimmedQuery.count >= 2 ? AppTheme.Colors.textLight : AppTheme.Colors.textMuted)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(trimmedQuery.count >= 2 ? AppTheme.Colors.primary : AppTheme.Colors.skeleton)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.lg, style: .continuous))
                }
                .disabled(trimmedQuery.count < 2)
                .buttonStyle(ScaleButtonStyle())

                PrimaryScanCard { env.coordinator.isScannerPresented = true }
                    .accessibilityHint("Opens camera to scan barcode")

                quickFilters

                VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                    Text("Recent products")
                        .font(AppTheme.Typography.h2)
                        .foregroundStyle(AppTheme.Colors.text)

                    if model.isLoadingRecent {
                        ProgressView()
                            .tint(AppTheme.Colors.primary)
                            .frame(maxWidth: .infinity)
                    } else if model.recent.isEmpty {
                        Text("No recent scans yet. Search or scan a barcode to get started.")
                            .font(AppTheme.Typography.bodyMuted)
                            .foregroundStyle(AppTheme.Colors.textMuted)
                    } else {
                        VStack(spacing: AppTheme.Spacing.md) {
                            ForEach(model.recent) { item in
                                NavigationLink(value: HomeRoute.product(item.barcode)) {
                                    ProductCard(
                                        name: item.name ?? "Untitled",
                                        brand: item.brand,
                                        imageURL: item.imageUrl.flatMap(URL.init(string:)),
                                        nutriScore: nil,
                                        calories: nil,
                                        sugar: nil,
                                        salt: nil,
                                        onTap: {},
                                        wrapsInButton: false
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }

                tipCard
            }
            .padding(.horizontal, AppTheme.Spacing.xl)
            .padding(.top, AppTheme.Spacing.md)
            .padding(.bottom, MainTabView.tabBarClearance)
        }
        .background(AppTheme.Colors.background.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AppTheme.Colors.background, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Fooduch")
                    .font(.system(size: 17, weight: .heavy, design: .rounded))
                    .foregroundStyle(AppTheme.Colors.primary)
            }
        }
        .task { await model.reload() }
        .navigationDestination(for: HomeRoute.self) { route in
            switch route {
            case let .product(barcode):
                ProductDetailView(barcode: barcode, env: env).id(barcode)
            case let .search(query):
                SearchResultsView(initialQuery: query, env: env)
            }
        }
    }

    private var headerBlock: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text("Fooduch")
                .font(AppTheme.Typography.eyebrow)
                .foregroundStyle(AppTheme.Colors.primary)
            Text("Check the product before you buy")
                .font(AppTheme.Typography.title)
                .foregroundStyle(AppTheme.Colors.text)
                .fixedSize(horizontal: false, vertical: true)
            Text("Ingredients, allergens, Nutri-Score, and nutrition in one calm view.")
                .font(AppTheme.Typography.bodyMuted)
                .foregroundStyle(AppTheme.Colors.textMuted)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var quickFilters: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text("Quick filters")
                .font(AppTheme.Typography.h2)
                .foregroundStyle(AppTheme.Colors.text)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppTheme.Spacing.sm) {
                    ForEach(QuickFilter.allCases) { filter in
                        Button {
                            model.query = filter.searchQuery
                            submitSearch()
                        } label: {
                            Text(filter.rawValue)
                                .font(.system(size: 12, weight: .heavy, design: .rounded))
                                .foregroundStyle(AppTheme.Colors.text)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 9)
                                .background(AppTheme.Colors.surface)
                                .clipShape(Capsule())
                                .overlay(Capsule().stroke(AppTheme.Colors.border, lineWidth: 1))
                        }
                        .buttonStyle(ScaleButtonStyle(scale: 0.97))
                    }
                }
            }
        }
    }

    private var tipCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Tip")
                .font(.system(size: 16, weight: .heavy, design: .rounded))
                .foregroundStyle(AppTheme.Colors.primary)
            Text("Look beyond calories: check sugar, salt, saturated fat, and the NOVA group.")
                .font(AppTheme.Typography.bodyMuted)
                .foregroundStyle(AppTheme.Colors.textMuted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(AppTheme.Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.Colors.surfaceSoft)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(AppTheme.Colors.border, lineWidth: 1)
        )
    }

    private var trimmedQuery: String {
        model.query.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func submitSearch() {
        let t = trimmedQuery
        guard t.count >= 2 else { return }
        env.coordinator.openSearchFromHome(query: t)
    }
}
