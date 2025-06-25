//
//  ColorComponent.swift
//  betinged
//
//  Created by taeni on 6/24/25.
//

import Foundation
import SwiftUI

// MARK: - ColorComponent 구조체
struct ColorComponent: Codable, Equatable, Hashable {
    let red: Double
    let green: Double
    let blue: Double
    let alpha: Double
    
    // MARK: - 생성자
    
    /// SwiftUI Color로부터 ColorComponent 생성
    init(color: Color) {
        let uiColor = UIColor(color)
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        
        self.red = Double(r)
        self.green = Double(g)
        self.blue = Double(b)
        self.alpha = Double(a)
    }
    
    /// RGBA 값으로 직접 생성
    init(red: Double, green: Double, blue: Double, alpha: Double = 1.0) {
        self.red = max(0, min(1, red))
        self.green = max(0, min(1, green))
        self.blue = max(0, min(1, blue))
        self.alpha = max(0, min(1, alpha))
    }
    
    /// Hex 문자열로부터 생성
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        
        self.red = Double(r) / 255.0
        self.green = Double(g) / 255.0
        self.blue = Double(b) / 255.0
        self.alpha = Double(a) / 255.0
    }
    
    /// HSB 값으로부터 생성
    init(hue: Double, saturation: Double, brightness: Double, alpha: Double = 1.0) {
        let color = Color(hue: hue, saturation: saturation, brightness: brightness, opacity: alpha)
        self.init(color: color)
    }
    
    // MARK: - 변환 메서드들
    
    /// SwiftUI Color로 변환
    var color: Color {
        Color(red: red, green: green, blue: blue, opacity: alpha)
    }
    
    /// UIColor로 변환
    var uiColor: UIColor {
        UIColor(red: red, green: green, blue: blue, alpha: alpha)
    }
    
    /// CGColor로 변환
    var cgColor: CGColor {
        CGColor(red: red, green: green, blue: blue, alpha: alpha)
    }
    
    /// Hex 문자열로 변환 (알파 포함 여부 선택 가능)
    func hexString(includeAlpha: Bool = false) -> String {
        let r = Int(red * 255)
        let g = Int(green * 255)
        let b = Int(blue * 255)
        let a = Int(alpha * 255)
        
        if includeAlpha {
            return String(format: "#%02X%02X%02X%02X", a, r, g, b)
        } else {
            return String(format: "#%02X%02X%02X", r, g, b)
        }
    }
    
    /// HSB 값으로 변환
    var hsbValues: (hue: Double, saturation: Double, brightness: Double) {
        let uiColor = UIColor(red: red, green: green, blue: blue, alpha: alpha)
        var h: CGFloat = 0
        var s: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        uiColor.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        return (Double(h), Double(s), Double(b))
    }
    
    // MARK: - 유틸리티 메서드들
    
    /// 밝기 조절 (0.0 ~ 2.0, 1.0이 원본)
    func adjustBrightness(_ factor: Double) -> ColorComponent {
        ColorComponent(
            red: min(1.0, red * factor),
            green: min(1.0, green * factor),
            blue: min(1.0, blue * factor),
            alpha: alpha
        )
    }
    
    /// 채도 조절 (0.0 ~ 2.0, 1.0이 원본)
    func adjustSaturation(_ factor: Double) -> ColorComponent {
        let hsb = hsbValues
        return ColorComponent(
            hue: hsb.hue,
            saturation: min(1.0, hsb.saturation * factor),
            brightness: hsb.brightness,
            alpha: alpha
        )
    }
    
    /// 알파 값 조절
    func withAlpha(_ newAlpha: Double) -> ColorComponent {
        ColorComponent(red: red, green: green, blue: blue, alpha: max(0, min(1, newAlpha)))
    }
    
    /// 보색 계산
    var complementary: ColorComponent {
        ColorComponent(red: 1.0 - red, green: 1.0 - green, blue: 1.0 - blue, alpha: alpha)
    }
    
    /// 그레이스케일 변환
    var grayscale: ColorComponent {
        let gray = 0.299 * red + 0.587 * green + 0.114 * blue
        return ColorComponent(red: gray, green: gray, blue: gray, alpha: alpha)
    }
    
    /// 색상의 밝기 계산 (0.0 ~ 1.0)
    var luminance: Double {
        0.299 * red + 0.587 * green + 0.114 * blue
    }
    
    /// 어두운 색상인지 판단
    var isDark: Bool {
        luminance < 0.5
    }
}

