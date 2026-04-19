import SwiftUI

// MARK: - Lounge Row

struct LoungeRowView: View {
    let lounge: Lounge

    // MARK: - Kind Theming

    private var kindGradient: LinearGradient {
        switch lounge.kind {
        case .first:
            return LinearGradient(
                colors: [Color(red: 0.72, green: 0.58, blue: 0.20), Color(red: 0.55, green: 0.42, blue: 0.12)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        case .business:
            return LinearGradient(
                colors: [Color(red: 0.10, green: 0.22, blue: 0.52), Color(red: 0.06, green: 0.14, blue: 0.38)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        case .shared:
            return LinearGradient(
                colors: [Color(red: 0.10, green: 0.48, blue: 0.50), Color(red: 0.06, green: 0.35, blue: 0.38)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        case .thirdParty:
            return LinearGradient(
                colors: [Color(red: 0.38, green: 0.38, blue: 0.40), Color(red: 0.28, green: 0.28, blue: 0.30)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        }
    }

    private var kindIcon: String {
        switch lounge.kind {
        case .first: return "crown.fill"
        case .business: return "briefcase.fill"
        case .shared: return "person.2.fill"
        case .thirdParty: return "building.2.fill"
        }
    }

    private var kindLabel: String {
        switch lounge.kind {
        case .first: return "First Class"
        case .business: return "Business"
        case .shared: return "Shared"
        case .thirdParty: return "Third Party"
        }
    }

    private var operatorLabel: String {
        switch lounge.operator {
        case .emirates: return "Emirates"
        case .marhaba: return "Marhaba"
        case .ahlan: return "Ahlan"
        case .plazaPremium: return "Plaza Premium"
        }
    }

    private static let amenityIcons: [String: (icon: String, label: String)] = [
        "champagneBar": ("wineglass.fill", "Champagne"),
        "fineWine": ("wineglass.fill", "Wine"),
        "cocktailBar": ("wineglass.fill", "Cocktails"),
        "buffetDining": ("fork.knife", "Dining"),
        "alaCarteDining": ("fork.knife", "A la carte"),
        "barista": ("cup.and.saucer.fill", "Barista"),
        "showers": ("shower.fill", "Showers"),
        "quietZone": ("moon.zzz.fill", "Quiet zone"),
        "sleepPods": ("bed.double.fill", "Sleep pods"),
        "napRooms": ("bed.double.fill", "Nap rooms"),
        "spaWithTimoraSpa": ("sparkles", "Spa"),
        "spa": ("sparkles", "Spa"),
        "businessCentre": ("desktopcomputer", "Business"),
        "childrenPlayArea": ("figure.and.child.holdinghands", "Kids"),
        "gamesConsoles": ("gamecontroller.fill", "Gaming"),
        "cigarLounge": ("smoke.fill", "Cigar"),
        "freeWifi": ("wifi", "Wi-Fi"),
        "healthHub": ("heart.fill", "Health"),
        "prayerRoom": ("moon.stars.fill", "Prayer"),
    ]

    var body: some View {
        HStack(spacing: 14) {
            // MARK: Kind badge
            VStack(spacing: 4) {
                Image(systemName: kindIcon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.white)

                Text(kindLabel)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(width: 76, height: 72)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(kindGradient)
            )

            // MARK: Details
            VStack(alignment: .leading, spacing: 6) {
                Text(lounge.name)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                HStack(spacing: 8) {
                    Label(operatorLabel, systemImage: "building.2")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.secondary)

                    if let gate = lounge.nearestGate {
                        Label("Gate \(gate)", systemImage: "mappin")
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(.secondary)
                    }
                }

                HStack(spacing: 5) {
                    Label {
                        Text(lounge.openingHours)
                            .lineLimit(1)
                    } icon: {
                        Image(systemName: "clock")
                    }
                    .font(.caption2)
                    .foregroundStyle(.tertiary)

                    if lounge.directBoarding == true {
                        HStack(spacing: 2) {
                            Image(systemName: "airplane.departure")
                                .font(.system(size: 9))
                            Text("Direct")
                                .font(.caption2.weight(.semibold))
                        }
                        .foregroundStyle(.green)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.green.opacity(0.12), in: Capsule())
                    }
                }

                if !lounge.amenities.isEmpty {
                    amenityRow
                }
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.quaternary)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color(.systemGray5), lineWidth: 1)
        )
    }

    // MARK: - Amenity Row

    private var amenityRow: some View {
        HStack(spacing: 4) {
            ForEach(lounge.amenities.prefix(6), id: \.self) { amenity in
                if let entry = Self.amenityIcons[amenity] {
                    Image(systemName: entry.icon)
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                        .frame(width: 20, height: 20)
                        .background(Color(.systemGray5), in: RoundedRectangle(cornerRadius: 5, style: .continuous))
                        .help(entry.label)
                }
            }

            let remaining = lounge.amenities.count - min(lounge.amenities.count, 6)
            if remaining > 0 {
                Text("+\(remaining)")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.tertiary)
                    .frame(width: 20, height: 20)
                    .background(Color(.systemGray5), in: RoundedRectangle(cornerRadius: 5, style: .continuous))
            }
        }
    }
}
