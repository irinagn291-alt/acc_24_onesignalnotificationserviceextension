import SwiftUI

struct MainTabView: View {
    @ObservedObject var env: AppEnvironment

    /// Bottom inset so scroll content clears the floating tab bar.
    static let tabBarClearance: CGFloat = 96

    private var homePathBinding: Binding<NavigationPath> {
        Binding(
            get: { env.coordinator.homePath },
            set: { env.coordinator.homePath = $0 }
        )
    }

    private var historyPathBinding: Binding<NavigationPath> {
        Binding(
            get: { env.coordinator.historyPath },
            set: { env.coordinator.historyPath = $0 }
        )
    }

    private var favoritesPathBinding: Binding<NavigationPath> {
        Binding(
            get: { env.coordinator.favoritesPath },
            set: { env.coordinator.favoritesPath = $0 }
        )
    }

    private var dayListsPathBinding: Binding<NavigationPath> {
        Binding(
            get: { env.coordinator.dayListsPath },
            set: { env.coordinator.dayListsPath = $0 }
        )
    }

    private var scannerPresentedBinding: Binding<Bool> {
        Binding(
            get: { env.coordinator.isScannerPresented },
            set: { env.coordinator.isScannerPresented = $0 }
        )
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            ZStack {
                NavigationStack(path: homePathBinding) {
                    HomeView(env: env)
                }
                .opacity(env.coordinator.selectedTab == .home ? 1 : 0)
                .allowsHitTesting(env.coordinator.selectedTab == .home)

                NavigationStack(path: historyPathBinding) {
                    HistoryView(env: env)
                }
                .opacity(env.coordinator.selectedTab == .history ? 1 : 0)
                .allowsHitTesting(env.coordinator.selectedTab == .history)

                NavigationStack(path: favoritesPathBinding) {
                    FavoritesView(env: env)
                }
                .opacity(env.coordinator.selectedTab == .favorites ? 1 : 0)
                .allowsHitTesting(env.coordinator.selectedTab == .favorites)

                NavigationStack(path: dayListsPathBinding) {
                    DayListsView(env: env)
                }
                .opacity(env.coordinator.selectedTab == .dayLists ? 1 : 0)
                .allowsHitTesting(env.coordinator.selectedTab == .dayLists)

                NavigationStack {
                    SettingsView(env: env)
                }
                .opacity(env.coordinator.selectedTab == .settings ? 1 : 0)
                .allowsHitTesting(env.coordinator.selectedTab == .settings)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            floatingTabBar
                .padding(.horizontal, 20)
                .padding(.bottom, 12)
        }
        .tint(AppTheme.Colors.primary)
        .fullScreenCover(isPresented: scannerPresentedBinding) {
            BarcodeScannerView(
                onCode: { code in
                    let trimmed = code.trimmingCharacters(in: .whitespacesAndNewlines)
                    env.coordinator.dismissScannerIfNeeded()
                    DispatchQueue.main.async {
                        env.coordinator.openProductFromHome(barcode: trimmed)
                    }
                },
                onCancel: {
                    env.coordinator.dismissScannerIfNeeded()
                }
            )
            .ignoresSafeArea()
        }
    }

