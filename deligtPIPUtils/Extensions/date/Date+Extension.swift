//
//  Date+Extensions.swift
//  betinged
//
//  Created by taeni on 6/28/25.
//
import Foundation

// MARK: - Date Extensions
extension Date {
    
    // MARK: - 현재 시스템 정보
    
    /// 현재 시스템 날짜와 시간
    static var now: Date {
        return Date()
    }
    
    /// 오늘 날짜 (시간은 00:00:00)
    static var today: Date {
        return Calendar.current.startOfDay(for: Date())
    }
    
    /// 어제 날짜
    static var yesterday: Date {
        return Calendar.current.date(byAdding: .day, value: -1, to: today) ?? today
    }
    
    /// 내일 날짜
    static var tomorrow: Date {
        return Calendar.current.date(byAdding: .day, value: 1, to: today) ?? today
    }
    
    // MARK: - 요일 정보
    
    /// 현재 요일 (1=일요일, 7=토요일)
    var weekdayNumber: Int {
        return Calendar.current.component(.weekday, from: self)
    }
    
    /// 현재 요일을 Weekday enum으로 반환
    var weekday: Weekday {
        return Weekday.allCases.first { $0.rawValue == weekdayNumber } ?? .sunday
    }
    
    /// 요일 이름 (한국어)
    var weekdayName: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "EEEE"
        return formatter.string(from: self)
    }
    
    /// 요일 짧은 이름 (한국어)
    var weekdayShortName: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "E"
        return formatter.string(from: self)
    }
    
    // MARK: - 시간 정보
    
    /// 현재 시간 (24시간 형식)
    var hour: Int {
        return Calendar.current.component(.hour, from: self)
    }
    
    /// 현재 분
    var minute: Int {
        return Calendar.current.component(.minute, from: self)
    }
    
    /// 현재 초
    var second: Int {
        return Calendar.current.component(.second, from: self)
    }
    
    /// 분 단위로 변환된 시간 (예: 14:30 → 870분)
    var timeInMinutes: Int {
        return hour * 60 + minute
    }
    
    /// 30분 단위로 반올림된 시간
    var roundedToHalfHour: Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: self)
        
        let roundedMinute = (components.minute ?? 0) < 30 ? 0 : 30
        
        var newComponents = DateComponents()
        newComponents.year = components.year
        newComponents.month = components.month
        newComponents.day = components.day
        newComponents.hour = components.hour
        newComponents.minute = roundedMinute
        
        return calendar.date(from: newComponents) ?? self
    }
    
    /// 1시간 단위로 반올림된 시간
    var roundedToHour: Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour], from: self)
        
        return calendar.date(from: components) ?? self
    }
    
    // MARK: - 날짜 정보
    
    /// 년도
    var year: Int {
        return Calendar.current.component(.year, from: self)
    }
    
    /// 월 (1-12)
    var month: Int {
        return Calendar.current.component(.month, from: self)
    }
    
    /// 일 (1-31)
    var day: Int {
        return Calendar.current.component(.day, from: self)
    }
    
    /// 이번 주의 시작일 (일요일)
    var startOfWeek: Date {
        let calendar = Calendar.current
        return calendar.dateInterval(of: .weekOfYear, for: self)?.start ?? self
    }
    
    /// 이번 주의 종료일 (토요일)
    var endOfWeek: Date {
        let calendar = Calendar.current
        if let weekInterval = calendar.dateInterval(of: .weekOfYear, for: self) {
            return calendar.date(byAdding: .second, value: -1, to: weekInterval.end) ?? self
        }
        return self
    }
    
    /// 이번 달의 시작일
    var startOfMonth: Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: self)
        return calendar.date(from: components) ?? self
    }
    
    /// 이번 달의 마지막일
    var endOfMonth: Date {
        let calendar = Calendar.current
        if let nextMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth) {
            return calendar.date(byAdding: .second, value: -1, to: nextMonth) ?? self
        }
        return self
    }
    
    // MARK: - 포맷팅
    
    /// 기본 날짜 문자열 (2025-06-29)
    var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: self)
    }
    
    /// 기본 시간 문자열 (14:30)
    var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: self)
    }
    
    /// 기본 날짜시간 문자열 (2025-06-29 14:30)
    var dateTimeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter.string(from: self)
    }
    
    /// 한국어 날짜 문자열 (2025년 6월 29일)
    var koreanDateString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy년 M월 d일"
        return formatter.string(from: self)
    }
    
    /// 한국어 요일 포함 날짜 문자열 (2025년 6월 29일 일요일)
    var koreanDateWithWeekdayString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy년 M월 d일 EEEE"
        return formatter.string(from: self)
    }
    
    /// 상대적 시간 문자열 (방금 전, 1분 전, 2시간 전 등)
    var relativeTimeString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.unitsStyle = .full
        return formatter.localizedString(for: self, relativeTo: Date())
    }
    
    // MARK: - 비교 메서드
    
    /// 오늘인지 확인
    var isToday: Bool {
        return Calendar.current.isDateInToday(self)
    }
    
    /// 어제인지 확인
    var isYesterday: Bool {
        return Calendar.current.isDateInYesterday(self)
    }
    
    /// 내일인지 확인
    var isTomorrow: Bool {
        return Calendar.current.isDateInTomorrow(self)
    }
    
    /// 이번 주인지 확인
    var isThisWeek: Bool {
        return Calendar.current.isDate(self, equalTo: Date(), toGranularity: .weekOfYear)
    }
    
    /// 이번 달인지 확인
    var isThisMonth: Bool {
        return Calendar.current.isDate(self, equalTo: Date(), toGranularity: .month)
    }
    
    /// 올해인지 확인
    var isThisYear: Bool {
        return Calendar.current.isDate(self, equalTo: Date(), toGranularity: .year)
    }
    
    /// 특정 날짜와 같은 날인지 확인
    func isSameDay(as date: Date) -> Bool {
        return Calendar.current.isDate(self, inSameDayAs: date)
    }
    
    // MARK: - 유틸리티 메서드
    
    /// 특정 시간으로 설정 (년월일은 유지)
    func setting(hour: Int, minute: Int = 0, second: Int = 0) -> Date {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: self)
        components.hour = hour
        components.minute = minute
        components.second = second
        return calendar.date(from: components) ?? self
    }
    
    /// 날짜 더하기/빼기
    func adding(_ component: Calendar.Component, value: Int) -> Date {
        return Calendar.current.date(byAdding: component, value: value, to: self) ?? self
    }
    
    /// 두 날짜 사이의 차이 계산
    func difference(from date: Date, component: Calendar.Component) -> Int {
        return Calendar.current.dateComponents([component], from: date, to: self).value(for: component) ?? 0
    }
}

