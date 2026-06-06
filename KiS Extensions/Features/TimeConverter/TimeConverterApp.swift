import SwiftUI

// MARK: - Time Converter Mini-App

struct TimeConverterApp: View {
    @State private var dxbTime = Date()
    @State private var stationCode = ""
    @State private var matchedStation: String?
    @FocusState private var stationFocused: Bool

    private static let dxbTZ = TimeZone(identifier: "Asia/Dubai")!

    private var filteredStations: [String] {
        let query = stationCode.uppercased()
        guard !query.isEmpty else { return [] }
        if query.count == 3, StationTimezones.timeZone(for: query) != nil { return [] }
        return StationTimezones.allCodes
            .filter { $0.hasPrefix(query) }
            .prefix(8)
            .map { $0 }
    }

    private var targetTZ: TimeZone? {
        let code = (matchedStation ?? stationCode).uppercased()
        guard code.count == 3 else { return nil }
        return StationTimezones.timeZone(for: code)
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    HStack(alignment: .top, spacing: 24) {
                        dxbCard
                        stationCard
                    }

                    if let tz = targetTZ {
                        resultCard(tz: tz)
                    }
                }
                .padding(24)
                .frame(maxWidth: 800)
                .frame(maxWidth: .infinity)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Time Converter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Now") {
                        dxbTime = Date()
                    }
                }
            }
        }
    }

    // MARK: - DXB Card

    private var dxbCard: some View {
        VStack(spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "building.2")
                    .font(.caption2.weight(.semibold))
                Text("DXB TIME")
                    .font(.caption2.weight(.bold))
                    .tracking(1.2)
            }
            .foregroundStyle(.orange)

            DatePicker("", selection: $dxbTime, displayedComponents: [.date, .hourAndMinute])
                .datePickerStyle(.compact)
                .labelsHidden()
                .environment(\.locale, Locale(identifier: "en_GB"))
                .environment(\.timeZone, Self.dxbTZ)

            Text(formattedDXB)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .monospacedDigit()

            Text(formattedDXBDate)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.orange.opacity(0.25), lineWidth: 1)
        )
    }

    // MARK: - Station Card

    private var stationCard: some View {
        VStack(spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "airplane")
                    .font(.caption2.weight(.semibold))
                Text("STATION")
                    .font(.caption2.weight(.bold))
                    .tracking(1.2)
            }
            .foregroundStyle(.blue)

            HStack(spacing: 0) {
                TextField("LHR", text: Binding(
                    get: { stationCode },
                    set: {
                        let cleaned = $0.uppercased().filter { $0.isLetter }
                        stationCode = String(cleaned.prefix(3))
                        if cleaned.count == 3, StationTimezones.timeZone(for: cleaned) != nil {
                            matchedStation = cleaned
                        } else {
                            matchedStation = nil
                        }
                    }
                ))
                .focused($stationFocused)
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()
                .font(.system(size: 28, weight: .bold, design: .monospaced))
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
            }
            .padding(.vertical, 8)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(stationFocused ? Color.blue : Color(.separator), lineWidth: 1)
            )

            if !filteredStations.isEmpty && stationFocused {
                stationDropdown
            }

            if let tz = targetTZ {
                let code = (matchedStation ?? stationCode).uppercased()
                if let name = StationTimezones.displayName(for: code) {
                    Text(name)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.primary)
                }
                Text(tz.abbreviation(for: dxbTime) ?? tz.identifier)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.blue.opacity(0.25), lineWidth: 1)
        )
    }

    // MARK: - Station Dropdown

    private var stationDropdown: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(filteredStations, id: \.self) { code in
                Button {
                    stationCode = code
                    matchedStation = code
                    stationFocused = false
                } label: {
                    HStack(spacing: 8) {
                        Text(code)
                            .font(.system(size: 15, weight: .medium, design: .monospaced))
                        if let name = StationTimezones.displayName(for: code) {
                            Text(name)
                                .font(.system(size: 13))
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(.systemBackground))
                }
                .buttonStyle(.plain)
                if code != filteredStations.last {
                    Divider()
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(.separator), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.1), radius: 6, y: 3)
    }

    // MARK: - Result Card

    private func resultCard(tz: TimeZone) -> some View {
        let stationDate = dxbTime
        let code = (matchedStation ?? stationCode).uppercased()
        let city = StationTimezones.displayName(for: code)

        let stationTimeStr = Self.timeFormatter(tz: tz).string(from: stationDate)
        let stationDateStr = Self.dateFormatter(tz: tz).string(from: stationDate)
        let dxbDateStr = Self.dateFormatter(tz: Self.dxbTZ).string(from: stationDate)

        let dayDiff = dayDifference(from: Self.dxbTZ, to: tz, at: stationDate)
        let offsetDiff = offsetDifference(from: Self.dxbTZ, to: tz, at: stationDate)

        return VStack(spacing: 16) {
            VStack(spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: "clock.arrow.2.circlepath")
                        .font(.caption2.weight(.semibold))
                    Text("\(code) LOCAL TIME")
                        .font(.caption2.weight(.bold))
                        .tracking(1.2)
                }
                .foregroundStyle(.green)

                if let city {
                    Text(city)
                        .font(.headline)
                        .foregroundStyle(.primary)
                }
            }

            Text(stationTimeStr)
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .monospacedDigit()

            Text(stationDateStr)
                .font(.title3.weight(.medium))
                .foregroundStyle(.secondary)

            HStack(spacing: 16) {
                infoChip(label: "UTC offset", value: offsetDiff)

                if dayDiff != 0 {
                    infoChip(
                        label: dayDiff > 0 ? "Next day" : "Previous day",
                        value: dayDiff > 0 ? "+\(dayDiff)d" : "\(dayDiff)d"
                    )
                }

                if dxbDateStr != stationDateStr {
                    infoChip(label: "DXB date", value: dxbDateStr)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.green.opacity(0.25), lineWidth: 1)
        )
    }

    // MARK: - Info Chip

    private func infoChip(label: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(label.uppercased())
                .font(.system(size: 9, weight: .semibold))
                .tracking(0.4)
                .foregroundStyle(.tertiary)
            Text(value)
                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                .monospacedDigit()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Formatters

    private var formattedDXB: String {
        Self.timeFormatter(tz: Self.dxbTZ).string(from: dxbTime)
    }

    private var formattedDXBDate: String {
        Self.dateFormatter(tz: Self.dxbTZ).string(from: dxbTime)
    }

    private static func timeFormatter(tz: TimeZone) -> DateFormatter {
        let f = DateFormatter()
        f.timeZone = tz
        f.dateFormat = "HH:mm"
        return f
    }

    private static func dateFormatter(tz: TimeZone) -> DateFormatter {
        let f = DateFormatter()
        f.timeZone = tz
        f.dateFormat = "EEEE, dd MMM yyyy"
        return f
    }

    // MARK: - Calculations

    private func dayDifference(from source: TimeZone, to target: TimeZone, at date: Date) -> Int {
        var sourceCal = Calendar(identifier: .gregorian)
        sourceCal.timeZone = source
        var targetCal = Calendar(identifier: .gregorian)
        targetCal.timeZone = target
        let sourceDay = sourceCal.startOfDay(for: date)
        let targetDay = targetCal.startOfDay(for: date)
        let diff = targetCal.dateComponents([.day], from: sourceDay, to: targetDay)
        return diff.day ?? 0
    }

    private func offsetDifference(from source: TimeZone, to target: TimeZone, at date: Date) -> String {
        let sourceOffset = source.secondsFromGMT(for: date)
        let targetOffset = target.secondsFromGMT(for: date)
        let diffSeconds = targetOffset - sourceOffset
        let hours = diffSeconds / 3600
        let minutes = abs(diffSeconds % 3600) / 60
        if minutes == 0 {
            return "\(hours >= 0 ? "+" : "")\(hours)h"
        }
        return "\(hours >= 0 ? "+" : "")\(hours)h \(minutes)m"
    }
}
