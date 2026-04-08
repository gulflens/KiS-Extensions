import SwiftUI
import SwiftData

struct MainAppView: View {
    @Environment(AppState.self) private var appState
    @Query private var settingsArray: [AppSettings]
    @State private var sidebarExpanded = false

    private var settings: AppSettings {
        settingsArray.first ?? AppSettings()
    }

    private var colorScheme: ColorScheme? {
        switch settings.appearanceMode {
        case .light: return .light
        case .dark: return .dark
        case .system: return nil
        }
    }

    var body: some View {
        @Bindable var appState = appState

        HStack(spacing: 0) {
            // MARK: - Compact Sidebar
            CompactSidebarView(
                selectedSection: $appState.selectedSection,
                expanded: $sidebarExpanded
            )

            Divider()

            // MARK: - Detail area
            VStack(spacing: 0) {
                NavigationStack(path: $appState.navigationPath) {
                    detailContent
                        .navigationDestination(for: NavigationDestination.self) { destination in
                            switch destination {
                            case .tripsList:
                                TripsListView()
                            case .crewTable(let tripIndex, let doPositions):
                                if tripIndex < appState.parsedTrips.count {
                                    CrewTableView(trip: appState.parsedTrips[tripIndex], doPositions: doPositions)
                                }
                            }
                        }
                }
            }
            .frame(maxWidth: .infinity)
        }
        .preferredColorScheme(colorScheme)
        .onChange(of: appState.selectedSection) { _, _ in
            appState.navigationPath = NavigationPath()
        }
    }

    @ViewBuilder
    private var detailContent: some View {
        switch appState.selectedSection {
        case .crewPositions:
            DashboardView()
        case .timeline:
            TimelinePlaceholderView()
        case .kisReports:
            ReportWriterRootView()
        case .settings:
            SettingsView()
        }
    }
}

// MARK: - Compact Sidebar

struct CompactSidebarView: View {
    @Binding var selectedSection: SidebarSection
    @Binding var expanded: Bool

    private let compactWidth: CGFloat = 56
    private let expandedWidth: CGFloat = 200

    var body: some View {
        VStack(spacing: 0) {
            // Expand/collapse toggle
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    expanded.toggle()
                }
            } label: {
                Image(systemName: expanded ? "sidebar.left" : "sidebar.left")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.secondary)
                    .frame(width: compactWidth, height: 44)
            }
            .buttonStyle(.plain)

            Divider()
                .padding(.horizontal, 8)

            // Feature sections
            VStack(spacing: 4) {
                ForEach(SidebarSection.featureSections) { section in
                    sidebarItem(for: section)
                }
            }
            .padding(.top, 8)

            Spacer()

            // Settings at the bottom
            Divider()
                .padding(.horizontal, 8)

            sidebarItem(for: .settings)
                .padding(.vertical, 8)
        }
        .frame(width: expanded ? expandedWidth : compactWidth)
        .background(Color(.systemGray6))
    }

    private func sidebarItem(for section: SidebarSection) -> some View {
        let isSelected = selectedSection == section

        return Button {
            selectedSection = section
        } label: {
            HStack(spacing: 10) {
                Image(systemName: section.icon)
                    .font(.system(size: 18, weight: isSelected ? .semibold : .regular))
                    .frame(width: 24)

                if expanded {
                    Text(section.rawValue)
                        .font(.subheadline.weight(isSelected ? .semibold : .regular))
                        .lineLimit(1)

                    Spacer()
                }
            }
            .foregroundStyle(isSelected ? Color.accentColor : .primary)
            .padding(.horizontal, expanded ? 14 : 0)
            .frame(width: expanded ? expandedWidth - 16 : 44, height: 40)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(isSelected ? Color.accentColor.opacity(0.12) : Color.clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .frame(width: expanded ? nil : compactWidth)
    }
}

