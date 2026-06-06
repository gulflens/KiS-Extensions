import SwiftUI

// MARK: - EK Crew Rest Mini-App

/// Service and rest schedule calculator for Emirates cabin crew.
/// Self-contained mini-app — owns its own NavigationStack and a private state container.
/// The Onboard Crew Rest Strategies v18.1 helper is reachable via a toolbar shield icon.
struct EKCrewRestApp: View {
    @Environment(AppState.self) private var appState
    @State private var crewRestState = CrewRestState.restored()
    @State private var showHelper = false

    enum Route: Hashable { case results }

    var body: some View {
        @Bindable var appState = appState

        NavigationStack(path: $appState.ekCrewRestPath) {
            inputContent
                .navigationDestination(for: Route.self) { route in
                    switch route {
                    case .results:
                        CrewRestResultsView()
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showHelper = true
                        } label: {
                            Image(systemName: "checkmark.shield")
                                .font(.system(size: 16, weight: .medium))
                        }
                        .accessibilityLabel("Crew Rest Helper")
                    }
                }
        }
        .environment(crewRestState)
        .sheet(isPresented: $showHelper) {
            CrewRestHelperSheet()
                .environment(crewRestState)
                .presentationSizing(.page)
        }
    }

    // MARK: - Input content with persistence

    private var inputContent: some View {
        CrewRestInputView(onCalculate: {
            crewRestState.result = Calculator.calc(crewRestState)
            appState.ekCrewRestPath.append(Route.results)
        })
        .onChange(of: crewRestState.takeoffMin) { crewRestState.save() }
        .onChange(of: crewRestState.flightMin) { crewRestState.save() }
        .onChange(of: crewRestState.registration) { crewRestState.save() }
        .onChange(of: crewRestState.aircraft) { crewRestState.save() }
        .onChange(of: crewRestState.hasFC) { crewRestState.save() }
        .onChange(of: crewRestState.facility) { crewRestState.save() }
        .onChange(of: crewRestState.settlingMin) { crewRestState.save() }
        .onChange(of: crewRestState.numServices) { crewRestState.save() }
        .onChange(of: crewRestState.services) { crewRestState.save() }
        .onChange(of: crewRestState.mdCrcSequence) { crewRestState.save() }
        .onChange(of: crewRestState.breakStartOverride) { crewRestState.save() }
        .onChange(of: crewRestState.breakStartMin) { crewRestState.save() }
        .onChange(of: crewRestState.fcAllowOverlap) { crewRestState.save() }
        .onChange(of: crewRestState.fcStartAfterTO) { crewRestState.save() }
        .onChange(of: crewRestState.fcEndBuffer) { crewRestState.save() }
    }
}
