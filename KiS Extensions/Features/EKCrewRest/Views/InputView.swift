import SwiftUI

// MARK: - Crew Rest Input View

/// Calculator input screen — direct port of the demo HTML's iPhone input screen.
/// Card layout matches the source 1:1: Flight, Aircraft, Settling-in, Services.
struct CrewRestInputView: View {
    @Environment(CrewRestState.self) private var state
    let onCalculate: () -> Void

    var body: some View {
        @Bindable var state = state

        VStack(spacing: 0) {
        ScrollView {
            VStack(spacing: 12) {
                HStack(alignment: .top, spacing: 14) {

                    // MARK: - Left Column (Flight + Aircraft + Settling-in)
                    VStack(spacing: 12) {
                        Card(title: "Flight") {
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Take off").font(.system(size: 13, weight: .medium)).foregroundStyle(.primary)
                                    TakeoffField(minutesSinceMidnight: $state.takeoffMin)
                                }
                                Spacer()
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Flight time").font(.system(size: 13, weight: .medium)).foregroundStyle(.primary)
                                    DurationField(totalMin: $state.flightMin)
                                }
                            }
                        }

                        Card(title: "Aircraft") {
                            VStack(spacing: 8) {
                                LabeledRow(label: "Registration", trailing: { RegistrationField(text: $state.registration) }, hasTopBorder: false)
                                    .onChange(of: state.registration) {
                                        guard let fleet = state.matchedFleet else { return }
                                        state.aircraft = fleet.type
                                        let options = fleet.facilityOptions
                                        if let best = options.first {
                                            state.facility = best
                                        }
                                        state.hasFC = state.fcAvailable
                                    }

                                if let fleet = state.matchedFleet {
                                    Text(fleet.aircraftLabel)
                                        .font(.system(size: 13))
                                        .foregroundStyle(CRTheme.ekRed)
                                }

                                Seg(options: ["B777", "A350", "A380"], label: { $0 }, selection: $state.aircraft)
                                    .onChange(of: state.aircraft) {
                                        let available = Facility.options(for: state.aircraft)
                                        if !available.contains(state.facility) {
                                            state.facility = available.first ?? .crc
                                        }
                                        state.hasFC = state.fcAvailable
                                    }

                                VStack(alignment: .leading, spacing: 8) {
                                    Text("REST FACILITY").font(.system(size: 13, weight: .semibold)).tracking(0.7).foregroundStyle(.primary.opacity(0.7))
                                        .padding(.top, 4)
                                    Seg(
                                        options: Facility.options(for: state.aircraft),
                                        label: \.label,
                                        selection: $state.facility
                                    )
                                }
                                .onChange(of: state.facility) {
                                    state.hasFC = state.fcAvailable
                                }

                                if state.fcAvailable {
                                    LabeledRow(label: "First class cabin", trailing: { Toggle("", isOn: $state.hasFC).labelsHidden().tint(CRTheme.ekRed) })
                                }

                                LabeledRow(label: "Rest groups", trailing: {
                                    Text("\(state.facility.numBreaks) break\(state.facility.numBreaks == 1 ? "" : "s")")
                                        .font(.system(size: 16, weight: .medium, design: .monospaced))
                                })
                            }
                        }

                        Card(title: "Settling-in duties") {
                            VStack(spacing: 10) {
                                SliderRow(label: "Duration", value: $state.settlingMin,
                                          range: 10...30, step: 5,
                                          display: { TimeFormatter.dur($0) })
                                LabeledRow(label: "Period", trailing: {
                                    let start = state.takeoffMin + 10
                                    let end = start + state.settlingMin
                                    Text("\(TimeFormatter.clock(start)) — \(TimeFormatter.clock(end))")
                                        .font(.system(size: 16, design: .monospaced))
                                        .foregroundStyle(.primary)
                                })
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)

                    // MARK: - Right Column (Services + FC)
                    VStack(spacing: 12) {
                        Card(title: "Services") {
                            VStack(spacing: 12) {
                                Seg(options: [1, 2, 3], label: { "\($0) svc" }, selection: $state.numServices)

                                ForEach(0..<state.numServices, id: \.self) { idx in
                                    SliderRow(
                                        label: "Service \(idx + 1)",
                                        value: Binding(
                                            get: { state.services[idx] },
                                            set: { state.services[idx] = $0 }
                                        ),
                                        range: 30...180, step: 5,
                                        display: { TimeFormatter.dur($0) }
                                    )
                                }

                                if state.facility == .mdCrc && state.numServices == 3 {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("SEQUENCE").font(.system(size: 13, weight: .semibold)).tracking(0.7).foregroundStyle(.primary.opacity(0.7))
                                        Seg(options: MDCrcSequence.allCases, label: \.label, selection: $state.mdCrcSequence)
                                    }
                                }
                            }
                        }

                        Card(title: "Breaks") {
                            VStack(spacing: 10) {
                                LabeledRow(label: "Override start time", trailing: {
                                    Toggle("", isOn: $state.breakStartOverride).labelsHidden().tint(CRTheme.ekRed)
                                }, hasTopBorder: false)

                                if state.breakStartOverride {
                                    LabeledRow(label: "Start time", trailing: {
                                        TakeoffField(minutesSinceMidnight: $state.breakStartMin)
                                    })
                                }
                            }
                        }

                        if state.fcAvailable && state.hasFC {
                            Card(title: "First class (dine on demand)") {
                                VStack(spacing: 10) {
                                    LabeledRow(label: "Allow overlap", trailing: {
                                        Toggle("", isOn: $state.fcAllowOverlap).labelsHidden().tint(CRTheme.ekRed)
                                    }, hasTopBorder: false)

                                    SliderRow(label: "Start after TO", value: $state.fcStartAfterTO,
                                              range: 30...120, step: 5, display: { TimeFormatter.dur($0) })

                                    SliderRow(label: "End before LDG", value: $state.fcEndBuffer,
                                              range: 60...120, step: 5, display: { TimeFormatter.dur($0) })
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(14)
            }
            .frame(maxWidth: .infinity)
        }

        // MARK: - Calculate Button (pinned to bottom)
        Button(action: onCalculate) {
            Text("Calculate")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(CRTheme.ekRed)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color(uiColor: .systemGroupedBackground))
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(CRTheme.ekRed, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack {
                    Text("Service & rest")
                        .font(.system(size: 17, weight: .semibold))
                    Spacer(minLength: 20)
                    Text(state.headerSummary)
                        .font(.system(size: 13, design: .monospaced))
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(Color.white.opacity(0.18))
                        .clipShape(RoundedRectangle(cornerRadius: 5))
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
}
