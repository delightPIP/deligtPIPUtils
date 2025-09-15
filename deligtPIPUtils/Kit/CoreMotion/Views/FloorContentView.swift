//
//  FloorContentView.swift (수정된 버전)
//  deligtPIPUtils
//
//  Created by taeni on 9/15/25.
//

import SwiftUI

struct FloorContentView: View {
    @StateObject private var floorDetector = FloorDetector()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 헤더
                    HeaderView()
                    
                    // 현재 층수 & 이동 방법 (수정됨)
                    FloorDisplayView(detector: floorDetector)
                    
                    // 상세 정보 그리드 (수정됨)
                    DetailInfoGridView(detector: floorDetector)
                    
                    // 활동 상태 (수정됨)
                    ActivityStatusView(detector: floorDetector)
                    
                    // 상태 메시지
                    StatusMessageView(message: floorDetector.statusMessage)
                    
                    // 컨트롤 버튼 (수정됨)
                    EnhancedControlButtonsView(detector: floorDetector)
                    
                    // 히스토리 링크
                    if !floorDetector.altitudeHistory.isEmpty {
                        HistoryLinkView(history: floorDetector.altitudeHistory)
                    }
                    
                    // 사용법 안내
                    UsageGuideView()
                }
                .padding()
            }
            .navigationBarHidden(true)
            .alert("권한 필요", isPresented: $floorDetector.showPermissionAlert) {
                Button("설정으로 이동") {
                    floorDetector.openSettings()
                }
                Button("취소", role: .cancel) { }
            } message: {
                Text("층수 및 이동 방법 감지를 위해 Motion & Fitness 권한이 필요합니다.")
            }
        }
    }
}

// MARK: - Header View
struct HeaderView: View {
    var body: some View {
        VStack(spacing: 8) {
            Text("🏗️ 스마트 층수 감지기")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("AI 기반 이동 방법 분석 시스템")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Enhanced Floor Display View (수정된 버전)
struct FloorDisplayView: View {
    @ObservedObject var detector: FloorDetector // 🔥 수정: @ObservedObject 사용
    
    var body: some View {
        VStack {
            HStack {
                VStack(alignment: .leading) {
                    Text("현재 층수")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    // 모니터링 상태 표시 추가
                    HStack(spacing: 8) {
                        Circle()
                            .fill(detector.isMonitoring ? Color.green : Color.red)
                            .frame(width: 8, height: 8)
                        
                        Text(detector.isMonitoring ? "🔴 실시간 모니터링" : "⏸️ 중지됨")
                            .font(.caption)
                            .foregroundColor(detector.isMonitoring ? .green : .red)
                            .fontWeight(.medium)
                    }
                }
                
                Spacer()
                
                // 이동 방법 뱃지
                Text(detector.transportationType.rawValue)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(detector.transportationType.color.opacity(0.2))
                    .foregroundColor(detector.transportationType.color)
                    .clipShape(Capsule())
            }
            
            Text("\(detector.currentFloor)")
                .font(.system(size: 64, weight: .bold, design: .rounded))
                .foregroundColor(detector.currentFloor == 0 ? .primary :
                                    detector.currentFloor > 0 ? .green : .red)
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            // 모니터링 중일 때 애니메이션 테두리
            RoundedRectangle(cornerRadius: 16)
                .stroke(detector.isMonitoring ? Color.blue : Color.clear, lineWidth: 2)
                .opacity(detector.isMonitoring ? 1 : 0)
                .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: detector.isMonitoring)
        )
    }
}

// MARK: - Detail Info Grid View (수정된 버전)
struct DetailInfoGridView: View {
    @ObservedObject var detector: FloorDetector // 🔥 수정: @ObservedObject 사용
    
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
            InfoCard(
                title: "상대 고도",
                value: String(format: "%.2f m", detector.relativeAltitude),
                icon: "arrow.up.arrow.down"
            )
            InfoCard(
                title: "기압",
                value: String(format: "%.1f hPa", detector.pressure),
                icon: "barometer"
            )
            InfoCard(
                title: "걸음 층수",
                value: "\(detector.walkingFloors)",
                icon: "figure.stairs"
            )
            InfoCard(
                title: "총 걸음",
                value: "\(detector.totalSteps)",
                icon: "figure.walk"
            )
        }
    }
}

// MARK: - Activity Status View (수정된 버전)
struct ActivityStatusView: View {
    @ObservedObject var detector: FloorDetector // 🔥 수정: @ObservedObject 사용
    
    var body: some View {
        HStack {
            Image(systemName: activityIcon)
                .foregroundColor(.blue)
            Text("활동: \(detector.activityType)")
                .font(.subheadline)
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var activityIcon: String {
        switch detector.activityType {
        case "걷기": return "figure.walk"
        case "달리기": return "figure.run"
        case "자전거": return "bicycle"
        case "자동차": return "car"
        default: return "figure.wave"
        }
    }
}

// MARK: - Status Message View
struct StatusMessageView: View {
    let message: String
    
    var body: some View {
        Text(message)
            .font(.subheadline)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
            .padding()
            .background(Color(.systemYellow).opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Enhanced Control Buttons View (수정된 버전)
struct EnhancedControlButtonsView: View {
    @ObservedObject var detector: FloorDetector // 🔥 수정: @ObservedObject 사용
    
    var body: some View {
        VStack(spacing: 12) {
            if detector.isMonitoring {
                // 📍 모니터링 중일 때 버튼들
                VStack(spacing: 8) {
                    // 기본 중지 버튼
                    Button(action: {
                        print("🛑 모니터링 중지 버튼 클릭됨")
                        detector.stopMonitoring()
                    }) {
                        Label("모니터링 중지", systemImage: "stop.fill")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    
                    // 강제 중지 & 초기화 버튼 (안전장치)
                    Button(action: {
                        print("🚨 강제 중지 & 초기화 버튼 클릭됨")
                        detector.resetMeasurement()
                    }) {
                        HStack {
                            Image(systemName: "stop.circle.fill")
                            Text("강제 중지 & 초기화")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                
            } else {
                // 📍 모니터링 중지 상태일 때
                Button(action: {
                    print("▶️ 모니터링 시작 버튼 클릭됨")
                    detector.startMonitoring()
                }) {
                    Label("스마트 감지 시작", systemImage: "play.fill")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            
            // 항상 표시되는 초기화 버튼
            Button(action: {
                print("🔄 전체 초기화 버튼 클릭됨")
                detector.resetMeasurement()
            }) {
                Label("전체 초기화", systemImage: "arrow.clockwise")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray4))
                    .foregroundColor(.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }
}

// MARK: - History Link View
struct HistoryLinkView: View {
    let history: [AltitudeReading]
    
    var body: some View {
        NavigationLink(destination: EnhancedHistoryView(history: history)) {
            Label("상세 이동 히스토리", systemImage: "chart.line.uptrend.xyaxis")
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemGray6))
                .foregroundColor(.primary)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

// MARK: - Usage Guide View
struct UsageGuideView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("🤖 AI 분석 방법:")
                .font(.caption)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("🛗 엘리베이터: 정지 상태 + 고도 변화")
                Text("🚶‍♂️ 계단: 걸음 감지 + 층수 카운트")
                Text("⚡ 에스컬레이터: 걸음 감지 + 층수 미카운트")
                Text("📱 실시간 센서 융합 분석")
                Text("🛑 중지 버튼으로 언제든 모니터링 중지 가능")
            }
            .font(.caption2)
            .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBlue).opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    FloorContentView()
}
