//
//  EventKitManager.swift
//  deligtPIPUtils
//
//  Created by taeni on 9/13/25.
//

import EventKit
import Foundation

// MARK: - EventKitManager 클래스
/// EventKit을 관리하는 싱글톤 클래스
@MainActor
class EventKitManager: ObservableObject {
    static let shared = EventKitManager()
    
    private let eventStore = EKEventStore()
    
    @Published var hasCalendarAccess = false
    @Published var hasReminderAccess = false
    @Published var calendars: [EKCalendar] = []
    @Published var reminderLists: [EKCalendar] = []
    
    private init() {
        checkCurrentAuthorization()
    }
    
    // MARK: - 권한 확인
    
    /// 현재 권한 상태 확인
    private func checkCurrentAuthorization() {
        let eventStatus = EKEventStore.authorizationStatus(for: .event)
        let reminderStatus = EKEventStore.authorizationStatus(for: .reminder)
        
        hasCalendarAccess = (eventStatus == .fullAccess || eventStatus == .writeOnly)
        hasReminderAccess = (reminderStatus == .fullAccess || reminderStatus == .writeOnly)
        
        if hasCalendarAccess {
            loadCalendars()
        }
        
        if hasReminderAccess {
            loadReminderLists()
        }
    }
    
    /// 캘린더 접근 권한 요청
    func requestCalendarAccess() async -> Bool {
        do {
            let granted = try await eventStore.requestFullAccessToEvents()
            await MainActor.run {
                hasCalendarAccess = granted
                if granted {
                    loadCalendars()
                }
            }
            return granted
        } catch {
            print("캘린더 권한 요청 실패: \(error)")
            return false
        }
    }
    
    /// 리마인더 접근 권한 요청
    func requestReminderAccess() async -> Bool {
        do {
            let granted = try await eventStore.requestFullAccessToReminders()
            await MainActor.run {
                hasReminderAccess = granted
                if granted {
                    loadReminderLists()
                }
            }
            return granted
        } catch {
            print("리마인더 권한 요청 실패: \(error)")
            return false
        }
    }
    
    // MARK: - 데이터 로드
    
    /// 사용 가능한 캘린더 목록 로드
    private func loadCalendars() {
        calendars = eventStore.calendars(for: .event)
            .filter { $0.allowsContentModifications }
            .sorted { $0.title < $1.title }
    }
    
    /// 사용 가능한 리마인더 목록 로드
    private func loadReminderLists() {
        reminderLists = eventStore.calendars(for: .reminder)
            .filter { $0.allowsContentModifications }
            .sorted { $0.title < $1.title }
    }
    
    // MARK: - 이벤트 관리
    
    /// 새 이벤트 생성
    func createEvent(
        title: String,
        startDate: Date,
        endDate: Date,
        location: String? = nil,
        notes: String? = nil,
        calendar: EKCalendar? = nil
    ) -> EKEvent {
        let event = EKEvent(eventStore: eventStore)
        event.title = title
        event.startDate = startDate
        event.endDate = endDate
        event.location = location
        event.notes = notes
        event.calendar = calendar ?? eventStore.defaultCalendarForNewEvents
        
        return event
    }
    
    /// 이벤트 저장
    func saveEvent(_ event: EKEvent) throws {
        try eventStore.save(event, span: .thisEvent)
    }
    
    /// 특정 기간의 이벤트 가져오기
    func getEvents(from startDate: Date, to endDate: Date) -> [EKEvent] {
        let predicate = eventStore.predicateForEvents(
            withStart: startDate,
            end: endDate,
            calendars: nil
        )
        return eventStore.events(matching: predicate)
    }
    
    /// 오늘의 이벤트 가져오기
    func getTodayEvents() -> [EKEvent] {
        let today = Date.today
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today) ?? today
        return getEvents(from: today, to: tomorrow)
    }
    
    /// 이번 주 이벤트 가져오기
    func getThisWeekEvents() -> [EKEvent] {
        let startOfWeek = Date.today.startOfWeek
        let endOfWeek = Date.today.endOfWeek
        return getEvents(from: startOfWeek, to: endOfWeek)
    }
    
    // MARK: - 리마인더 관리
    
    /// 새 리마인더 생성
    func createReminder(
        title: String,
        dueDate: Date? = nil,
        notes: String? = nil,
        priority: Int = 0,
        calendar: EKCalendar? = nil
    ) -> EKReminder {
        let reminder = EKReminder(eventStore: eventStore)
        reminder.title = title
        reminder.notes = notes
        reminder.priority = priority
        reminder.calendar = calendar ?? eventStore.defaultCalendarForNewReminders()
        
        if let dueDate = dueDate {
            reminder.dueDateComponents = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute],
                from: dueDate
            )
        }
        
        return reminder
    }
    
    /// 리마인더 저장
    func saveReminder(_ reminder: EKReminder) throws {
        try eventStore.save(reminder, commit: true)
    }
    
    /// 완료되지 않은 리마인더 가져오기
    func getIncompleteReminders() async -> [EKReminder] {
        return await withCheckedContinuation { continuation in
            let predicate = eventStore.predicateForIncompleteReminders(
                withDueDateStarting: nil,
                ending: nil,
                calendars: nil
            )
            
            eventStore.fetchReminders(matching: predicate) { reminders in
                continuation.resume(returning: reminders ?? [])
            }
        }
    }
    
    /// 오늘 마감인 리마인더 가져오기
    func getTodayReminders() async -> [EKReminder] {
        let today = Date.today
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today) ?? today
        
        return await withCheckedContinuation { continuation in
            let predicate = eventStore.predicateForIncompleteReminders(
                withDueDateStarting: today,
                ending: tomorrow,
                calendars: nil
            )
            
            eventStore.fetchReminders(matching: predicate) { reminders in
                continuation.resume(returning: reminders ?? [])
            }
        }
    }
    
    /// 리마인더 완료 처리
    func completeReminder(_ reminder: EKReminder) throws {
        reminder.isCompleted = true
        reminder.completionDate = Date()
        try eventStore.save(reminder, commit: true)
    }
    
    // MARK: - 편의 메서드
    
    /// 기본 캘린더 가져오기
    var defaultCalendar: EKCalendar? {
        return eventStore.defaultCalendarForNewEvents
    }
    
    /// 기본 리마인더 목록 가져오기
    var defaultReminderList: EKCalendar? {
        return eventStore.defaultCalendarForNewReminders()
    }
    
    /// EventStore 인스턴스 반환 (UI에서 사용)
    var eventStoreInstance: EKEventStore {
        return eventStore
    }
    
    /// 빠른 이벤트 추가
    func addQuickEvent(
        title: String,
        date: Date,
        duration: TimeInterval = 3600 // 기본 1시간
    ) async throws {
        if !hasReminderAccess {
            let granted = await requestReminderAccess()
            guard granted else {
                throw EventKitError.accessDenied
            }
        }
        
        let endDate = date.addingTimeInterval(duration)
        let event = createEvent(
            title: title,
            startDate: date,
            endDate: endDate
        )
        
        try saveEvent(event)
    }
    
    /// 빠른 리마인더 추가
    func addQuickReminder(
        title: String,
        dueDate: Date? = nil
    ) async throws {
        // 권한이 없는 경우 권한 요청
        if !hasReminderAccess {
            let granted = await requestReminderAccess()
            guard granted else {
                throw EventKitError.accessDenied
            }
        }
        
        let reminder = createReminder(
            title: title,
            dueDate: dueDate
        )
        
        try saveReminder(reminder)
    }
}
