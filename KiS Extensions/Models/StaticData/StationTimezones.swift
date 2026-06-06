import Foundation

// MARK: - Station Timezones

/// Maps IATA station codes across the Emirates network (passenger, SkyCargo and
/// technical stations) to their served city, country and IANA timezone.
/// The timezone drives cross-timezone flight-time calculations; the city and
/// country drive the destination picker, dashboard clocks and time converter.
///
/// City names are stored explicitly per code rather than derived from the
/// timezone identifier, so distinct airports sharing one zone read correctly
/// (e.g. DFW is "Dallas", not "Chicago", even though both use America/Chicago).
enum StationTimezones {

    // MARK: - Public API

    static func timeZone(for iataCode: String) -> TimeZone? {
        guard let station = stations[iataCode.uppercased()] else { return nil }
        return TimeZone(identifier: station.timeZone)
    }

    static var allCodes: [String] {
        stations.keys.sorted()
    }

    /// Short city name for a code, e.g. "Dallas". Nil for unknown codes.
    static func cityName(for iataCode: String) -> String? {
        stations[iataCode.uppercased()]?.city
    }

    /// Country name for a code, e.g. "United States". Nil for unknown codes.
    static func countryName(for iataCode: String) -> String? {
        stations[iataCode.uppercased()]?.country
    }

    /// City with country, e.g. "Dallas, United States". Nil for unknown codes.
    /// Used where there is room to disambiguate same-named cities.
    static func displayName(for iataCode: String) -> String? {
        guard let s = stations[iataCode.uppercased()] else { return nil }
        return "\(s.city), \(s.country)"
    }

    // MARK: - Station Model

    private struct Station {
        let city: String
        let country: String
        let timeZone: String
    }

    // MARK: - IATA → Station (Emirates network)

