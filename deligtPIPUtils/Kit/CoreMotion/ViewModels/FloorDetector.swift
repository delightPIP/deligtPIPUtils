//
//  FloorDetector.swift
//  deligtPIPUtils
//
//  Created by taeni on 9/15/25.
//

import Foundation
import CoreMotion
import UIKit

// MARK: - Enhanced Floor Detector
@MainActor
class FloorDetector: ObservableObject, FloorDetectorProtocol {
    // MARK: - Published Properties
    @Published var currentFloor: Int = 0
    @Published var relativeAltitude: Double = 0.0
    @Published var pressure: Double = 0.0
    @Published var isMonitoring: Bool = false
    @Published var statusMessage: String = "준비됨"
    @Published var altitudeHistory: [AltitudeReading] = []
    @Published var showPermissionAlert: Bool = false
    
    // Enhanced Properties
    @Published var transportationType: TransportationType = .unknown
    @Published var walkingFloors: Int = 0
    @Published var totalSteps: Int = 0
    @Published var activityType: String = "정적"
    
    // MARK: - Private Properties
    private let altimeter = CMAltimeter()
    private let pedometer = CMPedometer()
    private let activityManager = CMMotionActivityManager()
    private let averageFloorHeight: Double = 3.0
    private var startingAltitude: Double = 0.0
    private var lastPedometerUpdate: Date = Date()
    private var currentActivity: CMMotionActivity?
    private var sessionStartTime: Date?
    
    // MARK: - Initialization
    init() {
        setupNotifications()
        print("🎯 FloorDetector 초기화 완료")
    }
    
    // MARK: - Deinit (MainActor 문제 완전 해결)
    deinit {
        // MainActor 호출 없이 직접 센서 정리
        altimeter.stopRelativeAltitudeUpdates()
        pedometer.stopUpdates()
        activityManager.stopActivityUpdates()
        
        // 알림 센터 정리
        NotificationCenter.default.removeObserver(self)
        print("🧹 FloorDetector 정리 완료")
    }
    
