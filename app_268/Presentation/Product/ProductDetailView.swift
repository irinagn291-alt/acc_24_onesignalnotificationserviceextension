import Combine
import SwiftUI

@MainActor
final class ProductDetailViewModel: ObservableObject {
    @Published private(set) var product: Product?
    @Published private(set) var source: ProductSource?
    @Published private(set) var warnings: [ProductWarning] = []
    @Published private(set) var isFavorite: Bool = false
    @Published private(set) var isLoading = true
    @Published private(set) var errorMessage: String?

    private let barcode: String
    private let env: AppEnvironment

    init(barcode: String, env: AppEnvironment) {
        self.barcode = barcode
        self.env = env
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let resolved = try await env.fetchProductUseCase.execute(barcode: barcode, preferNetwork: true)
            product = resolved.product
            source = resolved.source
            warnings = env.warningEngine.evaluate(product: resolved.product)
            isFavorite = try await env.favoritesRepository.isFavorite(barcode: barcode)
        } catch is CancellationError {
            return
        } catch FoodScanError.productNotFound {
            errorMessage = "Product not found in OpenFoodFacts"
        } catch FoodScanError.networkUnavailable {
            errorMessage = "Could not load data. Check your internet connection"
        } catch {
            errorMessage = "Could not load product"
        }
    }

    func toggleFavorite() async {
        guard let product else { return }
        do {
            isFavorite = try await env.toggleFavoriteUseCase.execute(product: product)
        } catch {}
    }

    func addProductToDayList(day: Date) async {
        guard let product else { return }
        let dayStart = Calendar.current.startOfDay(for: day)
        try? await env.addProductToDayListUseCase.execute(day: dayStart, product: product)
    }

    var shareText: String {
        guard let product else {
            return "Barcode: \(barcode)"
        }
        var lines: [String] = [product.name]
        if let b = product.brand { lines.append(b) }
        lines.append("Barcode: \(product.barcode)")
        if let u = product.url { lines.append(u) }
        return lines.joined(separator: "\n")
    }
}

struct ProductDetailView: View {
    private let barcode: String
    @StateObject private var model: ProductDetailViewModel
    @State private var showDayListSheet = false
    @State private var selectedDayForList = Calendar.current.startOfDay(for: Date())

    init(barcode: String, env: AppEnvironment) {
        self.barcode = barcode
        _model = StateObject(wrappedValue: ProductDetailViewModel(barcode: barcode, env: env))
    }

