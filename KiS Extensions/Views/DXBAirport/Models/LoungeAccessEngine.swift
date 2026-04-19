// MARK: - LoungeAccessEngine
// Evaluates a PassengerContext against a Lounge's AccessRules.
// Pure function — no state. Safe for Swift 6 strict concurrency.

import Foundation

enum LoungeAccessEngine {

    static func decide(
        passenger: PassengerContext,
        lounge: Lounge
    ) -> LoungeAccessDecision {

        let rules = lounge.accessRules

        // 1. Deny conditions first
        if let denies = rules.denyConditions {
            for predicate in denies where matches(predicate: predicate, passenger: passenger) {
                return .denied(reason: denyReasonText(predicate))
            }
        }

        // 2. Complimentary — first match wins
        if let comps = rules.complimentary {
            for rule in comps where matches(predicate: rule.match, passenger: passenger) {
                if let guests = rule.guests {
                    return .allowedWithLimitedGuests(
                        maxAdults: guests.adults,
                        maxChildren: guests.childrenUnder17,
                        reason: complimentaryReasonText(rule.match, lounge: lounge)
                    )
                }
                return .allowed(
                    reason: complimentaryReasonText(rule.match, lounge: lounge),
                    guests: nil
                )
            }
        }

        // 3. Paid access
        if let paids = rules.paidAccess {
            for rule in paids where matches(predicate: rule.match, passenger: passenger) {
                return .paidOnly(
                    approxPriceUSD: rule.approxPriceUSD,
                    approxPriceAED: rule.approxPriceAED,
                    reason: paidReasonText(rule.match)
                )
            }
        }

        return .denied(reason: "No matching access rule for this passenger profile")
    }

    // MARK: - Predicate matching

    private static func matches(
        predicate: AccessPredicate,
        passenger: PassengerContext
    ) -> Bool {
        // anyPax: shorthand "any passenger qualifies" (used for paid lounges)
        if predicate.anyPax == true { return true }

        // Each non-nil field must match. Nil means "don't care".
        if let cc = predicate.cabinClass, !cc.values.contains(passenger.cabinClass.rawValue) {
            return false
        }
        if let tier = predicate.skywardsTier, !tier.values.contains(passenger.skywardsTier.rawValue) {
            return false
        }
        if let surfer = predicate.skywardsSkysurfer {
            guard let s = passenger.skywardsSkysurfer else { return false }
            if !surfer.values.contains(s.rawValue) { return false }
        }
        if let member = predicate.skywardsMember, member == true {
            // True means "must be a Skywards member" — Blue+ qualifies
            // (everyone in our tier enum is a member; Blue is the entry tier)
            // Adjust if you add a 'nonMember' state.
        }
        if let op = predicate.`operator`, op != passenger.operatingCarrier.lowercased() {
            // Note: JSON uses "flydubai", PassengerContext uses "FZ" — normalise here
            let normalisedPaxOp = passenger.operatingCarrier == "FZ" ? "flydubai" : passenger.operatingCarrier.lowercased()
            if op != normalisedPaxOp { return false }
        }
        if let jt = predicate.journeyType, jt != passenger.journeyType.rawValue {
            return false
        }
        return true
    }

    // MARK: - Reason text

    private static func complimentaryReasonText(_ p: AccessPredicate, lounge: Lounge) -> String {
        if let cc = p.cabinClass {
            return "\(cc.values.joined(separator: "/")) class passenger"
        }
        if let t = p.skywardsTier {
            return "Skywards \(t.values.joined(separator: "/"))"
        }
        if let s = p.skywardsSkysurfer {
            return "Skywards Skysurfer \(s.values.joined(separator: "/"))"
        }
        return "Eligible"
    }

    private static func paidReasonText(_ p: AccessPredicate) -> String {
        if let t = p.skywardsTier {
            return "Paid access — Skywards \(t.values.joined(separator: "/"))"
        }
        if let cc = p.cabinClass {
            return "Paid access — \(cc.values.joined(separator: "/")) class"
        }
        return "Paid access available"
    }

    private static func denyReasonText(_ p: AccessPredicate) -> String {
        if p.journeyType == "arriving" {
            return "Lounge access not available for arriving passengers"
        }
        return "Access not permitted"
    }
}