    // MARK: - Public Methods
    func startMonitoring() {
        print("🚀 startMonitoring() 시작")
        
        guard CMAltimeter.isRelativeAltitudeAvailable() else {
            statusMessage = "❌ 기압계가 지원되지 않는 기기입니다"
            print("❌ CMAltimeter 사용 불가")
            return
        }
        
        sessionStartTime = Date()
        requestAllPermissions()
        startAltimeterMonitoring()
        startPedometerMonitoring()
        startActivityMonitoring()
        
        isMonitoring = true
        statusMessage = "🔍 전체 센서 모니터링 중..."
        print("✅ 모든 센서 시작됨 - isMonitoring: \(isMonitoring)")
        
        // 3초 후 기준점 설정
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            if self.isMonitoring {
                self.startingAltitude = self.relativeAltitude
                self.statusMessage = "✅ 모든 센서 활성화 완료"
                print("📍 기준점 설정 완료: \(self.startingAltitude)m")
            }
        }
    }
    
    func stopMonitoring() {
        print("🛑 stopMonitoring() 호출됨 - 현재 상태: \(isMonitoring)")
        
        // 1. 모든 센서 즉시 중지
        altimeter.stopRelativeAltitudeUpdates()
        pedometer.stopUpdates()
        activityManager.stopActivityUpdates()
        print("🔌 모든 센서 중지 완료")
        
        // 2. 상태 업데이트
        isMonitoring = false
        statusMessage = "⏹️ 모니터링 중지됨"
        sessionStartTime = nil
        
        print("✅ 모니터링 중지 완료 - isMonitoring: \(isMonitoring)")
        print("📊 최종 데이터 - 층수: \(currentFloor), 걸음: \(totalSteps), 이동방법: \(transportationType.rawValue)")
    }
    
    func resetMeasurement() {
        print("🔄 resetMeasurement() 시작")
        
        // 1. 모니터링 중지
        stopMonitoring()
        
        // 2. 모든 데이터 초기화
        currentFloor = 0
        relativeAltitude = 0.0
        pressure = 0.0
        walkingFloors = 0
        totalSteps = 0
        startingAltitude = 0.0
        transportationType = .unknown
        activityType = "정적"
        altitudeHistory.removeAll()
        statusMessage = "🔄 모든 데이터 초기화됨"
        sessionStartTime = nil
        
        print("✅ 전체 초기화 완료")
    }
    
    func openSettings() {
        print("🔧 설정 페이지 열기")
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
            print("❌ 설정 URL 생성 실패")
            return
        }
        if UIApplication.shared.canOpenURL(settingsUrl) {
            UIApplication.shared.open(settingsUrl)
            print("✅ 설정 페이지 열림")
        }
    }
    
    // MARK: - Protocol Extensions
    func importData(from data: Data) -> Bool {
        do {
            let importedHistory = try JSONDecoder().decode([AltitudeReading].self, from: data)
            altitudeHistory = importedHistory
            statusMessage = "✅ 데이터 가져오기 완료 (\(importedHistory.count)개 항목)"
            print("📥 데이터 가져오기 성공: \(importedHistory.count)개")
            return true
        } catch {
            statusMessage = "❌ 데이터 가져오기 실패: \(error.localizedDescription)"
            print("❌ 데이터 가져오기 실패: \(error)")
            return false
        }
    }
    
    // MARK: - Private Methods
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }
    
    @objc private func appDidEnterBackground() {
        print("📱 앱이 백그라운드로 이동 - 모니터링 계속: \(isMonitoring)")
    }
    
    @objc private func appWillEnterForeground() {
        print("📱 앱이 포그라운드로 복귀 - 모니터링 상태: \(isMonitoring)")
        if isMonitoring {
            statusMessage = "🔄 센서 상태 확인 중..."
        }
    }
    
    private func requestAllPermissions() {
        print("🔑 권한 요청 시작")
        // iOS 17.4+ Motion & Fitness 권한 요청
        let recorder = CMSensorRecorder()
        recorder.recordAccelerometer(forDuration: 0.1)
        print("📡 권한 요청 완료")
    }
    
    private func startAltimeterMonitoring() {
        print("🌡️ CMAltimeter 모니터링 시작")
        
        altimeter.startRelativeAltitudeUpdates(to: .main) { [weak self] data, error in
            guard let self = self else { return }
            
            if let error = error {
                print("❌ Altimeter Error: \(error)")
                DispatchQueue.main.async {
                    self.handleError(error)
                }
                return
            }
            
            guard let altitudeData = data else {
                print("❌ Altimeter Data is nil")
                DispatchQueue.main.async {
                    self.statusMessage = "❌ 고도 데이터를 가져올 수 없습니다"
                }
                return
            }
            
            DispatchQueue.main.async {
                self.updateAltitudeData(altitudeData)
            }
        }
    }
    
    private func startPedometerMonitoring() {
        print("👣 CMPedometer 모니터링 시작")
        
        // 기능 가용성 개별 체크
        guard CMPedometer.isStepCountingAvailable() else {
            print("⚠️ 걸음 수 카운팅을 사용할 수 없습니다")
            return
        }
        
        if !CMPedometer.isFloorCountingAvailable() {
            print("⚠️ 층수 카운팅을 사용할 수 없습니다 (걸음 수만 사용)")
        }
        
        let startDate = Date()
        pedometer.startUpdates(from: startDate) { [weak self] data, error in
            guard let self = self else { return }
            
            if let error = error {
                print("❌ Pedometer Error: \(error.localizedDescription)")
                return
            }
            
            guard let pedometerData = data else {
                print("❌ Pedometer Data is nil")
                return
            }
            
            DispatchQueue.main.async {
                self.updatePedometerData(pedometerData)
            }
        }
    }
    
    private func startActivityMonitoring() {
        print("🎯 CMMotionActivityManager 모니터링 시작")
        
        guard CMMotionActivityManager.isActivityAvailable() else {
            print("⚠️ Activity Manager를 사용할 수 없습니다")
            return
        }
        
        activityManager.startActivityUpdates(to: .main) { [weak self] activity in
            guard let self = self, let activity = activity else { return }
            
            DispatchQueue.main.async {
                self.updateActivityData(activity)
            }
        }
    }
    
    private func updateAltitudeData(_ data: CMAltitudeData) {
        let newAltitude = data.relativeAltitude.doubleValue
        let newPressure = data.pressure.doubleValue * 10
        
        relativeAltitude = newAltitude
        pressure = newPressure
        
        let relativeFromStart = newAltitude - startingAltitude
        currentFloor = Int(round(relativeFromStart / averageFloorHeight))
        
        // 이동 방법 분석
        analyzeTransportationType()
        
        // 히스토리 업데이트
        addToHistory()
        updateStatusMessage()
        
        // 상세 로그 (5초마다만)
        if Int(Date().timeIntervalSince1970) % 5 == 0 {
            print("📊 고도 업데이트: \(String(format: "%.2f", newAltitude))m, 기압: \(String(format: "%.1f", newPressure))hPa, 층수: \(currentFloor)")
        }
    }
    
    // NSNumber 옵셔널 바인딩 문제 완전 해결
    private func updatePedometerData(_ data: CMPedometerData) {
        // 1. 걸음 수 - nil coalescing으로 안전 처리
        let newSteps = data.numberOfSteps.intValue
        totalSteps = newSteps
        
        // 2. 층수 - nil coalescing으로 안전 처리
        let floorsUp = data.floorsAscended?.intValue ?? 0
        let floorsDown = data.floorsDescended?.intValue ?? 0
        walkingFloors = floorsUp - floorsDown
        
        lastPedometerUpdate = Date()
        
        print("🦶 Pedometer 업데이트 - 걸음: \(totalSteps), 걸어서 오른 층수: \(walkingFloors) (+\(floorsUp)/-\(floorsDown))")
    }
    
    private func updateActivityData(_ activity: CMMotionActivity) {
        currentActivity = activity
        
        let newActivityType: String
        if activity.walking {
            newActivityType = "걷기"
        } else if activity.running {
            newActivityType = "달리기"
        } else if activity.automotive {
            newActivityType = "자동차"
        } else if activity.cycling {
            newActivityType = "자전거"
        } else if activity.stationary {
            newActivityType = "정적"
        } else {
            newActivityType = "알 수 없음"
        }
        
        if newActivityType != activityType {
            activityType = newActivityType
            print("🎭 활동 변경: \(activityType)")
        }
    }
    
    private func analyzeTransportationType() {
        let altitudeChange = abs(relativeAltitude - startingAltitude)
        let floorChange = abs(currentFloor)
        let walkingFloorChange = abs(walkingFloors)
        
        let oldTransportType = transportationType
        
        // 고도 변화가 거의 없으면
        if altitudeChange < 0.5 {
            transportationType = .stationary
        } else {
            guard let activity = currentActivity else {
                transportationType = .unknown
                return
            }
            
            // AI 분석 로직
            if floorChange > 0 && walkingFloorChange == 0 {
                if activity.stationary {
                    transportationType = .elevator  // 정적 + 고도 변화 = 엘리베이터
                } else if activity.walking {
                    transportationType = .escalator  // 걸음 + 층수 미카운트 = 에스컬레이터
                } else {
                    transportationType = .unknown
                }
            } else if floorChange > 0 && walkingFloorChange > 0 &&
                      abs(floorChange - walkingFloorChange) <= 1 {
                transportationType = .stairs  // 걸음 + 층수 카운트 = 계단
            } else if activity.walking && floorChange == 0 {
                transportationType = .walking  // 평지 걷기
            } else {
                transportationType = .unknown
            }
        }
        
        // 이동 방법 변경 시 로그
        if oldTransportType != transportationType {
            print("🚗 이동 방법 변경: \(oldTransportType.rawValue) → \(transportationType.rawValue)")
        }
    }
    
    private func addToHistory() {
        let reading = AltitudeReading(
            altitude: relativeAltitude,
            pressure: pressure,
            timestamp: Date(),
            floor: currentFloor,
            walkingFloors: walkingFloors,
            steps: totalSteps,
            transportType: transportationType,
            activity: activityType
        )
        
        altitudeHistory.append(reading)
        if altitudeHistory.count > 100 {
            altitudeHistory.removeFirst()
        }
    }
    
    private func updateStatusMessage() {
        let relativeFromStart = relativeAltitude - startingAltitude
        
        if abs(relativeFromStart) < 0.5 {
            statusMessage = "📍 기준 층 (\(transportationType.rawValue))"
        } else {
            let direction = relativeFromStart > 0 ? "⬆️" : "⬇️"
            let floorText = abs(currentFloor) == 1 ? "층" : "층"
            statusMessage = "\(direction) \(abs(currentFloor))\(floorText) - \(transportationType.rawValue)"
            
            if walkingFloors != currentFloor && walkingFloors != 0 {
                statusMessage += " (걸음: \(abs(walkingFloors))층)"
            }
        }
    }
    
    private func handleError(_ error: Error) {
        print("🚨 에러 발생 - stopMonitoring() 호출")
        stopMonitoring()
        
        let nsError = error as NSError
        print("🚨 Error Domain: \(nsError.domain), Code: \(nsError.code)")
        print("🚨 Error Description: \(error.localizedDescription)")
        
        switch nsError.code {
        case 105: // CMErrorMotionActivityNotAuthorized
            statusMessage = "❌ Motion & Fitness 권한이 필요합니다"
            showPermissionAlert = true
            print("🔑 권한 필요 - 알림 표시")
        case 106: // CMErrorMotionActivityNotAvailable
            statusMessage = "❌ 모션 데이터를 사용할 수 없습니다"
        case 107: // CMErrorDeviceRequiresMovement
            statusMessage = "⚠️ 기기를 조금 움직여주세요"
        default:
            let errorText = error.localizedDescription.lowercased()
            if errorText.contains("not authorized") {
                statusMessage = "❌ Motion & Fitness 권한이 필요합니다"
                showPermissionAlert = true
                print("🔑 권한 관련 에러 감지")
            } else {
                statusMessage = "❌ 센서 오류가 발생했습니다"
            }
        }
    }
}
