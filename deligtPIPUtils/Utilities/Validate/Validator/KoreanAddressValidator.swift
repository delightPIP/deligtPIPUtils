//
//  KoreanAddressValidator.swift
//  deligtPIPUtils
//
//  Created by taeni on 10/13/25.
//

import Foundation

/// Swift 6.0 호환 - Sendable 프로토콜 준수
struct KoreanAddressValidator: Sendable {
    
    // MARK: - 주소 타입
    enum AddressType: Sendable {
        case roadName      // 도로명 주소
        case jibun         // 지번 주소
        case partial       // 부분 주소
        case unknown       // 인식 불가
    }
    
    // MARK: - 검증 결과
    struct ValidationResult: Sendable {
        let isValid: Bool
        let type: AddressType
        let components: AddressComponents?
        let matchedString: String?
        let confidence: Double // 0.0 ~ 1.0
    }
    
    // MARK: - 주소 구성요소
    struct AddressComponents: Sendable {
        let sido: String?           // 시/도
        let sigungu: String?        // 시/군/구
        let dongmyeon: String?      // 동/면/읍
        let roadName: String?       // 도로명
        let buildingNumber: String? // 건물번호
        let jibun: String?         // 지번
    }
    
    // MARK: - 정규표현식 패턴 (불변, Sendable)
    private struct Patterns {
        static let sido = "(서울특별시|서울|부산광역시|부산|대구광역시|대구|인천광역시|인천|광주광역시|광주|대전광역시|대전|울산광역시|울산|세종특별자치시|세종|경기도|경기|강원특별자치도|강원도|강원|충청북도|충북|충청남도|충남|전북특별자치도|전라북도|전북|전라남도|전남|경상북도|경북|경상남도|경남|제주특별자치도|제주도|제주)"
        
        static let sigungu = "([가-힣0-9]+[시군구])"
        
        static let dongmyeon = "([가-힣0-9\\.]+[읍면동로가리])"
        
        static let roadName = "([가-힣0-9]+[로길])"
        
        static let buildingNumber = "(\\d+(?:-\\d+)?)"
        
        static let jibun = "(산?\\s*\\d+(?:-\\d+)?(?:번지)?)"
    }
    
    // MARK: - 주소 검증
    func validate(_ address: String) -> ValidationResult {
        let trimmed = address.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmed.isEmpty else {
            return ValidationResult(
                isValid: false,
                type: .unknown,
                components: nil,
                matchedString: nil,
                confidence: 0.0
            )
        }
        
        // 도로명 주소 체크
        if let result = checkRoadNameAddress(trimmed) {
            return result
        }
        
        // 지번 주소 체크
        if let result = checkJibunAddress(trimmed) {
            return result
        }
        
        // 부분 주소 체크 (시/도, 구 등만 있는 경우)
        if let result = checkPartialAddress(trimmed) {
            return result
        }
        
        return ValidationResult(
            isValid: false,
            type: .unknown,
            components: nil,
            matchedString: nil,
            confidence: 0.0
        )
    }
    
    // MARK: - 도로명 주소 검증
    private func checkRoadNameAddress(_ address: String) -> ValidationResult? {
        // 도로명 주소 패턴: 시도 + 시군구 + 도로명 + 건물번호
        let pattern = "\\s*\(Patterns.sido)?\\s*\(Patterns.sigungu)?\\s*\(Patterns.roadName)\\s*\(Patterns.buildingNumber)"
        
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
            return nil
        }
        
        let range = NSRange(address.startIndex..., in: address)
        guard let match = regex.firstMatch(in: address, options: [], range: range) else {
            return nil
        }
        
        let matchedString = (address as NSString).substring(with: match.range)
        
        // 구성요소 추출
        var sido: String?
        var sigungu: String?
        var roadName: String?
        var buildingNumber: String?
        
        // 각 캡처 그룹 추출
        if match.numberOfRanges > 1, match.range(at: 1).location != NSNotFound {
            sido = (address as NSString).substring(with: match.range(at: 1))
        }
        if match.numberOfRanges > 2, match.range(at: 2).location != NSNotFound {
            sigungu = (address as NSString).substring(with: match.range(at: 2))
        }
        if match.numberOfRanges > 3, match.range(at: 3).location != NSNotFound {
            roadName = (address as NSString).substring(with: match.range(at: 3))
        }
        if match.numberOfRanges > 4, match.range(at: 4).location != NSNotFound {
            buildingNumber = (address as NSString).substring(with: match.range(at: 4))
        }
        
