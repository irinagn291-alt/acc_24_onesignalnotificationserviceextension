import SwiftUI

struct OnboardingView: View {
    @ObservedObject var env: AppEnvironment
    @State private var page = 0

    private let slides: [(title: String, subtitle: String, icon: String, iconBg: Color, iconTint: Color)] = [
        (
            "Scan in seconds",
            "Point at a barcode and pull ingredients, nutrition, and scores from OpenFoodFacts.",
            "barcode.viewfinder",
            AppTheme.Colors.primaryLight,
            AppTheme.Colors.primary
        ),
        (
            "Understand what you eat",
            "Nutri-Score, NOVA, Eco-Score, and gentle warnings about sugar, salt, and fats.",
            "leaf.fill",
            Color(hex: 0xFFF4DB),
            AppTheme.Colors.warning
        ),
        (
            "Save what matters",
            "Keep favorites and history; cached cards work when you are offline.",
            "heart.fill",
            Color(hex: 0xFDECEC),
            AppTheme.Colors.danger
        ),
    ]

    var body: some View {
        ZStack {
            AppTheme.Colors.background.ignoresSafeArea()
            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Button("Skip") { finish() }
                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                        .foregroundStyle(AppTheme.Colors.textMuted)
                }
                .padding(.horizontal, AppTheme.Spacing.xl)
                .padding(.top, AppTheme.Spacing.md)

                HStack(spacing: AppTheme.Spacing.sm) {
                    Image(systemName: "leaf.fill")
                        .foregroundStyle(AppTheme.Colors.primary)
                    Text("Fooduch")
                        .font(.system(size: 18, weight: .heavy, design: .rounded))
                        .foregroundStyle(AppTheme.Colors.primary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, AppTheme.Spacing.xl)
                .padding(.top, AppTheme.Spacing.md)

                TabView(selection: $page) {
                    ForEach(slides.indices, id: \.self) { i in
                        slideView(slides[i])
                            .tag(i)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .padding(.vertical, AppTheme.Spacing.md)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                Button {
                    if page < slides.count - 1 {
                        page += 1
                    } else {
                        finish()
                    }
                } label: {
                    HStack(spacing: AppTheme.Spacing.sm) {
                        Text(page < slides.count - 1 ? "Next" : "Get started")
                            .font(.system(size: 16, weight: .heavy, design: .rounded))
                        Image(systemName: "arrow.right")
                    }
                    .foregroundStyle(AppTheme.Colors.textLight)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(AppTheme.Colors.primary)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.xl, style: .continuous))
                    .foodLensSoftShadow()
                }
                .buttonStyle(ScaleButtonStyle())
                .padding(.horizontal, AppTheme.Spacing.xl)
                .padding(.bottom, AppTheme.Spacing.xxl)
            }
        }
    }

    private func slideView(_ s: (title: String, subtitle: String, icon: String, iconBg: Color, iconTint: Color)) -> some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: AppTheme.Spacing.xl) {
                ZStack {
                    Circle()
                        .fill(s.iconBg)
                        .frame(width: 120, height: 120)
                    Image(systemName: s.icon)
                        .font(.system(size: 52))
                        .foregroundStyle(s.iconTint)
                }
                Text(s.title)
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                    .foregroundStyle(AppTheme.Colors.text)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .minimumScaleFactor(0.85)
                    .padding(.horizontal, AppTheme.Spacing.sm)
                Text(s.subtitle)
                    .font(AppTheme.Typography.body)
                    .foregroundStyle(AppTheme.Colors.textMuted)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, AppTheme.Spacing.md)
            }
            .padding(AppTheme.Spacing.xl)
            .frame(maxWidth: .infinity)
            .background(AppTheme.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 36, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 36, style: .continuous)
                    .stroke(AppTheme.Colors.border, lineWidth: 1)
            )
            .foodLensCardShadow()
            .padding(.horizontal, AppTheme.Spacing.xl)
            .padding(.vertical, AppTheme.Spacing.md)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func finish() {
        Task {
            try? await env.settingsRepository.update { s in
                var c = s
                c.onboardingCompleted = true
                return c
            }
            await env.refreshOnboardingFlag()
        }
    }
}
