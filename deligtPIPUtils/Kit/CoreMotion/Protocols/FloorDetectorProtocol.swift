//
//  FloorDetectorProtocol.swift
//  deligtPIPUtils
//
//  Created by taeni on 9/15/25.
//


import Foundation

// MARK: - Floor Detector Protocol
@MainActor
protocol FloorDetectorProtocol: ObservableObject {
    // MARK: - Basic Properties
    var currentFloor: Int { get }
    var relativeAltitude: Double { get }
    var pressure: Double { get }
    var isMonitoring: Bool { get }
    var statusMessage: String { get }
    var showPermissionAlert: Bool { get }
    
    // MARK: - Enhanced Properties
    var transportationType: TransportationType { get }
    var walkingFloors: Int { get }
    var totalSteps: Int { get }
    var activityType: String { get }
    var altitudeHistory: [AltitudeReading] { get }
    
    // MARK: - Control Methods
    func startMonitoring()
    func stopMonitoring()
    func resetMeasurement()
    func openSettings()
    
    // MARK: - Optional Advanced Methods
    func exportData() -> Data?
    func importData(from data: Data) -> Bool
    func getStatistics() -> FloorStatistics
}

// MARK: - Floor Statistics
struct FloorStatistics {
    let totalSessions: Int
    let totalFloorsClimbed: Int
    let totalFloorsDescended: Int
    let totalSteps: Int
    let averageFloorHeight: Double
    let mostUsedTransportMethod: TransportationType
    let totalMonitoringTime: TimeInterval
    
    var formattedMonitoringTime: String {
        let hours = Int(totalMonitoringTime) / 3600
        let minutes = Int(totalMonitoringTime) % 3600 / 60
        return "\(hours)시간 \(minutes)분"
    }
    
    static func empty() -> FloorStatistics {
        return FloorStatistics(
            totalSessions: 0,
            totalFloorsClimbed: 0,
            totalFloorsDescended: 0,
            totalSteps: 0,
            averageFloorHeight: 3.0,
            mostUsedTransportMethod: .unknown,
            totalMonitoringTime: 0
        )
    }
}

// MARK: - Default Protocol Implementation
extension FloorDetectorProtocol {
    func exportData() -> Data? {
        // 기본 구현: JSON으로 히스토리 내보내기
        do {
            return try JSONEncoder().encode(altitudeHistory)
        } catch {
            print("❌ 데이터 내보내기 실패: \(error)")
            return nil
        }
    }
    
    func importData(from data: Data) -> Bool {
        // 기본 구현: 서브클래스에서 구현 필요
        return false
    }
    
    func getStatistics() -> FloorStatistics {
        let history = altitudeHistory
        
        let floorsClimbed = history.compactMap { $0.floor > 0 ? $0.floor : nil }.reduce(0, +)
        let floorsDescended = history.compactMap { $0.floor < 0 ? abs($0.floor) : nil }.reduce(0, +)
        let totalSteps = history.last?.steps ?? 0
        
        // 가장 많이 사용된 이동 방법
        let transportCounts = Dictionary(grouping: history, by: { $0.transportType })
            .mapValues { $0.count }
        let mostUsed = transportCounts.max(by: { $0.value < $1.value })?.key ?? .unknown
        
        // 모니터링 시간 계산
        let startTime = history.first?.timestamp ?? Date()
        let endTime = history.last?.timestamp ?? Date()
        let monitoringTime = endTime.timeIntervalSince(startTime)
        
        return FloorStatistics(
            totalSessions: history.isEmpty ? 0 : 1,
            totalFloorsClimbed: floorsClimbed,
            totalFloorsDescended: floorsDescended,
            totalSteps: totalSteps,
            averageFloorHeight: 3.0,
            mostUsedTransportMethod: mostUsed,
            totalMonitoringTime: monitoringTime
        )
    }
}