    private var floatingTabBar: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases) { t in
                tabButton(t)
            }
        }
        .padding(.horizontal, AppTheme.Spacing.sm)
        .padding(.vertical, 10)
        .background(AppTheme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(AppTheme.Colors.border, lineWidth: 1)
        )
        .shadow(color: AppTheme.Colors.text.opacity(0.12), radius: 24, x: 0, y: 10)
    }

    private func tabButton(_ t: AppTab) -> some View {
        let selected = env.coordinator.selectedTab == t
        return Button {
            env.coordinator.selectedTab = t
        } label: {
            VStack(spacing: 4) {
                ZStack {
                    if selected {
                        Circle()
                            .fill(AppTheme.Colors.primary)
                            .frame(width: 48, height: 48)
                    }
                    Image(systemName: t.icon)
                        .font(.system(size: 21, weight: .semibold))
                        .foregroundStyle(selected ? AppTheme.Colors.textLight : AppTheme.Colors.textMuted)
                }
                .frame(height: 48)
                Text(t.title)
                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                    .foregroundStyle(selected ? AppTheme.Colors.primary : AppTheme.Colors.textMuted)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(t.title)
    }
}

struct RootView: View {
    @ObservedObject var env: AppEnvironment

    var body: some View {
        Group {
            if env.onboardingCompleted {
                MainTabView(env: env)
            } else {
                OnboardingView(env: env)
            }
        }
        .task {
            await env.refreshOnboardingFlag()
        }
    }
}

private let dayListFormatter: DateFormatter = {
    let f = DateFormatter()
    f.dateStyle = .medium
    f.timeStyle = .none
    return f
}()

struct DayListsView: View {
    @ObservedObject var env: AppEnvironment
    @State private var dayListSummaries: [DayListSummary] = []

    var body: some View {
        Group {
            if dayListSummaries.isEmpty {
                ScrollView {
                    EmptyState(
                        icon: "calendar",
                        title: "No day lists yet",
                        description: "Add a product to a day from any product screen — tap the calendar button in the toolbar.",
                        actionTitle: nil,
                        onAction: nil
                    )
                    .padding(AppTheme.Spacing.xl)
                    .padding(.bottom, MainTabView.tabBarClearance)
                }
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                        ForEach(dayListSummaries) { s in
                            NavigationLink(value: DayListsRoute.day(s.dayStart)) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(dayListFormatter.string(from: s.dayStart))
                                            .font(.system(size: 17, weight: .heavy, design: .rounded))
                                            .foregroundStyle(AppTheme.Colors.text)
                                        Text("\(s.itemCount) items")
                                            .font(AppTheme.Typography.caption)
                                            .foregroundStyle(AppTheme.Colors.textMuted)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(AppTheme.Colors.textMuted)
                                }
                                .padding(AppTheme.Spacing.lg)
                                .background(AppTheme.Colors.surface)
                                .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.lg, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: AppTheme.Radius.lg, style: .continuous)
                                        .stroke(AppTheme.Colors.border, lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, AppTheme.Spacing.xl)
                    .padding(.vertical, AppTheme.Spacing.lg)
                    .padding(.bottom, MainTabView.tabBarClearance)
                }
            }
        }
        .background(AppTheme.Colors.background.ignoresSafeArea())
        .navigationTitle("Day picks")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AppTheme.Colors.background, for: .navigationBar)
        .task { await reload() }
        .onAppear { Task { await reload() } }
        .navigationDestination(for: DayListsRoute.self) { route in
            switch route {
            case let .day(start):
                DayListDetailView(dayStart: start, env: env)
            case let .product(barcode):
                ProductDetailView(barcode: barcode, env: env).id(barcode)
            }
        }
    }

    private func reload() async {
        do {
            dayListSummaries = try await env.dayListRepository.summaries()
        } catch {
            dayListSummaries = []
        }
    }
}

struct DayListDetailView: View {
    let dayStart: Date
    @ObservedObject var env: AppEnvironment
    @State private var rowItems: [DayListItemRow] = []

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                if rowItems.isEmpty {
                    Text("No items for this day.")
                        .font(AppTheme.Typography.bodyMuted)
                        .foregroundStyle(AppTheme.Colors.textMuted)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    ForEach(rowItems) { item in
                        NavigationLink(value: DayListsRoute.product(item.barcode)) {
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
                                Task { await remove(item.id) }
                            } label: {
                                Label("Remove", systemImage: "trash")
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, AppTheme.Spacing.xl)
            .padding(.vertical, AppTheme.Spacing.lg)
            .padding(.bottom, MainTabView.tabBarClearance)
        }
        .background(AppTheme.Colors.background.ignoresSafeArea())
        .navigationTitle(dayListFormatter.string(from: dayStart))
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AppTheme.Colors.background, for: .navigationBar)
        .task(id: dayStart.timeIntervalSince1970) { await reload() }
        .onAppear { Task { await reload() } }
    }

    private func reload() async {
        do {
            rowItems = try await env.dayListRepository.items(dayStart: dayStart)
        } catch {
            rowItems = []
        }
    }

    private func remove(_ id: UUID) async {
        try? await env.dayListRepository.removeItem(itemId: id)
        await reload()
    }
}