    var body: some View {
        Group {
            if model.isLoading && model.product == nil && model.errorMessage == nil {
                ProgressView()
                    .tint(AppTheme.Colors.primary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(AppTheme.Colors.background.ignoresSafeArea())
            } else if let msg = model.errorMessage {
                EmptyState(
                    icon: "exclamationmark.triangle.fill",
                    title: "No data",
                    description: msg,
                    actionTitle: nil,
                    onAction: nil
                )
                .padding(AppTheme.Spacing.xl)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(AppTheme.Colors.background.ignoresSafeArea())
            } else if let p = model.product {
                productScroll(p)
            } else {
                ProgressView("Loading…")
                    .tint(AppTheme.Colors.primary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(AppTheme.Colors.background.ignoresSafeArea())
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AppTheme.Colors.background, for: .navigationBar)
        .task(id: barcode) {
            await model.load()
        }
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                if model.product != nil {
                    Button {
                        Task { await model.toggleFavorite() }
                    } label: {
                        Image(systemName: model.isFavorite ? "heart.fill" : "heart")
                            .foregroundStyle(AppTheme.Colors.danger)
                    }
                    .accessibilityLabel(model.isFavorite ? "Remove from favorites" : "Add to favorites")

                    ShareLink(item: model.shareText) {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundStyle(AppTheme.Colors.primary)
                    }
                    .accessibilityLabel("Share")

                    Button {
                        selectedDayForList = Calendar.current.startOfDay(for: Date())
                        showDayListSheet = true
                    } label: {
                        Image(systemName: "calendar.badge.plus")
                            .foregroundStyle(AppTheme.Colors.primary)
                    }
                    .accessibilityLabel("Add to day list")
                }
            }
        }
        .sheet(isPresented: $showDayListSheet) {
            NavigationStack {
                Form {
                    DatePicker("Day", selection: $selectedDayForList, displayedComponents: .date)
                }
                .navigationTitle("Day pick")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { showDayListSheet = false }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Add") {
                            Task {
                                await model.addProductToDayList(day: selectedDayForList)
                                showDayListSheet = false
                            }
                        }
                    }
                }
            }
        }
    }

    private func productScroll(_ p: Product) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                if model.source == .cacheWhenOffline {
                    offlineBanner
                }

                heroCard(p)
                scoresRow(p)

                if !model.warnings.isEmpty {
                    SectionCard(
                        title: "Heads up",
                        subtitle: "Based on nutrition facts and processing"
                    ) {
                        VStack(spacing: AppTheme.Spacing.sm) {
                            ForEach(model.warnings) { w in
                                WarningCard(
                                    severity: w.severity,
                                    title: w.message,
                                    description: nil
                                )
                            }
                        }
                    }
                }

                SectionCard(
                    title: "Nutrition",
                    subtitle: "Per 100 g or 100 ml"
                ) {
                    NutritionGrid(items: nutritionItems(from: p.nutriments))
                }

                SectionCard(title: "Ingredients") {
                    VStack(alignment: .leading, spacing: 0) {
                        if let t = p.ingredientsText, !t.isEmpty {
                            Text(t)
                                .font(.system(size: 15, weight: .medium, design: .rounded))
                                .foregroundStyle(AppTheme.Colors.text)
                                .lineSpacing(4)
                        } else {
                            Text("No ingredient list in OpenFoodFacts for this product.")
                                .font(AppTheme.Typography.bodyMuted)
                                .foregroundStyle(AppTheme.Colors.textMuted)
                        }
                    }
                    .padding(AppTheme.Spacing.lg)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AppTheme.Colors.surfaceSoft)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.lg, style: .continuous))
                }

                SectionCard(title: "Allergens & traces") {
                    FlowChipWrap {
                        ForEach(p.allergens, id: \.self) { a in
                            Chip(label: a, variant: .danger)
                        }
                        ForEach(p.traces, id: \.self) { t in
                            Chip(label: "May contain: \(t)", variant: .warning)
                        }
                        if p.allergens.isEmpty && p.traces.isEmpty {
                            Text("None listed")
                                .font(AppTheme.Typography.bodyMuted)
                                .foregroundStyle(AppTheme.Colors.textMuted)
                        }
                    }
                }

                SectionCard(title: "Additives") {
                    FlowChipWrap {
                        if p.additives.isEmpty {
                            Text("None listed")
                                .font(AppTheme.Typography.bodyMuted)
                                .foregroundStyle(AppTheme.Colors.textMuted)
                        } else {
                            ForEach(p.additives, id: \.self) { a in
                                Chip(label: a, variant: .primary)
                            }
                        }
                    }
                }

                extrasSection(p)

                ProductPassport(rows: passportRows(for: p))

                if let u = p.url, let url = URL(string: u) {
                    Link(destination: url) {
                        HStack(spacing: AppTheme.Spacing.sm) {
                            Image(systemName: "link")
                            Text("Open in OpenFoodFacts")
                                .font(.system(size: 15, weight: .heavy, design: .rounded))
                        }
                        .foregroundStyle(AppTheme.Colors.textLight)
                        .frame(maxWidth: .infinity)
                        .frame(height: 58)
                        .background(AppTheme.Colors.primary)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.xl, style: .continuous))
                        .foodLensSoftShadow()
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            }
            .padding(.horizontal, AppTheme.Spacing.xl)
            .padding(.vertical, AppTheme.Spacing.lg)
            .padding(.bottom, MainTabView.tabBarClearance)
        }
        .background(AppTheme.Colors.background.ignoresSafeArea())
    }

    private var offlineBanner: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            Image(systemName: "wifi.slash")
                .foregroundStyle(AppTheme.Colors.warning)
            Text("Showing saved product data (offline)")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(AppTheme.Colors.text)
        }
        .padding(AppTheme.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(hex: 0xFFF4DB))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.md, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radius.md, style: .continuous)
                .stroke(AppTheme.Colors.border, lineWidth: 1)
        )
    }

    private func heroCard(_ p: Product) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
            ZStack {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(AppTheme.Colors.surfaceSoft)
                    .frame(height: 240)
                AsyncImage(url: p.imageUrl.flatMap(URL.init(string:))) { phase in
                    switch phase {
                    case .success(let img):
                        img.resizable().scaledToFit()
                            .frame(maxWidth: .infinity)
                            .frame(height: 220)
                    case .empty:
                        ProgressView()
                    default:
                        Image(systemName: "takeoutbag.and.cup.and.straw.fill")
                            .font(.system(size: 54))
                            .foregroundStyle(AppTheme.Colors.textMuted)
                    }
                }
            }

            if let b = p.brand {
                Text(b)
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                    .foregroundStyle(AppTheme.Colors.primary)
            }
            Text(p.name)
                .font(.system(size: 27, weight: .heavy, design: .rounded))
                .foregroundStyle(AppTheme.Colors.text)
                .fixedSize(horizontal: false, vertical: true)
            if let q = p.quantity {
                Text(q)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppTheme.Colors.textMuted)
            }
        }
        .padding(AppTheme.Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 34, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 34, style: .continuous)
                .stroke(AppTheme.Colors.border, lineWidth: 1)
        )
        .foodLensCardShadow()
    }

    private func scoresRow(_ p: Product) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text("Scores")
                .font(AppTheme.Typography.h2)
                .foregroundStyle(AppTheme.Colors.text)
            HStack(spacing: AppTheme.Spacing.sm) {
                NutriScoreBadge(grade: p.nutriScore, size: .md)
                NovaGroupChip(group: p.novaGroup)
                if p.ecoScore != nil {
                    EcoBadge(grade: p.ecoScore)
                }
            }
        }
        .padding(AppTheme.Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.xl, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radius.xl, style: .continuous)
                .stroke(AppTheme.Colors.border, lineWidth: 1)
        )
    }

    @ViewBuilder
    private func extrasSection(_ p: Product) -> some View {
        let rows: [(String, String?)] = [
            ("Categories", p.categories.isEmpty ? nil : p.categories.joined(separator: ", ")),
            ("Countries", p.countries.isEmpty ? nil : p.countries.joined(separator: ", ")),
            ("Packaging", p.packaging.isEmpty ? nil : p.packaging.joined(separator: ", ")),
            ("Stores", p.stores.isEmpty ? nil : p.stores.joined(separator: ", ")),
            ("Labels", p.labels.isEmpty ? nil : p.labels.joined(separator: ", ")),
            ("Manufacturing", p.manufacturingPlaces),
            ("Origins", p.origins),
        ]
        let hasAny = rows.contains { ($0.1?.isEmpty == false) }
        if hasAny {
            SectionCard(title: "More details") {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                    ForEach(rows.indices, id: \.self) { i in
                        let it = rows[i]
                        if let v = it.1, !v.isEmpty {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(it.0)
                                    .font(AppTheme.Typography.caption)
                                    .foregroundStyle(AppTheme.Colors.textMuted)
                                Text(v)
                                    .font(.system(size: 15, weight: .medium, design: .rounded))
                                    .foregroundStyle(AppTheme.Colors.text)
                            }
                        }
                    }
                }
            }
        }
    }

    private func passportRows(for p: Product) -> [PassportRow] {
        [
            PassportRow(label: "Barcode", value: p.barcode),
            PassportRow(label: "Brand", value: p.brand ?? ""),
            PassportRow(label: "Quantity", value: p.quantity ?? ""),
            PassportRow(label: "Category", value: p.categories.joined(separator: ", ")),
            PassportRow(label: "Countries", value: p.countries.joined(separator: ", ")),
            PassportRow(label: "Source", value: "OpenFoodFacts"),
        ]
    }

    private func nutritionItems(from n: Nutriments) -> [NutritionGridItem] {
        [
            NutritionGridItem(
                label: "Energy",
                value: n.energyKcal100g.map { "\(Int($0.rounded())) kcal" } ?? "—",
                accent: true
            ),
            NutritionGridItem(label: "Sugar", value: n.sugars100g.map(fmtG) ?? "—", accent: false),
            NutritionGridItem(label: "Salt", value: n.salt100g.map(fmtG) ?? "—", accent: false),
            NutritionGridItem(label: "Fat", value: n.fat100g.map(fmtG) ?? "—", accent: false),
            NutritionGridItem(label: "Saturated fat", value: n.saturatedFat100g.map(fmtG) ?? "—", accent: false),
            NutritionGridItem(label: "Protein", value: n.proteins100g.map(fmtG) ?? "—", accent: false),
            NutritionGridItem(label: "Carbohydrates", value: n.carbohydrates100g.map(fmtG) ?? "—", accent: false),
            NutritionGridItem(label: "Fiber", value: n.fiber100g.map(fmtG) ?? "—", accent: false),
        ]
    }

    private func fmtG(_ v: Double) -> String {
        String(format: "%.1f g", v)
    }
}

/// Wraps chips with flexible layout for allergen rows.
private struct FlowChipWrap<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        FlowLayout(spacing: AppTheme.Spacing.sm) {
            content()
        }
    }
}

/// Public flow layout duplicate for product detail — reuse private FlowLayout from FoodLensComponents by making it internal.
/// FlowLayout is private in FoodLensComponents; duplicate minimal version here or export.
private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxW = proposal.width ?? 0
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowH: CGFloat = 0
        for s in subviews {
            let sz = s.sizeThatFits(.unspecified)
            let w = sz.width
            let h = sz.height
            if x + w > maxW, x > 0 {
                x = 0
                y += rowH + spacing
                rowH = 0
            }
            rowH = max(rowH, h)
            x += w + spacing
        }
        return CGSize(width: maxW, height: y + rowH)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let maxW = bounds.width
        var x = bounds.minX
        var y = bounds.minY
        var rowH: CGFloat = 0
        for s in subviews {
            let sz = s.sizeThatFits(.unspecified)
            if x + sz.width > bounds.minX + maxW, x > bounds.minX {
                x = bounds.minX
                y += rowH + spacing
                rowH = 0
            }
            s.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(sz))
            rowH = max(rowH, sz.height)
            x += sz.width + spacing
        }
    }
}
