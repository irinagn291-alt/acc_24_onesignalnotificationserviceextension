import SwiftUI

enum AppTheme {
    enum Colors {
        static let background = Color(hex: 0xF7F4EC)
        static let surface = Color(hex: 0xFFFFFF)
        static let surfaceSoft = Color(hex: 0xFFF9ED)
        static let primary = Color(hex: 0x2E7D5B)
        static let primaryDark = Color(hex: 0x1F5C43)
        static let primaryLight = Color(hex: 0xDFF3E8)
        static let secondary = Color(hex: 0xF4A261)
        static let accent = Color(hex: 0x88D498)
        static let text = Color(hex: 0x1F2933)
        static let textMuted = Color(hex: 0x7B8794)
        static let textLight = Color(hex: 0xFFFFFF)
        static let border = Color(hex: 0xE7E2D8)
        static let danger = Color(hex: 0xE85D5D)
        static let warning = Color(hex: 0xF59E0B)
        static let success = Color(hex: 0x2E7D5B)
        static let info = Color(hex: 0x3B82F6)
        static let skeleton = Color(hex: 0xECE7DD)

        static let nutriA = Color(hex: 0x038141)
        static let nutriB = Color(hex: 0x85BB2F)
        static let nutriC = Color(hex: 0xFECB02)
        static let nutriD = Color(hex: 0xEE8100)
        static let nutriE = Color(hex: 0xE63E11)

        static let nova1 = Color(hex: 0x2E7D5B)
        static let nova2 = Color(hex: 0x8BC34A)
        static let nova3 = Color(hex: 0xF59E0B)
        static let nova4 = Color(hex: 0xE85D5D)
    }

    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
    }

    enum Radius {
        static let sm: CGFloat = 10
        static let md: CGFloat = 16
        static let lg: CGFloat = 22
        static let xl: CGFloat = 30
    }

    enum Typography {
        static let title = Font.system(size: 28, weight: .heavy, design: .rounded)
        static let h1 = Font.system(size: 26, weight: .heavy, design: .rounded)
        static let h2 = Font.system(size: 20, weight: .bold, design: .rounded)
        static let body = Font.system(size: 15, weight: .regular, design: .rounded)
        static let bodyMuted = Font.system(size: 14, weight: .regular, design: .rounded)
        static let caption = Font.system(size: 12, weight: .semibold, design: .rounded)
        static let eyebrow = Font.system(size: 15, weight: .heavy, design: .rounded)
    }
}

extension Color {
    init(hex: UInt32, alpha: Double = 1) {
        let r = Double((hex >> 16) & 0xFF) / 255
        let g = Double((hex >> 8) & 0xFF) / 255
        let b = Double(hex & 0xFF) / 255
        self.init(.sRGB, red: r, green: g, blue: b, opacity: alpha)
    }

    static func nutriScoreColor(grade: String?) -> Color {
        switch grade?.lowercased() {
        case "a": AppTheme.Colors.nutriA
        case "b": AppTheme.Colors.nutriB
        case "c": AppTheme.Colors.nutriC
        case "d": AppTheme.Colors.nutriD
        case "e": AppTheme.Colors.nutriE
        default: AppTheme.Colors.textMuted
        }
    }

    static func novaGroupColor(group: Int?) -> Color {
        switch group {
        case 1: AppTheme.Colors.nova1
        case 2: AppTheme.Colors.nova2
        case 3: AppTheme.Colors.nova3
        case 4: AppTheme.Colors.nova4
        default: AppTheme.Colors.textMuted
        }
    }

    static func warningTint(for severity: ProductWarningSeverity) -> Color {
        switch severity {
        case .danger: AppTheme.Colors.danger
        case .caution: AppTheme.Colors.warning
        case .info: AppTheme.Colors.info
        }
    }
}

extension View {
    func foodLensCardShadow() -> some View {
        shadow(color: AppTheme.Colors.text.opacity(0.10), radius: 20, x: 0, y: 10)
    }

    func foodLensSoftShadow() -> some View {
        shadow(color: AppTheme.Colors.text.opacity(0.08), radius: 20, x: 0, y: 8)
    }
}
