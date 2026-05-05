import SwiftUI

struct NutriScoreBadge: View {
    let grade: String?
    var size: NutriBadgeSize = .md

    enum NutriBadgeSize {
        case sm, md, lg
        var paddingH: CGFloat {
            switch self {
            case .sm: 10
            case .md: 12
            case .lg: 18
            }
        }

        var paddingV: CGFloat {
            switch self {
            case .sm: 5
            case .md: 7
            case .lg: 10
            }
        }

        var scoreFont: Font {
            switch self {
            case .sm: .system(size: 14, weight: .black, design: .rounded)
            case .md: .system(size: 18, weight: .black, design: .rounded)
            case .lg: .system(size: 24, weight: .black, design: .rounded)
            }
        }
    }

    var body: some View {
        let normalized = grade?.lowercased()
        let known = normalized.flatMap { ["a", "b", "c", "d", "e"].contains($0) ? $0 : nil }

        if let known {
            HStack(spacing: AppTheme.Spacing.sm) {
                Text("Nutri-Score")
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.Colors.textLight.opacity(0.9))
                Text(known.uppercased())
                    .font(size.scoreFont)
                    .foregroundStyle(AppTheme.Colors.textLight)
            }
            .padding(.horizontal, size.paddingH)
            .padding(.vertical, size.paddingV)
            .background(Color.nutriScoreColor(grade: known))
            .clipShape(Capsule())
            .accessibilityLabel("Nutri-Score \(known.uppercased())")
        } else {
            Text("Nutri-Score unknown")
                .font(AppTheme.Typography.caption)
                .foregroundStyle(AppTheme.Colors.textMuted)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(AppTheme.Colors.skeleton)
                .clipShape(Capsule())
                .accessibilityLabel("Nutri-Score unknown")
        }
    }
}

struct EcoBadge: View {
    let grade: String?

    var body: some View {
        let t = (grade?.uppercased()) ?? "—"
        Text("Eco \(t)")
            .font(.system(size: 12, weight: .heavy, design: .rounded))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.nutriScoreColor(grade: grade))
            .foregroundStyle(AppTheme.Colors.textLight)
            .clipShape(Capsule())
    }
}

struct NovaGroupChip: View {
    let group: Int?

    var body: some View {
        VStack(spacing: 2) {
            Text("NOVA")
                .font(.system(size: 10, weight: .heavy, design: .rounded))
                .foregroundStyle(AppTheme.Colors.primaryDark)
            Text(group.map(String.init) ?? "—")
                .font(.system(size: 17, weight: .heavy, design: .rounded))
                .foregroundStyle(AppTheme.Colors.primaryDark)
        }
        .frame(minWidth: 62)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(AppTheme.Colors.primaryLight)
        .clipShape(Capsule())
    }
}
