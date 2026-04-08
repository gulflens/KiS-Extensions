import Foundation

struct CrewLoader {
    /// Converts raw CrewDTO array into domain CrewMember array
    static func loadCrew(from inputData: [CrewDTO]) -> [CrewMember] {
        var crewData: [CrewMember] = []

        for (index, crew) in inputData.enumerated() {
            var badges: [Int] = []
            var languages: [String] = []
            var ratingIR = 21

            // Parse Profile string: "CODE1 - Description, CODE2 - Description, ..."
            let profileString = crew.Profile ?? ""
            if !profileString.isEmpty {
                let profileParts = profileString.split(separator: ",")
                for badge in profileParts {
                    let trimmed = badge.trimmingCharacters(in: .whitespaces)
                    let code = String(trimmed.split(separator: " - ", maxSplits: 1).first ?? Substring(trimmed))
                        .trimmingCharacters(in: .whitespaces)

                    if let langName = QualificationsData.languages[code] {
                        languages.append(langName)
                    } else if let dfRating = QualificationsData.dfRatings[code] {
                        ratingIR = dfRating
                    } else if QualificationsData.important[code] != nil {
                        if let codeInt = Int(code) {
                            badges.append(codeInt)
                        }
                    }
                }
            }

            let opGrade = crew.OperationGrade ?? "GR2"
            let hrGrade = crew.HRGrade ?? opGrade
            let grade = CrewGrade(rawValue: opGrade) ?? .GR2
            let outOfGrade = opGrade != hrGrade

            // Parse destination experiences (exclude DXB)
            var destExp: [String: Int] = [:]
            if let experiences = crew.destinationExperiences {
                for exp in experiences {
                    guard let dest = exp.Destination, dest != "DXB" else { continue }
                    destExp[dest] = exp.VisitedCount ?? 0
                }
            }

            let birthday = parseDateString(crew.DOB ?? "")
            let gradeExp = crew.GradeExp ?? "0 Years 0 Months"
            let firstName = crew.FirstName ?? "Unknown"
            let lastName = crew.LastName ?? ""
            let staffID = crew.StaffID ?? "\(index)"
            let natCode = crew.NationalityCode ?? ""

            let lastPosition: [String] = {
                switch grade {
                case .PUR, .CSA: return []
                case .GR1, .FG1, .CSV: return [""]
                default: return ["", ""]
                }
            }()

            let comment: String = {
                guard let status = crew.SocialStatus, !status.isEmpty else { return "" }
                return status
                    .replacingOccurrences(of: "'", with: "&apos;")
                    .replacingOccurrences(of: "\"", with: "&quot;")
            }()

            let nationality = cleanNationality(crew.Nationality ?? "")

            let nickname: String = {
                if let nick = crew.NickName, !nick.isEmpty {
                    return nick
                }
                return String(firstName.split(separator: " ").first ?? Substring(firstName))
            }()

            let member = CrewMember(
                id: staffID,
                index: index + grade.indexModifier,
                ratingIR: ratingIR,
                languages: languages,
                badges: badges,
                grade: grade,
                originalGrade: grade == .W ? .GR2 : grade,
                outOfGrade: outOfGrade,
                flag: alpha2(from: natCode),
                timeInGrade: gradeExp,
                timeInGradeMonths: outOfGrade ? 0 : parseTimeInGrade(gradeExp),
                birthday: birthday,
                lastPosition: lastPosition,
                comment: comment,
                staffNumber: staffID,
                fullname: "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces),
                nickname: nickname,
                destinationExperience: destExp,
                nationality: nationality
            )

            crewData.append(member)
        }

        return crewData
    }

    private static func parseTimeInGrade(_ string: String) -> Int {
        let elements = string
            .replacingOccurrences(of: ",", with: "")
            .split(separator: " ")
        guard elements.count >= 3 else { return 0 }
        let years = Int(elements[0]) ?? 0
        let months = Int(elements[2]) ?? 0
        return months + (years * 12)
    }

