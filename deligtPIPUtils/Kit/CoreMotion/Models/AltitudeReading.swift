//
//  AltitudeReading.swift
//  deligtPIPUtils
//
//  Created by taeni on 9/15/25.
//


import Foundation

// MARK: - Altitude Reading Model
struct AltitudeReading: Identifiable, Codable {
    var id = UUID()
    let altitude: Double
    let pressure: Double
    let timestamp: Date
    let floor: Int
    let walkingFloors: Int
    let steps: Int
    let transportType: TransportationType
    let activity: String
    
    // MARK: - Computed Properties
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        return formatter.string(from: timestamp)
    }
    
    var formattedAltitude: String {
        return String(format: "%.2f m", altitude)
    }
    
    var formattedPressure: String {
        return String(format: "%.1f hPa", pressure)
    }
    
    var floorDifference: Int {
        return floor - walkingFloors
    }
    
    var isSignificantMovement: Bool {
        return abs(floor) > 0 || abs(altitude) > 1.0
    }
    
    // MARK: - Static Methods
    static func sample() -> AltitudeReading {
        return AltitudeReading(
            altitude: 9.2,
            pressure: 1013.2,
            timestamp: Date(),
            floor: 3,
            walkingFloors: 3,
            steps: 245,
            transportType: .stairs,
            activity: "걷기"
        )
    }
    
    static func elevatorSample() -> AltitudeReading {
        return AltitudeReading(
            altitude: 24.0,
            pressure: 1009.8,
            timestamp: Date(),
            floor: 8,
            walkingFloors: 0,
            steps: 12,
            transportType: .elevator,
            activity: "정적"
        )
    }
    
    static func escalatorSample() -> AltitudeReading {
        return AltitudeReading(
            altitude: 12.1,
            pressure: 1011.5,
            timestamp: Date(),
            floor: 4,
            walkingFloors: 0,
            steps: 89,
            transportType: .escalator,
            activity: "걷기"
        )
    }
}

// MARK: - Codable Support for TransportationType
extension TransportationType: Codable {
    enum CodingKeys: String, CodingKey {
        case rawValue
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        self = TransportationType(rawValue: rawValue) ?? .unknown
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.rawValue)
    }
}
