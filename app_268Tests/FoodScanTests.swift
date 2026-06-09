import XCTest

@testable import app_268

final class WarningEngineTests: XCTestCase {
    func testHighSugarWarns() {
        let rules = WarningRuleConfig.bundleDefaults
        let engine = WarningEngine(rules: rules)
        var p = Product.placeholder(barcode: "0")
        p.nutriments.sugars100g = rules.highSugarThresholdG + 1
        let w = engine.evaluate(product: p)
        XCTAssertTrue(w.contains { $0.kind == .highSugar })
    }

    func testNova4UltraProcessed() {
        let engine = WarningEngine(rules: .bundleDefaults)
        var p = Product.placeholder(barcode: "0")
        p.novaGroup = 4
        XCTAssertTrue(engine.evaluate(product: p).contains { $0.kind == .ultraProcessed })
    }

    func testProductMapperNutrimentsFromJSON() throws {
        let json = """
        {"code":"1","status":1,"product":{"product_name":"T","nutriments":{"sugars_100g":"10.5","salt_100g":2}}}
        """
        .data(using: .utf8)!
        let dec = JSONDecoder()
        dec.keyDecodingStrategy = .convertFromSnakeCase
        let dto = try dec.decode(ProductResponseDTO.self, from: json)
        let off = try XCTUnwrap(dto.product)
        let prod = ProductMapper.map(dto: off, fallbackBarcode: "1")
        XCTAssertEqual(prod.nutriments.sugars100g, 10.5, accuracy: 0.01)
    }
}
