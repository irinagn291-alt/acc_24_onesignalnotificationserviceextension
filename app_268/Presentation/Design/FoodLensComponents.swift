import SwiftUI

// MARK: - Press scale

struct ScaleButtonStyle: ButtonStyle {
    var scale: CGFloat = 0.98

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .opacity(configuration.isPressed ? 0.92 : 1)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Search

struct SearchField: View {
    @Binding var text: String
    var placeholder: String
    var onSubmit: (() -> Void)?

    var body: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(AppTheme.Colors.textMuted)
            TextField("", text: $text, prompt: Text(placeholder).foregroundStyle(AppTheme.Colors.textMuted))
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.search)
                .onSubmit { onSubmit?() }
                .font(.system(size: 16, weight: .regular, design: .rounded))
                .foregroundStyle(AppTheme.Colors.text)
        }
        .padding(.horizontal, AppTheme.Spacing.lg)
        .frame(height: 56)
        .background(AppTheme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.lg, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radius.lg, style: .continuous)
                .stroke(AppTheme.Colors.border, lineWidth: 1)
        )
        .foodLensSoftShadow()
    }
}

// MARK: - Scan CTA

struct PrimaryScanCard: View {
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: AppTheme.Spacing.lg) {
                ZStack {
                    Circle()
                        .fill(AppTheme.Colors.primaryLight)
                        .frame(width: 62, height: 62)
                    Image(systemName: "barcode.viewfinder")
                        .font(.system(size: 30, weight: .medium))
                        .foregroundStyle(AppTheme.Colors.primary)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("Scan product")
                        .font(.system(size: 19, weight: .heavy, design: .rounded))
                        .foregroundStyle(AppTheme.Colors.textLight)
                    Text("Ingredients, allergens, and scores in one place.")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(AppTheme.Colors.textLight.opacity(0.78))
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(AppTheme.Colors.textLight)
            }
            .padding(AppTheme.Spacing.lg)
            .frame(maxWidth: .infinity, minHeight: 104, alignment: .leading)
            .background(AppTheme.Colors.primary)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.xl, style: .continuous))
            .foodLensCardShadow()
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Product card

struct ProductCard: View {
    var name: String
    var brand: String?
    var imageURL: URL?
    var nutriScore: String?
    var calories: Double?
    var sugar: Double?
    var salt: Double?
    var onTap: () -> Void
    var wrapsInButton: Bool = true

    var body: some View {
        Group {
            if wrapsInButton {
                Button(action: onTap) { cardInner }
                    .buttonStyle(ScaleButtonStyle(scale: 0.985))
            } else {
                cardInner
            }
        }
    }

    private var cardInner: some View {
        HStack(alignment: .top, spacing: AppTheme.Spacing.md) {
                ZStack {
                    RoundedRectangle(cornerRadius: AppTheme.Radius.lg, style: .continuous)
                        .fill(AppTheme.Colors.surfaceSoft)
                        .frame(width: 94, height: 112)
                    productThumb
                }
                VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                    Text(name.isEmpty ? "Untitled" : name)
                        .font(.system(size: 17, weight: .heavy, design: .rounded))
                        .foregroundStyle(AppTheme.Colors.text)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    if let brand, !brand.isEmpty {
                        Text(brand)
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundStyle(AppTheme.Colors.textMuted)
                            .lineLimit(1)
                    }
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                        NutriScoreBadge(grade: nutriScore, size: .sm)
                        metricsRow
                    }
                    .padding(.top, 4)
                }
                Spacer(minLength: 0)
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.xl, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radius.xl, style: .continuous)
                .stroke(AppTheme.Colors.border, lineWidth: 1)
        )
        .foodLensSoftShadow()
    }

    @ViewBuilder
    private var productThumb: some View {
        if let imageURL {
            AsyncImage(url: imageURL) { phase in
                switch phase {
                case .success(let img):
                    img.resizable().scaledToFit()
                        .frame(width: 82, height: 100)
                case .empty:
                    ProgressView()
                default:
                    Image(systemName: "takeoutbag.and.cup.and.straw.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(AppTheme.Colors.textMuted)
                }
            }
        } else {
            Image(systemName: "takeoutbag.and.cup.and.straw.fill")
                .font(.system(size: 32))
                .foregroundStyle(AppTheme.Colors.textMuted)
        }
    }

    @ViewBuilder
    private var metricsRow: some View {
        let chips = metricsChips
        if !chips.isEmpty {
            FlowLayout(spacing: 6) {
                ForEach(chips, id: \.self) { t in
                    Text(t)
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.Colors.primaryDark)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 5)
                        .background(AppTheme.Colors.primaryLight)
                        .clipShape(Capsule())
                }
            }
        }
    }

    private var metricsChips: [String] {
        var r: [String] = []
        if let kcal = calories { r.append("\(Int(kcal.rounded())) kcal") }
        if let s = sugar { r.append(String(format: "Sugar %.1f g", s)) }
        if let s = salt { r.append(String(format: "Salt %.1f g", s)) }
        return r
    }
}

