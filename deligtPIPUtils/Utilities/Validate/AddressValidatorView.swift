//
//  AddressValidatorView.swift
//  deligtPIPUtils
//
//  Created by taeni on 10/13/25.
//

import SwiftUI

struct AddressValidatorView: View {
    @State private var address: String = ""
    @State private var validationResult: KoreanAddressValidator.ValidationResult?
    @State private var selectedSampleIndex: Int?
    
    private let validator = KoreanAddressValidator()
    
    // 샘플 주소 데이터
    private let sampleAddresses = [
        "서울특별시 강남구 테헤란로 152",
        "서울 강남구 역삼동 737",
        "경기도 성남시 분당구 정자동 178-1",
        "부산광역시 해운대구 센텀중앙로 78",
        "인천광역시 동구 송림3.5동 123",
        "제주특별자치도 제주시 첨단로 242",
        "경북 포항시 남구 지곡로 80",
        "서울 종로구 사직로 161",
        "강원도 춘천시 중앙로 1",
        "대전 유성구 대학로 99"
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // 입력 섹션
                    inputSection
                    
                    // 결과 섹션
                    if let result = validationResult {
                        resultSection(result)
                    }
                    
                    // 샘플 주소 섹션
                    sampleAddressesSection
                }
                .padding()
            }
            .navigationTitle("한국 주소 검증기")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    // MARK: - 입력 섹션
    private var inputSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("주소 입력")
                .font(.headline)
            
            TextField("주소를 입력하세요", text: $address)
                .textFieldStyle(.roundedBorder)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(borderColor, lineWidth: 2)
                )
                .onChange(of: address) { _, newValue in
                    validateAddress(newValue)
                }
            
            HStack {
                Button(action: {
                    address = ""
                    validationResult = nil
                }) {
                    Label("초기화", systemImage: "xmark.circle.fill")
                        .foregroundColor(.red)
                }
                
                Spacer()
                
                Button(action: {
                    validateAddress(address)
                }) {
                    Label("검증", systemImage: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                }
            }
            .buttonStyle(.borderless)
        }
    }
    
    // MARK: - 결과 섹션
    private func resultSection(_ result: KoreanAddressValidator.ValidationResult) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("검증 결과")
                .font(.headline)
            
            VStack(spacing: 12) {
                // 유효성
                resultRow(
                    title: "유효성",
                    value: result.isValid ? "✓ 유효함" : "✗ 유효하지 않음",
                    color: result.isValid ? .green : .red
                )
                
                // 주소 타입
                resultRow(
                    title: "타입",
                    value: addressTypeString(result.type),
                    color: .blue
                )
                
                // 신뢰도
                resultRow(
                    title: "신뢰도",
                    value: String(format: "%.0f%%", result.confidence * 100),
                    color: confidenceColor(result.confidence)
                )
                
                // 매칭된 문자열
                if let matched = result.matchedString {
                    resultRow(
                        title: "매칭",
                        value: matched,
                        color: .purple
                    )
                }
                
                // 구성요소
                if let components = result.components {
                    componentsSection(components)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
    
    // MARK: - 구성요소 섹션
    private func componentsSection(_ components: KoreanAddressValidator.AddressComponents) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("주소 구성요소")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            Divider()
            
            if let sido = components.sido {
                componentRow(label: "시/도", value: sido)
            }
            if let sigungu = components.sigungu {
                componentRow(label: "시/군/구", value: sigungu)
            }
            if let dongmyeon = components.dongmyeon {
                componentRow(label: "읍/면/동", value: dongmyeon)
            }
            if let roadName = components.roadName {
                componentRow(label: "도로명", value: roadName)
            }
            if let buildingNumber = components.buildingNumber {
                componentRow(label: "건물번호", value: buildingNumber)
            }
            if let jibun = components.jibun {
                componentRow(label: "지번", value: jibun)
            }
        }
    }
    
    // MARK: - 샘플 주소 섹션
    private var sampleAddressesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("샘플 주소")
                .font(.headline)
            
            LazyVStack(spacing: 8) {
                ForEach(Array(sampleAddresses.enumerated()), id: \.offset) { index, sample in
                    Button(action: {
                        address = sample
                        selectedSampleIndex = index
                        validateAddress(sample)
                    }) {
                        HStack {
                            Text(sample)
                                .font(.subheadline)
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.leading)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(
                            selectedSampleIndex == index ?
                            Color.blue.opacity(0.1) : Color(.systemGray6)
                        )
                        .cornerRadius(8)
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Views
    private func resultRow(title: String, value: String, color: Color) -> some View {
        HStack {
            Text(title)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
                .foregroundColor(color)
        }
    }
    
    private func componentRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
        }
    }
    
    // MARK: - Helper Functions
    private func validateAddress(_ text: String) {
        validationResult = validator.validate(text)
    }
    
    private var borderColor: Color {
        guard let result = validationResult else {
            return Color.gray
        }
        return result.isValid ? Color.green : Color.red
    }
    
    private func addressTypeString(_ type: KoreanAddressValidator.AddressType) -> String {
        switch type {
        case .roadName: return "도로명 주소"
        case .jibun: return "지번 주소"
        case .partial: return "부분 주소"
        case .unknown: return "알 수 없음"
        }
    }
    
    private func confidenceColor(_ confidence: Double) -> Color {
        if confidence >= 0.7 { return .green }
        if confidence >= 0.4 { return .orange }
        return .red
    }
}

#Preview {
    AddressValidatorView()
}
