//
//  EnhancedHistoryView.swift
//  deligtPIPUtils
//
//  Created by taeni on 9/15/25.
//


import SwiftUI

// MARK: - Enhanced History View
struct EnhancedHistoryView: View {
    let history: [AltitudeReading]
    @State private var selectedFilter: TransportationType? = nil
    @State private var showingExportSheet = false
    @State private var showingStatistics = false
    
    private var filteredHistory: [AltitudeReading] {
        if let filter = selectedFilter {
            return history.filter { $0.transportType == filter }
        }
        return history
    }
    
    private var statistics: HistoryStatistics {
        HistoryStatistics(from: history)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 필터 및 액션 바
            FilterActionBar(
                selectedFilter: $selectedFilter,
                showingStatistics: $showingStatistics,
                showingExportSheet: $showingExportSheet,
                statistics: statistics
            )
            
            // 히스토리 리스트
            List(filteredHistory.reversed()) { reading in
                HistoryRowView(reading: reading)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .listRowBackground(Color.clear)
            }
            .listStyle(PlainListStyle())
        }
        .navigationTitle("이동 히스토리")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingStatistics) {
            StatisticsView(statistics: statistics)
        }
        .sheet(isPresented: $showingExportSheet) {
            ExportView(history: history)
        }
    }
}

// MARK: - Filter Action Bar
struct FilterActionBar: View {
    @Binding var selectedFilter: TransportationType?
    @Binding var showingStatistics: Bool
    @Binding var showingExportSheet: Bool
    let statistics: HistoryStatistics
    
    var body: some View {
        VStack(spacing: 12) {
            // 통계 요약
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("총 \(statistics.totalReadings)개 기록")
                        .font(.headline)
                    Text("최고 \(statistics.maxFloor)층 • 최저 \(statistics.minFloor)층")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button("통계") {
                    showingStatistics = true
                }
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.blue.opacity(0.1))
                .foregroundColor(.blue)
                .clipShape(Capsule())
            }
            
            // 필터 버튼들
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    FilterButton(
                        title: "전체",
                        isSelected: selectedFilter == nil,
                        action: { selectedFilter = nil }
                    )
                    
                    ForEach(statistics.availableTransportTypes, id: \.self) { type in
                        FilterButton(
                            title: type.rawValue,
                            isSelected: selectedFilter == type,
                            color: type.color,
                            action: { 
                                selectedFilter = selectedFilter == type ? nil : type 
                            }
                        )
                    }
                }
                .padding(.horizontal)
            }
            
            // 액션 버튼들
            HStack {
                Button("내보내기") {
                    showingExportSheet = true
                }
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color(.systemGray5))
                .clipShape(Capsule())
                
                Spacer()
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
        .background(Color(.systemGray6).opacity(0.5))
    }
}

// MARK: - Filter Button
struct FilterButton: View {
    let title: String
    let isSelected: Bool
    var color: Color = .blue
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? color : Color(.systemGray5))
                .foregroundColor(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
    }
}

// MARK: - History Row View
struct HistoryRowView: View {
    let reading: AltitudeReading
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 상단: 층수, 이동방법, 시간
            HStack {
                HStack(spacing: 4) {
                    Text("층수:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(reading.floor)")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(reading.floor == 0 ? .primary : 
                                       reading.floor > 0 ? .green : .red)
                }
                
                Spacer()
                
                Text(reading.transportType.rawValue)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(reading.transportType.color.opacity(0.2))
                    .foregroundColor(reading.transportType.color)
                    .clipShape(Capsule())
                
                Text(reading.formattedTime)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // 중간: 센서 데이터
            HStack {
                SensorDataChip(
                    icon: "arrow.up.arrow.down",
                    value: reading.formattedAltitude,
                    color: .blue
                )
                
                SensorDataChip(
                    icon: "barometer",
                    value: reading.formattedPressure,
                    color: .purple
                )
                
                if reading.walkingFloors != 0 {
                    SensorDataChip(
                        icon: "figure.stairs",
                        value: "\(reading.walkingFloors)층",
                        color: .green
                    )
                }
                
                Spacer()
            }
            
            // 하단: 활동 및 걸음
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "figure.wave")
                        .font(.caption)
                        .foregroundColor(.blue)
                    Text(reading.activity)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if reading.steps > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "figure.walk")
                            .font(.caption)
                            .foregroundColor(.orange)
                        Text("\(reading.steps) 걸음")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Sensor Data Chip
