//
//  InfoCard.swift
//  deligtPIPUtils
//
//  Created by taeni on 9/15/25.
//

import SwiftUI

// MARK: - Info Card Component
struct InfoCard: View {
    let title: String
    let value: String
    let icon: String
    var color: Color = .blue
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.system(size: 16, weight: .medium))
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            
            HStack {
                Text(value)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                Spacer()
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Specialized Info Cards
struct AltitudeInfoCard: View {
    let altitude: Double
    
    var body: some View {
        InfoCard(
            title: "상대 고도",
            value: String(format: "%.2f m", altitude),
            icon: "arrow.up.arrow.down",
            color: altitude > 0 ? .green : altitude < 0 ? .red : .gray
        )
    }
}

struct PressureInfoCard: View {
    let pressure: Double
    
    var body: some View {
        InfoCard(
            title: "기압",
            value: String(format: "%.1f hPa", pressure),
            icon: "barometer",
            color: .blue
        )
    }
}

struct WalkingFloorsInfoCard: View {
    let walkingFloors: Int
    
    var body: some View {
        InfoCard(
            title: "걸음 층수",
            value: "\(walkingFloors)",
            icon: "figure.stairs",
            color: walkingFloors > 0 ? .green : walkingFloors < 0 ? .red : .gray
        )
    }
}

struct StepsInfoCard: View {
    let steps: Int
    
    var body: some View {
        InfoCard(
            title: "총 걸음",
            value: formatSteps(steps),
            icon: "figure.walk",
            color: .orange
        )
    }
    
    private func formatSteps(_ steps: Int) -> String {
        if steps >= 1000 {
            return String(format: "%.1fK", Double(steps) / 1000.0)
        }
        return "\(steps)"
    }
}

// MARK: - Info Card Previews
struct InfoCard_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 16) {
            // 기본 카드들
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                InfoCard(title: "상대 고도", value: "15.2 m", icon: "arrow.up.arrow.down")
                InfoCard(title: "기압", value: "1010.3 hPa", icon: "barometer")
                InfoCard(title: "걸음 층수", value: "5", icon: "figure.stairs")
                InfoCard(title: "총 걸음", value: "1.2K", icon: "figure.walk")
            }
            
            Divider()
            
            // 전문 카드들
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                AltitudeInfoCard(altitude: 15.2)
                PressureInfoCard(pressure: 1010.3)
                WalkingFloorsInfoCard(walkingFloors: 5)
                StepsInfoCard(steps: 1234)
            }
            
            Divider()
            
            // 다양한 상태
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                AltitudeInfoCard(altitude: -6.1) // 지하
                WalkingFloorsInfoCard(walkingFloors: -2) // 내려감
                StepsInfoCard(steps: 5678) // 많은 걸음
                InfoCard(title: "속도", value: "4.2 km/h", icon: "speedometer", color: .purple)
            }
        }
        .padding()
        .previewLayout(.sizeThatFits)
        .previewDisplayName("Info Cards")
    }
}
