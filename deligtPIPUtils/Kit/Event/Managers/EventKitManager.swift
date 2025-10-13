//
//  CalendarManager.swift
//  deligtPIPUtils
//
//  Created by taeni on 10/13/25.
//

import EventKit
import SwiftUI

@MainActor
final class EventKitManager: ObservableObject {
    @Published var events: [EKEvent] = []
    @Published var authorizationStatus: EKAuthorizationStatus = .notDetermined
    @Published var errorMessage: String?
    
    private let eventStore = EKEventStore()
    
    init() {
        checkAuthorizationStatus()
    }
    
    // 권한 상태 확인 (요청하지 않음)
    func checkAuthorizationStatus() {
        authorizationStatus = EKEventStore.authorizationStatus(for: .event)
    }
    
    // 권한 요청 (사용자가 명시적으로 호출할 때만)
    func requestAccess() async {
        do {
            let granted = try await eventStore.requestFullAccessToEvents()
            authorizationStatus = granted ? .fullAccess : .denied
            
            if granted {
                await loadEvents()
            }
        } catch {
            errorMessage = "권한 요청 실패: \(error.localizedDescription)"
        }
    }
    
    // 이벤트 로드
    func loadEvents() async {
        guard authorizationStatus == .fullAccess else { return }
        
        let calendars = eventStore.calendars(for: .event)
        let startDate = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
        let endDate = Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()
        
        let predicate = eventStore.predicateForEvents(
            withStart: startDate,
            end: endDate,
            calendars: calendars
        )
        
        events = eventStore.events(matching: predicate)
    }
    
    // 이벤트 생성
    func createEvent(title: String, startDate: Date, endDate: Date, notes: String? = nil) async -> Bool {
        guard authorizationStatus == .fullAccess else { return false }
        
        let event = EKEvent(eventStore: eventStore)
        event.title = title
        event.startDate = startDate
        event.endDate = endDate
        event.notes = notes
        event.calendar = eventStore.defaultCalendarForNewEvents
        
        do {
            try eventStore.save(event, span: .thisEvent)
            await loadEvents()
            return true
        } catch {
            errorMessage = "이벤트 생성 실패: \(error.localizedDescription)"
            return false
        }
    }
    
    // 이벤트 수정
    func updateEvent(_ event: EKEvent, title: String, startDate: Date, endDate: Date, notes: String? = nil) async -> Bool {
        guard authorizationStatus == .fullAccess else { return false }
        
        event.title = title
        event.startDate = startDate
        event.endDate = endDate
        event.notes = notes
        
        do {
            try eventStore.save(event, span: .thisEvent)
            await loadEvents()
            return true
        } catch {
            errorMessage = "이벤트 수정 실패: \(error.localizedDescription)"
            return false
        }
    }
    
    // 이벤트 삭제
    func deleteEvent(_ event: EKEvent) async -> Bool {
        guard authorizationStatus == .fullAccess else { return false }
        
        do {
            try eventStore.remove(event, span: .thisEvent)
            await loadEvents()
            return true
        } catch {
            errorMessage = "이벤트 삭제 실패: \(error.localizedDescription)"
            return false
        }
    }
}
