//
//  EventKitError.swift
//  deligtPIPUtils
//
//  Created by taeni on 9/13/25.
//

import Foundation

// MARK: - EventKitError
enum EventKitError: LocalizedError {
    case accessDenied
    case saveFailed
    case eventNotFound
    
    var errorDescription: String? {
        switch self {
        case .accessDenied:
            return "캘린더 또는 리마인더 접근 권한이 없습니다."
        case .saveFailed:
            return "저장에 실패했습니다."
        case .eventNotFound:
            return "이벤트를 찾을 수 없습니다."
        }
    }
}
