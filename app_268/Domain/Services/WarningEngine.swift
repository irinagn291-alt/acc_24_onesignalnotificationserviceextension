import Foundation

struct WarningEngine {
    private let rules: WarningRuleConfig

    init(rules: WarningRuleConfig = .loadFromBundle()) {
        self.rules = rules
    }

    func evaluate(product: Product) -> [ProductWarning] {
        var r: [ProductWarning] = []
        let n = product.nutriments

        if let s = n.sugars100g, s > rules.highSugarThresholdG {
            r.append(ProductWarning(kind: .highSugar, severity: .caution, message: rules.highSugarMessage))
        }
        if let s = n.salt100g, s > rules.highSaltThresholdG {
            r.append(ProductWarning(kind: .highSalt, severity: .caution, message: rules.highSaltMessage))
        }
        if let f = n.saturatedFat100g, f > rules.highSaturatedFatThresholdG {
            r.append(ProductWarning(kind: .highSaturatedFat, severity: .caution, message: rules.highSaturatedFatMessage))
        }
        if product.novaGroup == 4 {
            r.append(ProductWarning(kind: .ultraProcessed, severity: .caution, message: rules.ultraProcessedMessage))
        }
        if product.palmOilIngredients {
            r.append(ProductWarning(kind: .palmOil, severity: .info, message: rules.palmOilMessage))
        }
        return r
    }
}