/// Simple horizontal flow for metric chips.
private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxW = proposal.width ?? 0
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowH: CGFloat = 0
        for s in subviews {
            let sz = s.sizeThatFits(.unspecified)
            if x + sz.width > maxW, x > 0 {
                x = 0
                y += rowH + spacing
                rowH = 0
            }
            rowH = max(rowH, sz.height)
            x += sz.width + spacing
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

// MARK: - Section card

struct SectionCard<Content: View, Right: View>: View {
    var title: String
    var subtitle: String?
    @ViewBuilder var right: () -> Right
    @ViewBuilder var content: () -> Content

    init(
        title: String,
        subtitle: String? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) where Right == EmptyView {
        self.title = title
        self.subtitle = subtitle
        self.right = { EmptyView() }
        self.content = content
    }

    init(
        title: String,
        subtitle: String? = nil,
        @ViewBuilder right: @escaping () -> Right,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.right = right
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            HStack(alignment: .top, spacing: AppTheme.Spacing.md) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 19, weight: .heavy, design: .rounded))
                        .foregroundStyle(AppTheme.Colors.text)
                    if let subtitle {
                        Text(subtitle)
                            .font(AppTheme.Typography.bodyMuted)
                            .foregroundStyle(AppTheme.Colors.textMuted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                Spacer()
                right()
            }
            content()
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
}

// MARK: - Warning

struct WarningCard: View {
    var severity: ProductWarningSeverity
    var title: String
    var description: String?

    private var config: (bg: Color, iconBg: Color, icon: String) {
        switch severity {
        case .danger:
            (Color(hex: 0xFDECEC), Color(hex: 0xFBD1D1), "exclamationmark.triangle.fill")
        case .caution:
            (Color(hex: 0xFFF4DB), Color(hex: 0xFFE2A8), "exclamationmark.triangle.fill")
        case .info:
            (Color(hex: 0xEAF2FF), Color(hex: 0xD5E7FF), "info.circle.fill")
        }
    }

    var body: some View {
        let cfg = config
        HStack(alignment: .top, spacing: AppTheme.Spacing.md) {
            ZStack {
                Circle()
                    .fill(cfg.iconBg)
                    .frame(width: 40, height: 40)
                Image(systemName: cfg.icon)
                    .font(.system(size: 18))
                    .foregroundStyle(Color.warningTint(for: severity))
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color.warningTint(for: severity))
                if let description {
                    Text(description)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(AppTheme.Colors.textMuted)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(AppTheme.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cfg.bg)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.md, style: .continuous))
    }
}

// MARK: - Nutrition grid

struct NutritionGridItem: Identifiable {
    var id: String { label }
    var label: String
    var value: String
    var accent: Bool
}

struct NutritionGrid: View {
    let items: [NutritionGridItem]

    private let columns = [GridItem(.flexible(), spacing: AppTheme.Spacing.md), GridItem(.flexible(), spacing: AppTheme.Spacing.md)]

    var body: some View {
        LazyVGrid(columns: columns, spacing: AppTheme.Spacing.md) {
            ForEach(items) { item in
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.value)
                        .font(.system(size: 22, weight: .heavy, design: .rounded))
                        .foregroundStyle(item.accent ? AppTheme.Colors.textLight : AppTheme.Colors.text)
                    Text(item.label)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(item.accent ? AppTheme.Colors.textLight.opacity(0.85) : AppTheme.Colors.textMuted)
                }
                .padding(AppTheme.Spacing.lg)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(item.accent ? AppTheme.Colors.primary : AppTheme.Colors.surface)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.lg, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.Radius.lg, style: .continuous)
                        .stroke(item.accent ? AppTheme.Colors.primary : AppTheme.Colors.border, lineWidth: 1)
                )
            }
        }
    }
}

// MARK: - Chip

struct Chip: View {
    enum Variant {
        case `default`, danger, warning, success, primary
    }

    var label: String
    var variant: Variant = .default

    private var colors: (Color, Color) {
        switch variant {
        case .default:
            (Color(hex: 0xF1EEE7), AppTheme.Colors.text)
        case .danger:
            (Color(hex: 0xFDECEC), AppTheme.Colors.danger)
        case .warning:
            (Color(hex: 0xFFF4DB), AppTheme.Colors.warning)
        case .success:
            (AppTheme.Colors.primaryLight, AppTheme.Colors.primaryDark)
        case .primary:
            (AppTheme.Colors.primaryLight, AppTheme.Colors.primaryDark)
        }
    }

