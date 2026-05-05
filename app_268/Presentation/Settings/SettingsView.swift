import SwiftUI

struct SettingsView: View {
    @ObservedObject var env: AppEnvironment
    @State private var snapshot = AppSettingsSnapshot.default
    @State private var showingPrivacy = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xl) {
                sectionTitle("OpenFoodFacts")
                VStack(spacing: AppTheme.Spacing.sm) {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                        Text("Search region")
                            .font(AppTheme.Typography.caption)
                            .foregroundStyle(AppTheme.Colors.textMuted)
                        Picker("Search region", selection: Binding(
                            get: { hostToRegion(snapshot.openFoodFactsHost) },
                            set: { new in Task { await updateHost(new.host) } }
                        )) {
                            ForEach(OpenFoodFactsRegion.allCases) { r in
                                Text(r.displayTitle).tag(r)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(AppTheme.Colors.primary)
                    }
                    .padding(AppTheme.Spacing.lg)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AppTheme.Colors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.lg, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.Radius.lg, style: .continuous)
                            .stroke(AppTheme.Colors.border, lineWidth: 1)
                    )

                    if let url = URL(string: "https://world.openfoodfacts.org") {
                        Link(destination: url) {
                            SettingsRow(
                                icon: "globe",
                                title: "OpenFoodFacts website",
                                subtitle: "Browse the public database",
                                action: nil
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }

                sectionTitle("Interface")
                VStack(spacing: AppTheme.Spacing.sm) {
                    HStack {
                        Text("Metric units")
                            .font(.system(size: 15, weight: .heavy, design: .rounded))
                        Spacer()
                        Toggle("", isOn: Binding(
                            get: { snapshot.useMetricUnits },
                            set: { v in Task { await updateMetric(v) } }
                        ))
                        .labelsHidden()
                        .tint(AppTheme.Colors.primary)
                    }
                    .padding(AppTheme.Spacing.lg)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AppTheme.Colors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.lg, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.Radius.lg, style: .continuous)
                            .stroke(AppTheme.Colors.border, lineWidth: 1)
                    )
                }

                sectionTitle("Storage")
                VStack(spacing: AppTheme.Spacing.sm) {
                    SettingsRow(
                        icon: "trash.circle",
                        title: "Clear product cache",
                        subtitle: "Remove cached product cards",
                        action: {
                            Task { try? await env.cacheRepository.clearAllProductCache() }
                        }
                    )
                    SettingsRow(
                        icon: "clock.badge.xmark",
                        title: "Clear scan history",
                        subtitle: "Cannot be undone",
                        danger: true,
                        action: {
                            Task { try? await env.historyRepository.clear() }
                        }
                    )
                }

                sectionTitle("Legal")
                SettingsRow(
                    icon: "hand.raised.fill",
                    title: "Privacy policy",
                    subtitle: "How data is stored on device",
                    action: { showingPrivacy = true }
                )

                sectionTitle("About")
                VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                    Text(medicalDisclaimer)
                        .font(AppTheme.Typography.bodyMuted)
                        .foregroundStyle(AppTheme.Colors.textMuted)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("Version \(Bundle.main.infoDictVersion)")
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.Colors.textMuted)
                }
                .padding(AppTheme.Spacing.lg)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppTheme.Colors.surfaceSoft)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.lg, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.Radius.lg, style: .continuous)
                        .stroke(AppTheme.Colors.border, lineWidth: 1)
                )
            }
            .padding(.horizontal, AppTheme.Spacing.xl)
            .padding(.vertical, AppTheme.Spacing.lg)
            .padding(.bottom, MainTabView.tabBarClearance)
        }
        .background(AppTheme.Colors.background.ignoresSafeArea())
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AppTheme.Colors.background, for: .navigationBar)
        .task { await reload() }
        .sheet(isPresented: $showingPrivacy) {
            NavigationStack {
                ScrollView {
                    Text(privacyText)
                        .font(AppTheme.Typography.body)
                        .foregroundStyle(AppTheme.Colors.text)
                        .padding(AppTheme.Spacing.xl)
                }
                .background(AppTheme.Colors.background)
                .navigationTitle("Privacy")
                .toolbarBackground(AppTheme.Colors.background, for: .navigationBar)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Close") { showingPrivacy = false }
                    }
                }
            }
        }
    }

    private func sectionTitle(_ s: String) -> some View {
        Text(s.uppercased())
            .font(.system(size: 12, weight: .heavy, design: .rounded))
            .foregroundStyle(AppTheme.Colors.textMuted)
            .tracking(0.6)
    }

    private func reload() async {
        do {
            snapshot = try await env.settingsRepository.snapshot()
        } catch {}
    }

    private func updateHost(_ host: String) async {
        try? await env.settingsRepository.update { s in
            var c = s
            c.openFoodFactsHost = host
            return c
        }
        await reload()
    }

    private func updateMetric(_ v: Bool) async {
        try? await env.settingsRepository.update { s in
            var c = s
            c.useMetricUnits = v
            return c
        }
        await reload()
    }

    private func hostToRegion(_ host: String) -> OpenFoodFactsRegion {
        OpenFoodFactsRegion.allCases.first { $0.host == host } ?? .world
    }

    private var medicalDisclaimer: String {
        "Product information comes from the OpenFoodFacts community database and may be incomplete or inaccurate. This app is not medical advice—always read the label and talk to a professional when needed."
    }

    private var privacyText: String {
        """
        On this device we store: scan history, favorites, settings, and a cache of product cards you opened.

        The camera is used only to read barcodes. Images are not saved or uploaded.

        Product data is requested from OpenFoodFacts over HTTPS. We do not collect personal health information.

        Fooduch is not a medical service.
        """
    }
}

private extension Bundle {
    var infoDictVersion: String {
        (infoDictionary?["CFBundleShortVersionString"] as? String) ?? "1.0"
    }
}
