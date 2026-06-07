import SwiftUI

// MARK: - Lounges List

struct LoungesListView: View {
    @Environment(DXBDataStore.self) private var dataStore

    private var grouped: [(concourse: Concourse, lounges: [Lounge])] {
        dataStore.loungesGrouped()
    }

    private func concourseColor(_ concourse: Concourse) -> Color {
        switch concourse {
        case .A: return Color(red: 0.15, green: 0.35, blue: 0.70)
        case .B: return Color(red: 0.10, green: 0.55, blue: 0.42)
        case .C: return Color(red: 0.75, green: 0.45, blue: 0.10)
        case .D: return Color(red: 0.50, green: 0.25, blue: 0.65)   // T1 — purple
        case .F: return Color(red: 0.45, green: 0.45, blue: 0.50)   // T2 — slate
        case .G: return Color(red: 0.55, green: 0.40, blue: 0.20)   // Apron G — bronze
        case .E: return Color(red: 0.10, green: 0.45, blue: 0.55)   // Apron E — teal
        case .H: return Color(red: 0.70, green: 0.55, blue: 0.10)   // Apron H — royal gold
        case .Q: return Color(red: 0.55, green: 0.20, blue: 0.20)   // Apron Q — maintenance red
        case .S: return Color(red: 0.40, green: 0.40, blue: 0.40)   // Apron S — neutral gray
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // MARK: Summary bar
                HStack(spacing: 12) {
                    loungeStatCard(
                        count: grouped.flatMap(\.lounges).count,
                        label: "Total lounges",
                        icon: "cup.and.saucer.fill",
                        color: Color(red: 0.72, green: 0.58, blue: 0.20)
                    )
                    loungeStatCard(
                        count: grouped.flatMap(\.lounges).filter { $0.kind == .first }.count,
                        label: "First Class",
                        icon: "crown.fill",
                        color: Color(red: 0.72, green: 0.58, blue: 0.20)
                    )
                    loungeStatCard(
                        count: grouped.flatMap(\.lounges).filter { $0.kind == .business }.count,
                        label: "Business",
                        icon: "briefcase.fill",
                        color: Color(red: 0.10, green: 0.22, blue: 0.52)
                    )
                    loungeStatCard(
                        count: grouped.flatMap(\.lounges).filter { $0.directBoarding == true }.count,
                        label: "Direct boarding",
                        icon: "airplane.departure",
                        color: .green
                    )
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)

                // MARK: Concourse sections
                ForEach(grouped, id: \.concourse) { group in
                    VStack(spacing: 8) {
                        concourseHeader(group.concourse, count: group.lounges.count)
                            .padding(.horizontal, 16)

                        LazyVStack(spacing: 8) {
                            ForEach(group.lounges) { lounge in
                                NavigationLink(value: lounge) {
                                    LoungeRowView(lounge: lounge)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                }
            }
            .padding(.bottom, 24)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Lounges")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: Lounge.self) { lounge in
            LoungeDetailView(lounge: lounge)
                // Single back affordance lives in the app top bar.
                .navigationBarBackButtonHidden(true)
        }
    }

    // MARK: - Stat Card

    private func loungeStatCard(count: Int, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .semibold))
                Text("\(count)")
                    .font(.title3.weight(.bold))
            }
            .foregroundStyle(color)

            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color(.systemGray5), lineWidth: 1)
        )
    }

    // MARK: - Concourse Header

    private func concourseHeader(_ concourse: Concourse, count: Int) -> some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(concourseColor(concourse))
                .frame(width: 4, height: 22)

            Text("Concourse \(concourse.rawValue)")
                .font(.title3.weight(.bold))

            Text("\(count)")
                .font(.caption.weight(.bold))
                .foregroundStyle(concourseColor(concourse))
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(concourseColor(concourse).opacity(0.12), in: Capsule())

            Spacer()
        }
        .padding(.top, 8)
    }
}
