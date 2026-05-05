import SwiftUI

struct HistoryView: View {
    @ObservedObject var env: AppEnvironment
    @State private var items: [HistoryListItem] = []
    @State private var searchText: String = ""
    @State private var filtered: [HistoryListItem] = []

    var body: some View {
        Group {
            if items.isEmpty && searchText.isEmpty {
                ScrollView {
                    EmptyState(
                        icon: "clock",
                        title: "No history yet",
                        description: "Products you open will show up here for quick access.",
                        actionTitle: nil,
                        onAction: nil
                    )
                    .padding(AppTheme.Spacing.xl)
                    .padding(.bottom, MainTabView.tabBarClearance)
                }
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                        if !items.isEmpty {
                            SearchField(
                                text: $searchText,
                                placeholder: "Search history",
                                onSubmit: nil
                            )
                            .onChange(of: searchText) { _, _ in Task { await filter() } }
                        }

                        ForEach(displayed) { item in
                            NavigationLink(value: item.barcode) {
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
                            .contextMenu {
                                Button(role: .destructive) {
                                    Task { await deleteOne(item.barcode) }
                                } label: {
                                    Label("Remove", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .padding(.horizontal, AppTheme.Spacing.xl)
                    .padding(.vertical, AppTheme.Spacing.lg)
                    .padding(.bottom, MainTabView.tabBarClearance)
                }
            }
        }
        .background(AppTheme.Colors.background.ignoresSafeArea())
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AppTheme.Colors.background, for: .navigationBar)
        .toolbar {
            if !items.isEmpty {
                Button("Clear", role: .destructive) {
                    Task { await clear() }
                }
            }
        }
        .task { await reload() }
        .onAppear { Task { await reload() } }
        .navigationDestination(for: String.self) { barcode in
            ProductDetailView(barcode: barcode, env: env).id(barcode)
        }
    }

    private var displayed: [HistoryListItem] {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? items : filtered
    }

    private func reload() async {
        do {
            items = try await env.historyRepository.items()
            await filter()
        } catch {
            items = []
        }
    }

    private func filter() async {
        do {
            filtered = try await env.historyRepository.search(term: searchText)
        } catch {
            filtered = items
        }
    }

    private func deleteOne(_ barcode: String) async {
        try? await env.historyRepository.delete(barcode: barcode)
        await reload()
    }

    private func clear() async {
        try? await env.historyRepository.clear()
        await reload()
    }
}

struct FavoritesView: View {
    @ObservedObject var env: AppEnvironment
    @State private var items: [FavoriteListItem] = []

    var body: some View {
        Group {
            if items.isEmpty {
                ScrollView {
                    EmptyState(
                        icon: "heart",
                        title: "No favorites",
                        description: "Save products you care about and open them anytime.",
                        actionTitle: nil,
                        onAction: nil
                    )
                    .padding(AppTheme.Spacing.xl)
                    .padding(.bottom, MainTabView.tabBarClearance)
                }
            } else {
                ScrollView {
                    VStack(spacing: AppTheme.Spacing.md) {
                        ForEach(items) { item in
                            NavigationLink(value: item.barcode) {
                                ProductCard(
                                    name: item.name ?? "Untitled",
                                    brand: item.brand,
                                    imageURL: item.imageUrl.flatMap(URL.init(string:)),
                                    nutriScore: item.nutriScore,
                                    calories: nil,
                                    sugar: nil,
                                    salt: nil,
                                    onTap: {},
                                    wrapsInButton: false
                                )
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                Button(role: .destructive) {
                                    Task { await remove(barcode: item.barcode) }
                                } label: {
                                    Label("Remove from favorites", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .padding(.horizontal, AppTheme.Spacing.xl)
                    .padding(.vertical, AppTheme.Spacing.lg)
                    .padding(.bottom, MainTabView.tabBarClearance)
                }
            }
        }
        .background(AppTheme.Colors.background.ignoresSafeArea())
        .navigationTitle("Favorites")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AppTheme.Colors.background, for: .navigationBar)
        .task { await reload() }
        .onAppear { Task { await reload() } }
        .navigationDestination(for: String.self) { barcode in
            ProductDetailView(barcode: barcode, env: env).id(barcode)
        }
    }

    private func reload() async {
        do {
            items = try await env.favoritesRepository.items()
        } catch {
            items = []
        }
    }

    private func remove(barcode: String) async {
        try? await env.favoritesRepository.remove(barcode: barcode)
        await reload()
    }
}
