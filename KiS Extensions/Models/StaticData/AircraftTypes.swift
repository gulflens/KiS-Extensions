import Foundation

struct AircraftType {
    let typesOfAircraftIndex: Int
    let crc: Int // -1 = no CRC, 1 = B773 CRC, 2 = LD CRC, 3 = MD CRC
    let aircraftModel: String
    let classes: Int
    let description: String
    let fullDescription: String
}

struct AircraftTypes {
    static let types: [Int: AircraftType] = [
        1:  AircraftType(typesOfAircraftIndex: 1,  crc: 1,  aircraftModel: "B773", classes: 3, description: "B773 3 class", fullDescription: "B773 3 class (with CRC)"),
        2:  AircraftType(typesOfAircraftIndex: 2,  crc: 1,  aircraftModel: "B773", classes: 3, description: "B773 3 class (JC Falcon seats)", fullDescription: "B773 3 class (with CRC, JC Falcon seats)"),
        3:  AircraftType(typesOfAircraftIndex: 3,  crc: 1,  aircraftModel: "B773", classes: 3, description: "B773 3 class (Game changer)", fullDescription: "B773 3 class (with CRC, Game changer)"),
        4:  AircraftType(typesOfAircraftIndex: 4,  crc: 1,  aircraftModel: "B772", classes: 2, description: "B772 2 class (JC Falcon seats)", fullDescription: "B772 2 class (with CRC, JC Falcon seats)"),
        5:  AircraftType(typesOfAircraftIndex: 5,  crc: -1, aircraftModel: "B773", classes: 2, description: "B773 2 class", fullDescription: "B773 2 class (no CRC)"),
        6:  AircraftType(typesOfAircraftIndex: 6,  crc: -1, aircraftModel: "B773", classes: 3, description: "B773 3 class", fullDescription: "B773 3 class (no CRC)"),
        7:  AircraftType(typesOfAircraftIndex: 7,  crc: -1, aircraftModel: "A380", classes: 2, description: "A380 2 class", fullDescription: "A380 2 class (no CRC)"),
        8:  AircraftType(typesOfAircraftIndex: 8,  crc: -1, aircraftModel: "A380", classes: 3, description: "A380 3 class", fullDescription: "A380 3 class (no CRC)"),
        9:  AircraftType(typesOfAircraftIndex: 9,  crc: 3,  aircraftModel: "A380", classes: 3, description: "A380 3 class", fullDescription: "A380 3 class (with MD-CRC)"),
        10: AircraftType(typesOfAircraftIndex: 10, crc: 2,  aircraftModel: "A380", classes: 4, description: "A380 4 class", fullDescription: "A380 4 class (with LD-CRC)"),
        11: AircraftType(typesOfAircraftIndex: 11, crc: 2,  aircraftModel: "A380", classes: 3, description: "A380 3 class", fullDescription: "A380 3 class (with LD-CRC)"),
        12: AircraftType(typesOfAircraftIndex: 12, crc: 1,  aircraftModel: "B773", classes: 4, description: "B773 4 class (Game changer)", fullDescription: "B773 4 class (with CRC, Game changer)"),
        13: AircraftType(typesOfAircraftIndex: 13, crc: -1, aircraftModel: "A350", classes: 3, description: "A350 3 class", fullDescription: "A350 3 class (no CRC, no first class)"),
        14: AircraftType(typesOfAircraftIndex: 14, crc: -1, aircraftModel: "A380", classes: 4, description: "A380 4 class", fullDescription: "A380 4 class (no CRC)"),
        15: AircraftType(typesOfAircraftIndex: 15, crc: 3,  aircraftModel: "A380", classes: 4, description: "A380 4 class", fullDescription: "A380 4 class (MD-CRC)"),
        16: AircraftType(typesOfAircraftIndex: 16, crc: 1,  aircraftModel: "B773", classes: 4, description: "B773 4 class", fullDescription: "B773 4 class (non-Game changer)"),
        17: AircraftType(typesOfAircraftIndex: 17, crc: -1, aircraftModel: "B773", classes: 4, description: "B773 4 class", fullDescription: "B773 4 class (no CRC)"),
        18: AircraftType(typesOfAircraftIndex: 18, crc: 1,  aircraftModel: "A350", classes: 3, description: "A350 3 class (CRC)", fullDescription: "A350 3 class (no CRC, no first class)"),
    ]
}
