//
//  TransportationType.swift
//  deligtPIPUtils
//
//  Created by taeni on 9/15/25.
//

import SwiftUI

// MARK: - Transport Type Enum
enum TransportationType: String, CaseIterable {
    case unknown = "❓ 분석 중"
    case stairs = "🚶‍♂️ 계단"
    case elevator = "🛗 엘리베이터"
    case escalator = "⚡ 에스컬레이터"
    case stationary = "🚫 정지"
    case walking = "🚶 평지 걷기"
    
    var color: Color {
        switch self {
        case .unknown: return .gray
        case .stairs: return .green
        case .elevator: return .blue
        case .escalator: return .orange
        case .stationary: return .secondary
        case .walking: return .cyan
        }
    }
    
    var description: String {
        switch self {
        case .unknown:
            return "센서 데이터를 분석하여 이동 방법을 판단 중입니다."
        case .stairs:
            return "걸음 감지와 층수 카운트가 모두 확인되어 계단으로 판단됩니다."
        case .elevator:
            return "정적 상태에서 고도 변화가 감지되어 엘리베이터로 판단됩니다."
        case .escalator:
            return "걸음은 감지되지만 층수 카운트가 없어 에스컬레이터로 판단됩니다."
        case .stationary:
            return "고도 변화가 거의 없어 정지 상태로 판단됩니다."
        case .walking:
            return "평지에서 걷는 것으로 판단됩니다."
        }
    }
}