    private static let stations: [String: Station] = [
        "AAN": Station(city: "Al Ain", country: "United Arab Emirates", timeZone: "Asia/Dubai"),
        "ABJ": Station(city: "Abidjan", country: "Ivory Coast", timeZone: "Africa/Abidjan"),
        "ACC": Station(city: "Accra", country: "Ghana", timeZone: "Africa/Accra"),
        "ADD": Station(city: "Addis Ababa", country: "Ethiopia", timeZone: "Africa/Addis_Ababa"),
        "ADL": Station(city: "Adelaide", country: "Australia", timeZone: "Australia/Adelaide"),
        "AKL": Station(city: "Auckland", country: "New Zealand", timeZone: "Pacific/Auckland"),
        "ALA": Station(city: "Almaty", country: "Kazakhstan", timeZone: "Asia/Almaty"),
        "ALG": Station(city: "Algiers", country: "Algeria", timeZone: "Africa/Algiers"),
        "AMD": Station(city: "Ahmedabad", country: "India", timeZone: "Asia/Kolkata"),
        "AMM": Station(city: "Amman", country: "Jordan", timeZone: "Asia/Amman"),
        "AMS": Station(city: "Amsterdam", country: "Netherlands", timeZone: "Europe/Amsterdam"),
        "ANC": Station(city: "Anchorage", country: "United States", timeZone: "America/Anchorage"),
        "ARN": Station(city: "Stockholm", country: "Sweden", timeZone: "Europe/Stockholm"),
        "ATH": Station(city: "Athens", country: "Greece", timeZone: "Europe/Athens"),
        "AUH": Station(city: "Abu Dhabi", country: "United Arab Emirates", timeZone: "Asia/Dubai"),
        "AVV": Station(city: "Melbourne", country: "Australia", timeZone: "Australia/Melbourne"),
        "AZI": Station(city: "Abu Dhabi", country: "United Arab Emirates", timeZone: "Asia/Dubai"),
        "BAH": Station(city: "Manama", country: "Bahrain", timeZone: "Asia/Bahrain"),
        "BCN": Station(city: "Barcelona", country: "Spain", timeZone: "Europe/Madrid"),
        "BER": Station(city: "Berlin", country: "Germany", timeZone: "Europe/Berlin"),
        "BEY": Station(city: "Beirut", country: "Lebanon", timeZone: "Asia/Beirut"),
        "BGW": Station(city: "Baghdad", country: "Iraq", timeZone: "Asia/Baghdad"),
        "BHX": Station(city: "Birmingham", country: "United Kingdom", timeZone: "Europe/London"),
        "BKK": Station(city: "Bangkok", country: "Thailand", timeZone: "Asia/Bangkok"),
        "BLQ": Station(city: "Bologna", country: "Italy", timeZone: "Europe/Rome"),
        "BLR": Station(city: "Bangalore", country: "India", timeZone: "Asia/Kolkata"),
        "BNE": Station(city: "Brisbane", country: "Australia", timeZone: "Australia/Brisbane"),
        "BOG": Station(city: "Bogota", country: "Colombia", timeZone: "America/Bogota"),
        "BOM": Station(city: "Mumbai", country: "India", timeZone: "Asia/Kolkata"),
        "BOS": Station(city: "Boston", country: "United States", timeZone: "America/New_York"),
        "BQN": Station(city: "Aguadilla", country: "Puerto Rico", timeZone: "America/Puerto_Rico"),
        "BRU": Station(city: "Brussels", country: "Belgium", timeZone: "Europe/Brussels"),
        "BSR": Station(city: "Basra", country: "Iraq", timeZone: "Asia/Baghdad"),
        "BUD": Station(city: "Budapest", country: "Hungary", timeZone: "Europe/Budapest"),
        "CAI": Station(city: "Cairo", country: "Egypt", timeZone: "Africa/Cairo"),
        "CAN": Station(city: "Guangzhou", country: "China", timeZone: "Asia/Shanghai"),
        "CCU": Station(city: "Kolkata", country: "India", timeZone: "Asia/Kolkata"),
        "CDG": Station(city: "Paris", country: "France", timeZone: "Europe/Paris"),
        "CEB": Station(city: "Cebu", country: "Philippines", timeZone: "Asia/Manila"),
        "CGK": Station(city: "Jakarta", country: "Indonesia", timeZone: "Asia/Jakarta"),
        "CGO": Station(city: "Zhengzhou", country: "China", timeZone: "Asia/Shanghai"),
        "CHC": Station(city: "Christchurch", country: "New Zealand", timeZone: "Pacific/Auckland"),
        "CKY": Station(city: "Conakry", country: "Guinea", timeZone: "Africa/Conakry"),
        "CLO": Station(city: "Cali", country: "Colombia", timeZone: "America/Bogota"),
        "CMB": Station(city: "Colombo", country: "Sri Lanka", timeZone: "Asia/Colombo"),
        "CMN": Station(city: "Casablanca", country: "Morocco", timeZone: "Africa/Casablanca"),
        "COK": Station(city: "Kochi", country: "India", timeZone: "Asia/Kolkata"),
        "CPH": Station(city: "Copenhagen", country: "Denmark", timeZone: "Europe/Copenhagen"),
        "CPT": Station(city: "Cape Town", country: "South Africa", timeZone: "Africa/Johannesburg"),
        "CRK": Station(city: "Clark", country: "Philippines", timeZone: "Asia/Manila"),
        "CTU": Station(city: "Chengdu", country: "China", timeZone: "Asia/Shanghai"),
        "DAC": Station(city: "Dhaka", country: "Bangladesh", timeZone: "Asia/Dhaka"),
        "DAD": Station(city: "Da Nang", country: "Vietnam", timeZone: "Asia/Ho_Chi_Minh"),
        "DAR": Station(city: "Dar es Salaam", country: "Tanzania", timeZone: "Africa/Dar_es_Salaam"),
        "DEL": Station(city: "Delhi", country: "India", timeZone: "Asia/Kolkata"),
        "DFW": Station(city: "Dallas", country: "United States", timeZone: "America/Chicago"),
        "DME": Station(city: "Moscow", country: "Russia", timeZone: "Europe/Moscow"),
        "DMM": Station(city: "Dammam", country: "Saudi Arabia", timeZone: "Asia/Riyadh"),
        "DOH": Station(city: "Doha", country: "Qatar", timeZone: "Asia/Qatar"),
        "DPS": Station(city: "Denpasar", country: "Indonesia", timeZone: "Asia/Makassar"),
        "DSS": Station(city: "Dakar", country: "Senegal", timeZone: "Africa/Dakar"),
        "DTW": Station(city: "Detroit", country: "United States", timeZone: "America/Detroit"),
        "DUB": Station(city: "Dublin", country: "Ireland", timeZone: "Europe/Dublin"),
        "DUR": Station(city: "Durban", country: "South Africa", timeZone: "Africa/Johannesburg"),
        "DUS": Station(city: "Dusseldorf", country: "Germany", timeZone: "Europe/Berlin"),
        "DWC": Station(city: "Dubai", country: "United Arab Emirates", timeZone: "Asia/Dubai"),
        "DXB": Station(city: "Dubai", country: "United Arab Emirates", timeZone: "Asia/Dubai"),
        "EBB": Station(city: "Entebbe", country: "Uganda", timeZone: "Africa/Kampala"),
        "EBL": Station(city: "Erbil", country: "Iraq", timeZone: "Asia/Baghdad"),
        "EDI": Station(city: "Edinburgh", country: "United Kingdom", timeZone: "Europe/London"),
        "EWR": Station(city: "Newark", country: "United States", timeZone: "America/New_York"),
        "EZE": Station(city: "Buenos Aires", country: "Argentina", timeZone: "America/Argentina/Buenos_Aires"),
        "FCO": Station(city: "Rome", country: "Italy", timeZone: "Europe/Rome"),
        "FRA": Station(city: "Frankfurt", country: "Germany", timeZone: "Europe/Berlin"),
        "GIG": Station(city: "Rio de Janeiro", country: "Brazil", timeZone: "America/Sao_Paulo"),
        "GLA": Station(city: "Glasgow", country: "United Kingdom", timeZone: "Europe/London"),
        "GMT": Station(city: "Greenwich Mean Time", country: "Worldwide", timeZone: "GMT"),
        "GRU": Station(city: "Sao Paulo", country: "Brazil", timeZone: "America/Sao_Paulo"),
        "GVA": Station(city: "Geneva", country: "Switzerland", timeZone: "Europe/Zurich"),
        "HAM": Station(city: "Hamburg", country: "Germany", timeZone: "Europe/Berlin"),
        "HAN": Station(city: "Hanoi", country: "Vietnam", timeZone: "Asia/Ho_Chi_Minh"),
        "HGH": Station(city: "Hangzhou", country: "China", timeZone: "Asia/Shanghai"),
        "HKG": Station(city: "Hong Kong", country: "Hong Kong", timeZone: "Asia/Hong_Kong"),
        "HKT": Station(city: "Phuket", country: "Thailand", timeZone: "Asia/Bangkok"),
        "HND": Station(city: "Tokyo", country: "Japan", timeZone: "Asia/Tokyo"),
        "HPH": Station(city: "Hai Phong", country: "Vietnam", timeZone: "Asia/Ho_Chi_Minh"),
        "HRE": Station(city: "Harare", country: "Zimbabwe", timeZone: "Africa/Harare"),
        "HYD": Station(city: "Hyderabad", country: "India", timeZone: "Asia/Kolkata"),
        "IAD": Station(city: "Washington", country: "United States", timeZone: "America/New_York"),
        "IAH": Station(city: "Houston", country: "United States", timeZone: "America/Chicago"),
        "ICN": Station(city: "Seoul", country: "South Korea", timeZone: "Asia/Seoul"),
        "IKA": Station(city: "Tehran", country: "Iran", timeZone: "Asia/Tehran"),
        "ISB": Station(city: "Islamabad", country: "Pakistan", timeZone: "Asia/Karachi"),
        "ISL": Station(city: "Istanbul", country: "Turkey", timeZone: "Europe/Istanbul"),
        "IST": Station(city: "Istanbul", country: "Turkey", timeZone: "Europe/Istanbul"),
        "JED": Station(city: "Jeddah", country: "Saudi Arabia", timeZone: "Asia/Riyadh"),
        "JFK": Station(city: "New York", country: "United States", timeZone: "America/New_York"),
        "JNB": Station(city: "Johannesburg", country: "South Africa", timeZone: "Africa/Johannesburg"),
        "KHI": Station(city: "Karachi", country: "Pakistan", timeZone: "Asia/Karachi"),
        "KIX": Station(city: "Osaka", country: "Japan", timeZone: "Asia/Tokyo"),
        "KTI": Station(city: "Phnom Penh", country: "Cambodia", timeZone: "Asia/Phnom_Penh"),
        "KUL": Station(city: "Kuala Lumpur", country: "Malaysia", timeZone: "Asia/Kuala_Lumpur"),
        "KWI": Station(city: "Kuwait City", country: "Kuwait", timeZone: "Asia/Kuwait"),
        "LAX": Station(city: "Los Angeles", country: "United States", timeZone: "America/Los_Angeles"),
        "LBG": Station(city: "Paris", country: "France", timeZone: "Europe/Paris"),
        "LCA": Station(city: "Larnaca", country: "Cyprus", timeZone: "Asia/Nicosia"),
        "LED": Station(city: "Saint Petersburg", country: "Russia", timeZone: "Europe/Moscow"),
        "LFW": Station(city: "Lome", country: "Togo", timeZone: "Africa/Lome"),
        "LGG": Station(city: "Liege", country: "Belgium", timeZone: "Europe/Brussels"),
        "LGW": Station(city: "London", country: "United Kingdom", timeZone: "Europe/London"),
        "LHE": Station(city: "Lahore", country: "Pakistan", timeZone: "Asia/Karachi"),
        "LHR": Station(city: "London", country: "United Kingdom", timeZone: "Europe/London"),
        "LIS": Station(city: "Lisbon", country: "Portugal", timeZone: "Europe/Lisbon"),
        "LLW": Station(city: "Lilongwe", country: "Malawi", timeZone: "Africa/Blantyre"),
        "LOS": Station(city: "Lagos", country: "Nigeria", timeZone: "Africa/Lagos"),
        "LTN": Station(city: "London", country: "United Kingdom", timeZone: "Europe/London"),
        "LUN": Station(city: "Lusaka", country: "Zambia", timeZone: "Africa/Lusaka"),
        "LYS": Station(city: "Lyon", country: "France", timeZone: "Europe/Paris"),
        "MAA": Station(city: "Chennai", country: "India", timeZone: "Asia/Kolkata"),
        "MAD": Station(city: "Madrid", country: "Spain", timeZone: "Europe/Madrid"),
        "MAN": Station(city: "Manchester", country: "United Kingdom", timeZone: "Europe/London"),
        "MCO": Station(city: "Orlando", country: "United States", timeZone: "America/New_York"),
        "MCT": Station(city: "Muscat", country: "Oman", timeZone: "Asia/Muscat"),
        "MED": Station(city: "Medina", country: "Saudi Arabia", timeZone: "Asia/Riyadh"),
        "MEL": Station(city: "Melbourne", country: "Australia", timeZone: "Australia/Melbourne"),
        "MEX": Station(city: "Mexico City", country: "Mexico", timeZone: "America/Mexico_City"),
        "MIA": Station(city: "Miami", country: "United States", timeZone: "America/New_York"),
        "MLA": Station(city: "Valletta", country: "Malta", timeZone: "Europe/Malta"),
        "MLE": Station(city: "Male", country: "Maldives", timeZone: "Indian/Maldives"),
        "MNL": Station(city: "Manila", country: "Philippines", timeZone: "Asia/Manila"),
        "MRU": Station(city: "Port Louis", country: "Mauritius", timeZone: "Indian/Mauritius"),
        "MSP": Station(city: "Minneapolis", country: "United States", timeZone: "America/Chicago"),
        "MST": Station(city: "Maastricht", country: "Netherlands", timeZone: "Europe/Amsterdam"),
        "MUC": Station(city: "Munich", country: "Germany", timeZone: "Europe/Berlin"),
        "MXP": Station(city: "Milan", country: "Italy", timeZone: "Europe/Rome"),
        "NBJ": Station(city: "Luanda", country: "Angola", timeZone: "Africa/Luanda"),
        "NBO": Station(city: "Nairobi", country: "Kenya", timeZone: "Africa/Nairobi"),
        "NCE": Station(city: "Nice", country: "France", timeZone: "Europe/Paris"),
        "NCL": Station(city: "Newcastle", country: "United Kingdom", timeZone: "Europe/London"),
        "NLU": Station(city: "Mexico City", country: "Mexico", timeZone: "America/Mexico_City"),
        "NQY": Station(city: "Newquay", country: "United Kingdom", timeZone: "Europe/London"),
        "NRT": Station(city: "Tokyo", country: "Japan", timeZone: "Asia/Tokyo"),
        "ORD": Station(city: "Chicago", country: "United States", timeZone: "America/Chicago"),
        "OSL": Station(city: "Oslo", country: "Norway", timeZone: "Europe/Oslo"),
        "PAE": Station(city: "Everett", country: "United States", timeZone: "America/Los_Angeles"),
        "PEK": Station(city: "Beijing", country: "China", timeZone: "Asia/Shanghai"),
        "PER": Station(city: "Perth", country: "Australia", timeZone: "Australia/Perth"),
        "PEW": Station(city: "Peshawar", country: "Pakistan", timeZone: "Asia/Karachi"),
        "PKX": Station(city: "Beijing", country: "China", timeZone: "Asia/Shanghai"),
        "PRG": Station(city: "Prague", country: "Czech Republic", timeZone: "Europe/Prague"),
        "PVG": Station(city: "Shanghai", country: "China", timeZone: "Asia/Shanghai"),
        "QRO": Station(city: "Queretaro", country: "Mexico", timeZone: "America/Mexico_City"),
        "RFD": Station(city: "Rockford", country: "United States", timeZone: "America/Chicago"),
        "RUH": Station(city: "Riyadh", country: "Saudi Arabia", timeZone: "Asia/Riyadh"),
        "SAI": Station(city: "Siem Reap", country: "Cambodia", timeZone: "Asia/Phnom_Penh"),
        "SEA": Station(city: "Seattle", country: "United States", timeZone: "America/Los_Angeles"),
        "SEZ": Station(city: "Mahe", country: "Seychelles", timeZone: "Indian/Mahe"),
        "SFO": Station(city: "San Francisco", country: "United States", timeZone: "America/Los_Angeles"),
        "SGN": Station(city: "Ho Chi Minh City", country: "Vietnam", timeZone: "Asia/Ho_Chi_Minh"),
        "SHJ": Station(city: "Sharjah", country: "United Arab Emirates", timeZone: "Asia/Dubai"),
        "SIN": Station(city: "Singapore", country: "Singapore", timeZone: "Asia/Singapore"),
        "SKT": Station(city: "Sialkot", country: "Pakistan", timeZone: "Asia/Karachi"),
        "STN": Station(city: "London", country: "United Kingdom", timeZone: "Europe/London"),
        "SYD": Station(city: "Sydney", country: "Australia", timeZone: "Australia/Sydney"),
        "SZX": Station(city: "Shenzhen", country: "China", timeZone: "Asia/Shanghai"),
        "TEV": Station(city: "Teruel", country: "Spain", timeZone: "Europe/Madrid"),
        "TLS": Station(city: "Toulouse", country: "France", timeZone: "Europe/Paris"),
        "TLV": Station(city: "Tel Aviv", country: "Israel", timeZone: "Asia/Jerusalem"),
        "TNR": Station(city: "Antananarivo", country: "Madagascar", timeZone: "Indian/Antananarivo"),
        "TPE": Station(city: "Taipei", country: "Taiwan", timeZone: "Asia/Taipei"),
        "TRV": Station(city: "Thiruvananthapuram", country: "India", timeZone: "Asia/Kolkata"),
        "TUN": Station(city: "Tunis", country: "Tunisia", timeZone: "Africa/Tunis"),
        "UIO": Station(city: "Quito", country: "Ecuador", timeZone: "America/Guayaquil"),
        "UTC": Station(city: "Coordinated Universal Time", country: "Worldwide", timeZone: "UTC"),
        "VCE": Station(city: "Venice", country: "Italy", timeZone: "Europe/Rome"),
        "VIE": Station(city: "Vienna", country: "Austria", timeZone: "Europe/Vienna"),
        "WAW": Station(city: "Warsaw", country: "Poland", timeZone: "Europe/Warsaw"),
        "XMN": Station(city: "Xiamen", country: "China", timeZone: "Asia/Shanghai"),
        "YUL": Station(city: "Montreal", country: "Canada", timeZone: "America/Toronto"),
        "YYZ": Station(city: "Toronto", country: "Canada", timeZone: "America/Toronto"),
        "ZAZ": Station(city: "Zaragoza", country: "Spain", timeZone: "Europe/Madrid"),
        "ZRH": Station(city: "Zurich", country: "Switzerland", timeZone: "Europe/Zurich"),
    ]
}