struct SensorDataChip: View {
    let icon: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundColor(color)
            Text(value)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(color.opacity(0.1))
        .clipShape(Capsule())
    }
}

// MARK: - History Statistics
struct HistoryStatistics {
    let totalReadings: Int
    let maxFloor: Int
    let minFloor: Int
    let totalSteps: Int
    let availableTransportTypes: [TransportationType]
    let transportCounts: [TransportationType: Int]
    let totalMonitoringTime: TimeInterval
    let averageFloorChange: Double
    
    init(from history: [AltitudeReading]) {
        totalReadings = history.count
        maxFloor = history.map { $0.floor }.max() ?? 0
        minFloor = history.map { $0.floor }.min() ?? 0
        totalSteps = history.last?.steps ?? 0
        
        let typeCounts = Dictionary(grouping: history, by: { $0.transportType })
            .mapValues { $0.count }
        transportCounts = typeCounts
        availableTransportTypes = Array(typeCounts.keys).sorted { $0.rawValue < $1.rawValue }
        
        if let firstTime = history.first?.timestamp,
           let lastTime = history.last?.timestamp {
            totalMonitoringTime = lastTime.timeIntervalSince(firstTime)
        } else {
            totalMonitoringTime = 0
        }
        
        let floorChanges = history.map { abs($0.floor) }
        averageFloorChange = floorChanges.isEmpty ? 0 : Double(floorChanges.reduce(0, +)) / Double(floorChanges.count)
    }
}

// MARK: - Statistics View
struct StatisticsView: View {
    let statistics: HistoryStatistics
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section("📊 전체 통계") {
                    StatRow(title: "총 기록 수", value: "\(statistics.totalReadings)개")
                    StatRow(title: "최고층", value: "\(statistics.maxFloor)층")
                    StatRow(title: "최저층", value: "\(statistics.minFloor)층")
                    StatRow(title: "총 걸음 수", value: "\(statistics.totalSteps)걸음")
                    StatRow(title: "평균 층 변화", value: String(format: "%.1f층", statistics.averageFloorChange))
                    StatRow(title: "모니터링 시간", value: formatTime(statistics.totalMonitoringTime))
                }
                
                Section("🚶‍♂️ 이동 방법별 통계") {
                    ForEach(statistics.availableTransportTypes, id: \.self) { type in
                        HStack {
                            Text(type.rawValue)
                                .foregroundColor(type.color)
                            Spacer()
                            Text("\(statistics.transportCounts[type] ?? 0)회")
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("상세 통계")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarActions {
                Button("완료") {
                    dismiss()
                }
            }
        }
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return "\(minutes)분 \(seconds)초"
    }
}

// MARK: - Stat Row
struct StatRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Export View
struct ExportView: View {
    let history: [AltitudeReading]
    @Environment(\.dismiss) private var dismiss
    @State private var exportFormat: ExportFormat = .json
    
    enum ExportFormat: String, CaseIterable {
        case json = "JSON"
        case csv = "CSV"
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("데이터 내보내기")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Picker("형식", selection: $exportFormat) {
                    ForEach(ExportFormat.allCases, id: \.self) { format in
                        Text(format.rawValue).tag(format)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("내보낼 데이터:")
                        .font(.headline)
                    Text("• 총 \(history.count)개 기록")
                    Text("• 고도, 기압, 층수, 걸음 수")
                    Text("• 이동 방법 및 활동 정보")
                    Text("• 타임스탬프")
                }
                .foregroundColor(.secondary)
                
                Spacer()
                
                Button("데이터 내보내기") {
                    exportData()
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarActions {
                Button("취소") {
                    dismiss()
                }
            }
        }
    }
    
    private func exportData() {
        // 실제 앱에서는 파일 내보내기 구현
        print("📤 \(exportFormat.rawValue) 형식으로 \(history.count)개 데이터 내보내기")
        dismiss()
    }
}

// MARK: - Navigation Bar Actions Helper
extension View {
    func navigationBarActions<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        self.toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                content()
            }
        }
    }
}