        // 신뢰도 계산 (구성요소가 많을수록 높음)
        var confidence = 0.5
        if sido != nil { confidence += 0.15 }
        if sigungu != nil { confidence += 0.15 }
        if roadName != nil { confidence += 0.1 }
        if buildingNumber != nil { confidence += 0.1 }
        
        let components = AddressComponents(
            sido: sido,
            sigungu: sigungu,
            dongmyeon: nil,
            roadName: roadName,
            buildingNumber: buildingNumber,
            jibun: nil
        )
        
        return ValidationResult(
            isValid: true,
            type: .roadName,
            components: components,
            matchedString: matchedString,
            confidence: confidence
        )
    }
    
    // MARK: - 지번 주소 검증
    private func checkJibunAddress(_ address: String) -> ValidationResult? {
        // 지번 주소 패턴: 시도 + 시군구 + 동면 + 지번
        let pattern = "\\s*\(Patterns.sido)?\\s*\(Patterns.sigungu)?\\s*\(Patterns.dongmyeon)?\\s*\(Patterns.jibun)"
        
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
            return nil
        }
        
        let range = NSRange(address.startIndex..., in: address)
        guard let match = regex.firstMatch(in: address, options: [], range: range) else {
            return nil
        }
        
        let matchedString = (address as NSString).substring(with: match.range)
        
        // 구성요소 추출
        var sido: String?
        var sigungu: String?
        var dongmyeon: String?
        var jibun: String?
        
        if match.numberOfRanges > 1, match.range(at: 1).location != NSNotFound {
            sido = (address as NSString).substring(with: match.range(at: 1))
        }
        if match.numberOfRanges > 2, match.range(at: 2).location != NSNotFound {
            sigungu = (address as NSString).substring(with: match.range(at: 2))
        }
        if match.numberOfRanges > 3, match.range(at: 3).location != NSNotFound {
            dongmyeon = (address as NSString).substring(with: match.range(at: 3))
        }
        if match.numberOfRanges > 4, match.range(at: 4).location != NSNotFound {
            jibun = (address as NSString).substring(with: match.range(at: 4))
        }
        
        var confidence = 0.5
        if sido != nil { confidence += 0.15 }
        if sigungu != nil { confidence += 0.15 }
        if dongmyeon != nil { confidence += 0.1 }
        if jibun != nil { confidence += 0.1 }
        
        let components = AddressComponents(
            sido: sido,
            sigungu: sigungu,
            dongmyeon: dongmyeon,
            roadName: nil,
            buildingNumber: nil,
            jibun: jibun
        )
        
        return ValidationResult(
            isValid: true,
            type: .jibun,
            components: components,
            matchedString: matchedString,
            confidence: confidence
        )
    }
    
    // MARK: - 부분 주소 검증
    private func checkPartialAddress(_ address: String) -> ValidationResult? {
        // 시도 또는 시군구만 있는 경우
        let pattern = "\\s*\(Patterns.sido)\\s*\(Patterns.sigungu)?"
        
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
            return nil
        }
        
        let range = NSRange(address.startIndex..., in: address)
        guard let match = regex.firstMatch(in: address, options: [], range: range) else {
            return nil
        }
        
        let matchedString = (address as NSString).substring(with: match.range)
        
        var sido: String?
        var sigungu: String?
        
        if match.numberOfRanges > 1, match.range(at: 1).location != NSNotFound {
            sido = (address as NSString).substring(with: match.range(at: 1))
        }
        if match.numberOfRanges > 2, match.range(at: 2).location != NSNotFound {
            sigungu = (address as NSString).substring(with: match.range(at: 2))
        }
        
        let components = AddressComponents(
            sido: sido,
            sigungu: sigungu,
            dongmyeon: nil,
            roadName: nil,
            buildingNumber: nil,
            jibun: nil
        )
        
        return ValidationResult(
            isValid: true,
            type: .partial,
            components: components,
            matchedString: matchedString,
            confidence: 0.3
        )
    }
}