// MARK: - ColorStorable 프로토콜
/// Color 저장을 위한 공통 프로토콜
protocol ColorStorable {
    var colorData: Data { get set }
    var color: Color { get }
    mutating func updateColor(_ newColor: Color)
    mutating func updateColorComponent(_ component: ColorComponent)
}

// MARK: - ColorStorable 기본 구현
extension ColorStorable {
    /// 저장된 Data로부터 Color 복원
    var color: Color {
        if let component = try? JSONDecoder().decode(ColorComponent.self, from: colorData) {
            return component.color
        }
        return Color.clear
    }
    
    /// 저장된 Data로부터 ColorComponent 복원
    var ColorComponent: ColorComponent? {
        try? JSONDecoder().decode(ColorComponent.self, from: colorData)
    }
    
    /// SwiftUI Color로 업데이트
    mutating func updateColor(_ newColor: Color) {
        updateColorComponent(ColorComponent(color: newColor))
    }
    
    /// ColorComponent로 업데이트
    mutating func updateColorComponent(_ component: ColorComponent) {
        if let encoded = try? JSONEncoder().encode(component) {
            self.colorData = encoded
        }
    }
    
    /// Hex 문자열로 업데이트
    mutating func updateColor(hex: String) {
        updateColorComponent(ColorComponent(hex: hex))
    }
    
    /// Color를 Data로 변환하는 정적 헬퍼 메서드
    static func colorToData(_ color: Color) -> Data {
        if let colorData = try? JSONEncoder().encode(ColorComponent(color: color)) {
            return colorData
        }
        return Data()
    }
    
    /// ColorComponent를 Data로 변환하는 정적 헬퍼 메서드
    static func componentToData(_ component: ColorComponent) -> Data {
        if let colorData = try? JSONEncoder().encode(component) {
            return colorData
        }
        return Data()
    }
}

// MARK: - 사전 정의된 색상들
extension ColorComponent {
    static let clear = ColorComponent(red: 0, green: 0, blue: 0, alpha: 0)
    static let black = ColorComponent(red: 0, green: 0, blue: 0, alpha: 1)
    static let white = ColorComponent(red: 1, green: 1, blue: 1, alpha: 1)
    static let red = ColorComponent(red: 1, green: 0, blue: 0, alpha: 1)
    static let green = ColorComponent(red: 0, green: 1, blue: 0, alpha: 1)
    static let blue = ColorComponent(red: 0, green: 0, blue: 1, alpha: 1)
    static let yellow = ColorComponent(red: 1, green: 1, blue: 0, alpha: 1)
    static let orange = ColorComponent(red: 1, green: 0.5, blue: 0, alpha: 1)
    static let purple = ColorComponent(red: 0.5, green: 0, blue: 0.5, alpha: 1)
    static let pink = ColorComponent(red: 1, green: 0.75, blue: 0.8, alpha: 1)
    static let gray = ColorComponent(red: 0.5, green: 0.5, blue: 0.5, alpha: 1)
}

// MARK: - 사용 예시 구조체
struct ColorPreference: ColorStorable {
    var colorData: Data = Data()
    
    init(color: Color = .clear) {
        updateColor(color)
    }
    
    init(component: ColorComponent) {
        updateColorComponent(component)
    }
    
    init(hex: String) {
        updateColor(hex: hex)
    }
}