// MARK: - Calendar Extensions

extension Calendar {
    /// 한국 로케일 캘린더
    static var korean: Calendar {
        var calendar = Calendar.current
        calendar.locale = Locale(identifier: "ko_KR")
        return calendar
    }
}

// MARK: - Weekday Extension

extension Weekday {
    /// 현재 요일 반환
    static var today: Weekday {
        return Date.now.weekday
    }
}

// MARK: - 사용 예시 및 테스트

struct DateExtensionsExamples {
    static func printExamples() {
        let now = Date.now
        
        print("=== 현재 시스템 정보 ===")
        print("현재 시간: \(now.dateTimeString)")
        print("오늘: \(Date.today.dateString)")
        print("어제: \(Date.yesterday.dateString)")
        print("내일: \(Date.tomorrow.dateString)")
        
        print("\n=== 요일 정보 ===")
        print("요일 번호: \(now.weekdayNumber)")
        print("요일 enum: \(now.weekday)")
        print("요일 이름: \(now.weekdayName)")
        print("요일 짧은 이름: \(now.weekdayShortName)")
        
        print("\n=== 시간 정보 ===")
        print("시: \(now.hour)")
        print("분: \(now.minute)")
        print("초: \(now.second)")
        print("분 단위 시간: \(now.timeInMinutes)")
        print("30분 반올림: \(now.roundedToHalfHour.timeString)")
        print("1시간 반올림: \(now.roundedToHour.timeString)")
        
        print("\n=== 날짜 정보 ===")
        print("년: \(now.year)")
        print("월: \(now.month)")
        print("일: \(now.day)")
        print("이번 주 시작: \(now.startOfWeek.dateString)")
        print("이번 주 끝: \(now.endOfWeek.dateString)")
        
        print("\n=== 포맷팅 ===")
        print("기본 날짜: \(now.dateString)")
        print("기본 시간: \(now.timeString)")
        print("한국어 날짜: \(now.koreanDateString)")
        print("한국어 요일 포함: \(now.koreanDateWithWeekdayString)")
        print("상대 시간: \(now.relativeTimeString)")
        
        print("\n=== 비교 ===")
        print("오늘인가? \(now.isToday)")
        print("이번 주인가? \(now.isThisWeek)")
        print("이번 달인가? \(now.isThisMonth)")
        print("올해인가? \(now.isThisYear)")
    }
}