    private static func parseDateString(_ string: String) -> Date {
        if string.isEmpty { return Date.distantPast }

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = formatter.date(from: string) { return d }
        formatter.formatOptions = [.withInternetDateTime]
        if let d = formatter.date(from: string) { return d }

        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        for format in ["yyyy-MM-dd'T'HH:mm:ss", "yyyy-MM-dd", "MM/dd/yyyy", "dd/MM/yyyy"] {
            df.dateFormat = format
            if let d = df.date(from: string) { return d }
        }
        return Date.distantPast
    }

    private static func cleanNationality(_ name: String) -> String {
        let replacements: [(String, String)] = [
            ("Korea, Republic Of", "Korea"),
            ("Moldova, Republic Of", "Moldova"),
            ("Czech Republic", "Czech"),
            ("Taiwan, Province Of China", "Taiwan"),
            ("United Arab Emirates", "UAE"),
            ("Russian Federation", "Russia"),
            ("Bosnia And Herzegovina", "Bosnia"),
            ("Republic Of Macedonia", "Macedonia"),
            ("Syrian Arab Republic", "Syria"),
            ("Brunei Darussalam", "Brunei"),
        ]
        var result = name
        for (old, new) in replacements {
            result = result.replacingOccurrences(of: old, with: new)
        }
        return result
    }

    /// Convert ISO 3166-1 alpha-3 (or alpha-2) nationality code to alpha-2 for flag emoji.
    private static func alpha2(from code: String) -> String {
        let upper = code.uppercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !upper.isEmpty else { return "" }
        if upper.count == 2 { return upper }
        if let mapped = iso3toIso2[upper] { return mapped }
        // Try the system Locale as a last resort
        if upper.count == 3 {
            for localeID in Locale.availableIdentifiers {
                let components = Locale.Components(identifier: localeID)
                if let region = components.region?.identifier, region.count == 2 {
                    // Can't easily reverse-map, so fall through
                }
            }
        }
        print("⚠️ CrewLoader: unmapped nationality code '\(upper)'")
        return upper
    }

