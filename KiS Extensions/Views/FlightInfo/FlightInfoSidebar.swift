import SwiftUI

struct FlightInfoSidebar: View {
    let trip: ParsedTrip
    let crewMembers: [CrewMember]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Flight summary
                flightSummaryCard

                // Language count
                languagesCard

                // Aircraft info
                aircraftInfoCard
            }
            .padding()
        }
        .frame(maxWidth: 350)
        .background(Color(.systemGray6).opacity(0.3))
    }

    // MARK: - Flight Summary

    private var flightSummaryCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Flight Info", systemImage: "airplane")
                .font(.subheadline.bold())

            HStack {
                Text("EK \(trip.flightInfo.flightNumber)")
                    .font(.headline)
                Spacer()
                if trip.flightInfo.isULR {
                    Text("ULR")
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.red)
                        .cornerRadius(4)
                }
            }

            Text(trip.flightInfo.flightLegs.joined(separator: " - "))
                .font(.subheadline)

            Text(trip.flightInfo.flightDate, style: .date)
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack {
                ForEach(Array(trip.flightInfo.durations.enumerated()), id: \.offset) { i, dur in
                    if i > 0 {
                        Image(systemName: "arrow.right")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    Text(String(format: "%.1fh", dur))
                        .font(.caption)
                }
            }
        }
        .padding()
        .background(.regularMaterial)
        .cornerRadius(10)
    }

    // MARK: - Languages

    private var languagesCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Languages", systemImage: "bubble.left.and.text.bubble.right")
                .font(.subheadline.bold())

            let langCounts: [String: Int] = {
                var counts: [String: Int] = [:]
                for member in crewMembers {
                    for lang in member.languages {
                        counts[lang, default: 0] += 1
                    }
                }
                return counts
            }()
            let arabicCount = langCounts["Arabic"] ?? 0
            HStack {
                Text("Arabic")
                    .font(.caption)
                    .foregroundStyle(.purple)
                Spacer()
                Text("\(arabicCount) crew")
                    .font(.caption.bold())
                    .foregroundStyle(arabicCount > 0 ? .green : .red)
            }

            let sortedLangs = langCounts.keys.sorted().filter { $0 != "Arabic" }

            if !sortedLangs.isEmpty {
                Divider()
                ForEach(sortedLangs, id: \.self) { lang in
                    let count = langCounts[lang] ?? 0
                    HStack {
                        Text(lang)
                            .font(.caption)
                        Spacer()
                        Text("\(count)")
                            .font(.caption.monospaced())
                    }
                }
            }
        }
        .padding()
        .background(.regularMaterial)
        .cornerRadius(10)
    }

    // MARK: - Aircraft Info

    private var aircraftInfoCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Aircraft", systemImage: "airplane.circle")
                .font(.subheadline.bold())

            if let reg = trip.registration {
                HStack {
                    Text("Registration")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(reg)
                        .font(.caption.monospaced().bold())
                }

                if let typeCode = FleetRegistry.fleet[reg],
                   let acType = AircraftTypes.types[typeCode] {
                    HStack {
                        Text("Type")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(acType.fullDescription)
                            .font(.caption)
                    }
                    HStack {
                        Text("CRC")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(crcDescription(acType.crc))
                            .font(.caption)
                    }
                }
            } else {
                Text("No registration available")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }

            Divider()

            let gradeCounts = Dictionary(grouping: crewMembers, by: \.grade).mapValues(\.count)
            let grades: [CrewGrade] = [.PUR, .CSV, .FG1, .GR1, .W, .GR2, .CSA]
            ForEach(grades) { grade in
                let count = gradeCounts[grade] ?? 0
                if count > 0 {
                    HStack {
                        Text(grade.rawValue)
                            .font(.caption.bold())
                        Spacer()
                        Text("\(count)")
                            .font(.caption.monospaced())
                    }
                }
            }
        }
        .padding()
        .background(.regularMaterial)
        .cornerRadius(10)
    }

    private func crcDescription(_ crc: Int) -> String {
        switch crc {
        case -1: return "No CRC"
        case 1: return "B773 CRC"
        case 2: return "LD CRC"
        case 3: return "MD CRC"
        default: return "Unknown"
        }
    }
}
