import Foundation

// MARK: - We Care Rules Loader

/// Loads the bundled We Care rule base once, at launch. The rule base is a
/// shipped, offline resource: a decode failure is a build error, so we fail
/// loudly rather than degrade silently.
enum WeCareRulesLoader {

    /// The decoded rule base. Force-loaded at app launch (see KiS_ExtensionsApp).
    static let shared: WeCareRules = load()

    static let resourceName = "we_care_rules_v1_30"

    static func load() -> WeCareRules {
        guard let url = Bundle.main.url(forResource: resourceName, withExtension: "json") else {
            fatalError("We Care: \(resourceName).json is missing from the app bundle.")
        }
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(WeCareRules.self, from: data)
        } catch {
            fatalError("We Care: failed to decode \(resourceName).json — \(error)")
        }
    }
}
