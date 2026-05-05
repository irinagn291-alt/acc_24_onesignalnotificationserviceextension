import Foundation

struct WarningRuleConfig: Codable, Sendable, Equatable {
    var highSugarThresholdG: Double
    var highSaltThresholdG: Double
    var highSaturatedFatThresholdG: Double
    var highSugarMessage: String
    var highSaltMessage: String
    var highSaturatedFatMessage: String
    var ultraProcessedMessage: String
    var palmOilMessage: String

    static let bundleDefaults = WarningRuleConfig(
        highSugarThresholdG: 22.5,
        highSaltThresholdG: 1.5,
        highSaturatedFatThresholdG: 5,
        highSugarMessage: "High sugar content",
        highSaltMessage: "High salt content",
        highSaturatedFatMessage: "High saturated fat content",
        ultraProcessedMessage: "Ultra-processed product",
        palmOilMessage: "Contains palm oil"
    )

    static func loadFromBundle() -> WarningRuleConfig {
        guard let url = Bundle.main.url(forResource: "WarningRules", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode(WarningRuleConfig.self, from: data)
        else {
            return .bundleDefaults
        }
        return decoded
    }
}
