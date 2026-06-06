import SwiftUI

// MARK: - Access Checker Sheet

/// Form-driven passenger profile picker. Evaluates `LoungeAccessEngine.decide`
/// live as inputs change so crew get an immediate verdict at the bottom.
struct AccessCheckerSheet: View {
    let lounge: Lounge
    @Environment(\.dismiss) private var dismiss

    @State private var cabinClass: CabinClass = .Y
    @State private var skywardsTier: SkywardsTier = .Blue
    @State private var carrier: OperatingCarrier = .EK
    @State private var journeyType: JourneyType = .originating
    @State private var skysurferEnabled: Bool = false
    @State private var skysurferTier: SkywardsTier = .Blue
    @State private var guestAdults: Int = 0
    @State private var guestChildren: Int = 0

    private var passenger: PassengerContext {
        PassengerContext(
            cabinClass: cabinClass,
            skywardsTier: skywardsTier,
            skywardsSkysurfer: skysurferEnabled ? skysurferTier : nil,
            operatingCarrier: carrier.rawValue,
            journeyType: journeyType,
            partnerStatus: nil,
            requestedGuests: PassengerContext.GuestRequest(
                adults: guestAdults,
                childrenUnder17: guestChildren
            )
        )
    }

    private var decision: LoungeAccessDecision {
        LoungeAccessEngine.decide(passenger: passenger, lounge: lounge)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Cabin") {
                    Picker("Cabin class", selection: $cabinClass) {
                        ForEach(CabinClass.allCases, id: \.self) { cc in
                            Text(cabinLabel(cc)).tag(cc)
                        }
                    }
                }

                Section("Skywards") {
                    Picker("Tier", selection: $skywardsTier) {
                        ForEach(SkywardsTier.allCases, id: \.self) { t in
                            Text(tierLabel(t)).tag(t)
                        }
                    }

                    Toggle("Skysurfer companion", isOn: $skysurferEnabled)
                    if skysurferEnabled {
                        Picker("Skysurfer tier", selection: $skysurferTier) {
                            ForEach(SkywardsTier.allCases, id: \.self) { t in
                                Text(tierLabel(t)).tag(t)
                            }
                        }
                    }
                }

                Section("Flight") {
                    Picker("Operating carrier", selection: $carrier) {
                        ForEach(OperatingCarrier.allCases, id: \.self) { c in
                            Text(carrierLabel(c)).tag(c)
                        }
                    }
                    Picker("Journey", selection: $journeyType) {
                        ForEach([JourneyType.originating, .connecting, .arriving], id: \.self) { jt in
                            Text(journeyLabel(jt)).tag(jt)
                        }
                    }
                }

                Section("Guests requested") {
                    Stepper("Adults: \(guestAdults)", value: $guestAdults, in: 0...4)
                    Stepper("Children under 17: \(guestChildren)", value: $guestChildren, in: 0...4)
                }

                Section("Verdict") {
                    LoungeAccessVerdictView(decision: decision)
                        .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                        .listRowBackground(Color.clear)
                }
            }
            .navigationTitle("Check access")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    // MARK: - Labels

    private func cabinLabel(_ cc: CabinClass) -> String {
        switch cc {
        case .F: return "First (F)"
        case .J: return "Business (J)"
        case .W: return "Premium Economy (W)"
        case .Y: return "Economy (Y)"
        }
    }

    private func tierLabel(_ t: SkywardsTier) -> String {
        switch t {
        case .Blue: return "Blue"
        case .Silver: return "Silver"
        case .Gold: return "Gold"
        case .Platinum: return "Platinum"
        case .iO: return "iO"
        }
    }

    private func carrierLabel(_ c: OperatingCarrier) -> String {
        switch c {
        case .EK: return "Emirates (EK)"
        case .FZ: return "flydubai (FZ)"
        case .QF: return "Qantas (QF)"
        case .UA: return "United (UA)"
        }
    }

    private func journeyLabel(_ jt: JourneyType) -> String {
        switch jt {
        case .originating: return "Originating"
        case .connecting: return "Connecting"
        case .arriving: return "Arriving"
        }
    }
}

// MARK: - Operating Carrier (UI helper)

/// Lightweight enum for the carrier picker. The model layer accepts a raw
/// String, so we pass `.rawValue` into the PassengerContext.
enum OperatingCarrier: String, CaseIterable, Hashable {
    case EK, FZ, QF, UA
}