    private static let iso3toIso2: [String: String] = {
        // iOS Locale provides alpha-2 region codes; map alpha-3 ↔ alpha-2
        var map: [String: String] = [
            "AFG": "AF", "ALB": "AL", "DZA": "DZ", "ASM": "AS", "AND": "AD",
            "AGO": "AO", "ATG": "AG", "ARG": "AR", "ARM": "AM", "AUS": "AU",
            "AUT": "AT", "AZE": "AZ", "BHS": "BS", "BHR": "BH", "BGD": "BD",
            "BRB": "BB", "BLR": "BY", "BEL": "BE", "BLZ": "BZ", "BEN": "BJ",
            "BTN": "BT", "BOL": "BO", "BIH": "BA", "BWA": "BW", "BRA": "BR",
            "BRN": "BN", "BGR": "BG", "BFA": "BF", "BDI": "BI", "CPV": "CV",
            "KHM": "KH", "CMR": "CM", "CAN": "CA", "CAF": "CF", "TCD": "TD",
            "CHL": "CL", "CHN": "CN", "COL": "CO", "COM": "KM", "COG": "CG",
            "COD": "CD", "CRI": "CR", "CIV": "CI", "HRV": "HR", "CUB": "CU",
            "CYP": "CY", "CZE": "CZ", "DNK": "DK", "DJI": "DJ", "DMA": "DM",
            "DOM": "DO", "ECU": "EC", "EGY": "EG", "SLV": "SV", "GNQ": "GQ",
            "ERI": "ER", "EST": "EE", "SWZ": "SZ", "ETH": "ET", "FJI": "FJ",
            "FIN": "FI", "FRA": "FR", "GAB": "GA", "GMB": "GM", "GEO": "GE",
            "DEU": "DE", "GHA": "GH", "GRC": "GR", "GRD": "GD", "GTM": "GT",
            "GIN": "GN", "GNB": "GW", "GUY": "GY", "HTI": "HT", "HND": "HN",
            "HUN": "HU", "ISL": "IS", "IND": "IN", "IDN": "ID", "IRN": "IR",
            "IRQ": "IQ", "IRL": "IE", "ISR": "IL", "ITA": "IT", "JAM": "JM",
            "JPN": "JP", "JOR": "JO", "KAZ": "KZ", "KEN": "KE", "KIR": "KI",
            "PRK": "KP", "KOR": "KR", "KWT": "KW", "KGZ": "KG", "LAO": "LA",
            "LVA": "LV", "LBN": "LB", "LSO": "LS", "LBR": "LR", "LBY": "LY",
            "LIE": "LI", "LTU": "LT", "LUX": "LU", "MDG": "MG", "MWI": "MW",
            "MYS": "MY", "MDV": "MV", "MLI": "ML", "MLT": "MT", "MHL": "MH",
            "MRT": "MR", "MUS": "MU", "MEX": "MX", "FSM": "FM", "MDA": "MD",
            "MCO": "MC", "MNG": "MN", "MNE": "ME", "MAR": "MA", "MOZ": "MZ",
            "MMR": "MM", "NAM": "NA", "NRU": "NR", "NPL": "NP", "NLD": "NL",
            "NZL": "NZ", "NIC": "NI", "NER": "NE", "NGA": "NG", "MKD": "MK",
            "NOR": "NO", "OMN": "OM", "PAK": "PK", "PLW": "PW", "PAN": "PA",
            "PNG": "PG", "PRY": "PY", "PER": "PE", "PHL": "PH", "POL": "PL",
            "PRT": "PT", "QAT": "QA", "ROU": "RO", "RUS": "RU", "RWA": "RW",
            "KNA": "KN", "LCA": "LC", "VCT": "VC", "WSM": "WS", "SMR": "SM",
            "STP": "ST", "SAU": "SA", "SEN": "SN", "SRB": "RS", "SYC": "SC",
            "SLE": "SL", "SGP": "SG", "SVK": "SK", "SVN": "SI", "SLB": "SB",
            "SOM": "SO", "ZAF": "ZA", "SSD": "SS", "ESP": "ES", "LKA": "LK",
            "SDN": "SD", "SUR": "SR", "SWE": "SE", "CHE": "CH", "SYR": "SY",
            "TWN": "TW", "TJK": "TJ", "TZA": "TZ", "THA": "TH", "TLS": "TL",
            "TGO": "TG", "TON": "TO", "TTO": "TT", "TUN": "TN", "TUR": "TR",
            "TKM": "TM", "TUV": "TV", "UGA": "UG", "UKR": "UA", "ARE": "AE",
            "GBR": "GB", "USA": "US", "URY": "UY", "UZB": "UZ", "VUT": "VU",
            "VEN": "VE", "VNM": "VN", "YEM": "YE", "ZMB": "ZM", "ZWE": "ZW",
            "PSE": "PS", "HKG": "HK", "MAC": "MO", "XKX": "XK",
        ]
        return map
    }()

    static func checkBirthdays(_ crewData: inout [CrewMember], flightDate: Date, durations: [Double]) {
        let calendar = Calendar.current
        // Total flight duration in hours — covers the entire trip
        let totalHours = durations.reduce(0, +)
        // Flight ends after totalHours; the crew is on duty for this entire window
        let flightEnd = flightDate.addingTimeInterval(totalHours * 3600)

        // Collect all calendar dates the trip spans (day-of-month + month)
        var tripDays: [(month: Int, day: Int)] = []
        var current = calendar.startOfDay(for: flightDate)
        let endDay = calendar.startOfDay(for: flightEnd)
        while current <= endDay {
            tripDays.append((
                month: calendar.component(.month, from: current),
                day: calendar.component(.day, from: current)
            ))
            guard let next = calendar.date(byAdding: .day, value: 1, to: current) else { break }
            current = next
        }

        for i in crewData.indices {
            let bMonth = calendar.component(.month, from: crewData[i].birthday)
            let bDay = calendar.component(.day, from: crewData[i].birthday)

            let isBirthday = tripDays.contains { $0.month == bMonth && $0.day == bDay }

            if isBirthday && !crewData[i].badges.contains(1) {
                crewData[i].badges.append(1)
            }
        }
    }
}