    var body: some View {
        let c = colors
        Text(label)
            .font(.system(size: 12, weight: .heavy, design: .rounded))
            .foregroundStyle(c.1)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(c.0)
            .clipShape(Capsule())
    }
}

// MARK: - Passport

struct PassportRow: Identifiable {
    var id: String { label }
    var label: String
    var value: String
}

struct ProductPassport: View {
    let rows: [PassportRow]

    var body: some View {
        let visible = rows.filter { !$0.value.isEmpty }
        if visible.isEmpty { EmptyView() }
        else {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                Text("Product passport")
                    .font(.system(size: 19, weight: .heavy, design: .rounded))
                    .foregroundStyle(AppTheme.Colors.text)
                VStack(spacing: 0) {
                    ForEach(Array(visible.enumerated()), id: \.offset) { index, row in
                        HStack(alignment: .top, spacing: AppTheme.Spacing.md) {
                            Text(row.label)
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundStyle(AppTheme.Colors.textMuted)
                                .frame(width: 110, alignment: .leading)
                            Text(row.value)
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundStyle(AppTheme.Colors.text)
                                .multilineTextAlignment(.trailing)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                        }
                        .padding(.vertical, 12)
                        if index != visible.count - 1 {
                            Divider().background(AppTheme.Colors.border)
                        }
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
    }
}

// MARK: - Empty state

struct EmptyState: View {
    var icon: String = "leaf"
    var title: String
    var description: String
    var actionTitle: String?
    var onAction: (() -> Void)?

    var body: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            ZStack {
                Circle()
                    .fill(AppTheme.Colors.primaryLight)
                    .frame(width: 86, height: 86)
                Image(systemName: icon)
                    .font(.system(size: 36))
                    .foregroundStyle(AppTheme.Colors.primary)
            }
            Text(title)
                .font(.system(size: 21, weight: .heavy, design: .rounded))
                .foregroundStyle(AppTheme.Colors.text)
                .multilineTextAlignment(.center)
            Text(description)
                .font(AppTheme.Typography.bodyMuted)
                .foregroundStyle(AppTheme.Colors.textMuted)
                .multilineTextAlignment(.center)
            if let actionTitle, let onAction {
                Button(action: onAction) {
                    Text(actionTitle)
                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                        .foregroundStyle(AppTheme.Colors.textLight)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 12)
                        .background(AppTheme.Colors.primary)
                        .clipShape(Capsule())
                }
                .buttonStyle(ScaleButtonStyle())
            }
        }
        .padding(AppTheme.Spacing.xl)
        .frame(maxWidth: .infinity)
        .background(AppTheme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(AppTheme.Colors.border, lineWidth: 1)
        )
    }
}

// MARK: - Settings row

struct SettingsRow: View {
    var icon: String
    var title: String
    var subtitle: String?
    var danger: Bool
    var action: (() -> Void)?

    init(
        icon: String,
        title: String,
        subtitle: String? = nil,
        danger: Bool = false,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.danger = danger
        self.action = action
    }

    var body: some View {
        Group {
            if let action {
                Button(action: action) { label }
                    .buttonStyle(ScaleButtonStyle(scale: 0.99))
            } else {
                label
            }
        }
    }

    private var label: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            ZStack {
                Circle()
                    .fill(danger ? Color(hex: 0xFDECEC) : AppTheme.Colors.primaryLight)
                    .frame(width: 44, height: 44)
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(danger ? AppTheme.Colors.danger : AppTheme.Colors.primary)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                    .foregroundStyle(danger ? AppTheme.Colors.danger : AppTheme.Colors.text)
                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(AppTheme.Colors.textMuted)
                }
            }
            Spacer()
            if action != nil {
                Image(systemName: "chevron.right")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(AppTheme.Colors.textMuted)
            }
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.md, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radius.md, style: .continuous)
                .stroke(AppTheme.Colors.border, lineWidth: 1)
        )
    }
}

// MARK: - Skeleton

struct ProductCardSkeleton: View {
    var body: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            RoundedRectangle(cornerRadius: AppTheme.Radius.lg, style: .continuous)
                .fill(AppTheme.Colors.skeleton)
                .frame(width: 94, height: 112)
            VStack(alignment: .leading, spacing: 12) {
                RoundedRectangle(cornerRadius: 999)
                    .fill(AppTheme.Colors.skeleton)
                    .frame(height: 18)
                    .frame(maxWidth: .infinity)
                RoundedRectangle(cornerRadius: 999)
                    .fill(AppTheme.Colors.skeleton)
                    .frame(width: 120, height: 14)
                RoundedRectangle(cornerRadius: 999)
                    .fill(AppTheme.Colors.skeleton)
                    .frame(width: 110, height: 32)
            }
            .padding(.vertical, 6)
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.xl, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radius.xl, style: .continuous)
                .stroke(AppTheme.Colors.border, lineWidth: 1)
        )
    }
}
