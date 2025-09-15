//
//  EventKitSampleView.swift
//  deligtPIPUtils
//
//  Created by taeni on 9/13/25.
//

import SwiftUI
import EventKit

struct EventKitSampleView: View {
    @StateObject private var eventManager = EventKitManager.shared
    
    @State private var selectedTab = 0
    @State private var showingEventEdit = false
    @State private var showingCalendarChooser = false
    @State private var showingEventDetail: EKEvent?
    @State private var selectedCalendars: Set<EKCalendar> = []
    
    @State private var todayEvents: [EKEvent] = []
    @State private var todayReminders: [EKReminder] = []
    @State private var thisWeekEvents: [EKEvent] = []
    
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            TabView(selection: $selectedTab) {
                // 오늘 일정 탭
                todayEventsView
                    .tabItem {
                        Image(systemName: "calendar")
                        Text("오늘 일정")
                    }
                    .tag(0)
                
                // 이번 주 일정 탭
                weekEventsView
                    .tabItem {
                        Image(systemName: "calendar.badge.clock")
                        Text("이번 주")
                    }
                    .tag(1)
                
                // 리마인더 탭
                remindersView
                    .tabItem {
                        Image(systemName: "checklist")
                        Text("리마인더")
                    }
                    .tag(2)
                
                // 설정 탭
                settingsView
                    .tabItem {
                        Image(systemName: "gearshape")
                        Text("설정")
                    }
                    .tag(3)
            }
            .navigationTitle("EventKit 샘플")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { showingEventEdit = true }) {
                            Label("이벤트 추가", systemImage: "plus.circle")
                        }
                        
                        Button(action: { addQuickEvent() }) {
                            Label("빠른 이벤트 추가", systemImage: "bolt.circle")
                        }
                        
                        Button(action: { addQuickReminder() }) {
                            Label("빠른 리마인더 추가", systemImage: "bell.circle")
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .eventEditModal(
            eventStore: eventManager.eventStoreInstance,
            isPresented: $showingEventEdit,
            onEventSaved: { _ in
                loadTodayData()
                loadWeekData()
            }
        )
        .calendarChooserModal(
            eventStore: eventManager.eventStoreInstance,
            selectedCalendars: $selectedCalendars,
            isPresented: $showingCalendarChooser
        )
        .sheet(item: Binding<EKEventWrapper?>(
            get: { showingEventDetail.map(EKEventWrapper.init) },
            set: { showingEventDetail = $0?.event }
        )) { wrapper in
            EventViewController(
                event: wrapper.event,
                isPresented: .constant(true),
                onEventDeleted: { _ in
                    showingEventDetail = nil
                    loadTodayData()
                    loadWeekData()
                }
            )
        }
        .onAppear {
            loadInitialData()
        }
        .alert("오류", isPresented: .constant(errorMessage != nil)) {
            Button("확인") {
                errorMessage = nil
            }
        } message: {
            if let errorMessage = errorMessage {
                Text(errorMessage)
            }
        }
    }
    
    // MARK: - 오늘 일정 뷰
    
    private var todayEventsView: some View {
        VStack {
            if !eventManager.hasCalendarAccess {
                calendarPermissionView
            } else {
                List {
                    Section(header: Text("오늘 일정 (\(Date.today.koreanDateString))")) {
                        if todayEvents.isEmpty {
                            HStack {
                                Image(systemName: "calendar.badge.exclamationmark")
                                    .foregroundColor(.gray)
                                Text("오늘 일정이 없습니다")
                                    .foregroundColor(.gray)
                            }
                            .padding(.vertical, 8)
                        } else {
                            ForEach(todayEvents, id: \.eventIdentifier) { event in
                                EventRowView(event: event) {
                                    showingEventDetail = event
                                }
                            }
                        }
                    }
                }
                .refreshable {
                    loadTodayData()
                }
            }
        }
        .onAppear {
            if eventManager.hasCalendarAccess {
                loadTodayData()
            }
        }
    }
    
    // MARK: - 이번 주 일정 뷰
    
    private var weekEventsView: some View {
        VStack {
            if !eventManager.hasCalendarAccess {
                calendarPermissionView
            } else {
                List {
                    Section(header: Text("이번 주 일정")) {
                        if thisWeekEvents.isEmpty {
                            HStack {
                                Image(systemName: "calendar.badge.exclamationmark")
                                    .foregroundColor(.gray)
                                Text("이번 주 일정이 없습니다")
                                    .foregroundColor(.gray)
                            }
                            .padding(.vertical, 8)
                        } else {
                            ForEach(groupEventsByDate(thisWeekEvents), id: \.key) { dateGroup in
                                Section(header: Text(dateGroup.key)) {
                                    ForEach(dateGroup.value, id: \.eventIdentifier) { event in
                                        EventRowView(event: event) {
                                            showingEventDetail = event
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                .refreshable {
                    loadWeekData()
                }
            }
        }
        .onAppear {
            if eventManager.hasCalendarAccess {
                loadWeekData()
            }
        }
    }
    
    // MARK: - 리마인더 뷰
    
    private var remindersView: some View {
        VStack {
            if !eventManager.hasReminderAccess {
                reminderPermissionView
            } else {
                List {
                    Section(header: Text("오늘 마감 리마인더")) {
                        if todayReminders.isEmpty {
                            HStack {
                                Image(systemName: "checklist")
                                    .foregroundColor(.gray)
                                Text("오늘 마감인 리마인더가 없습니다")
                                    .foregroundColor(.gray)
                            }
                            .padding(.vertical, 8)
                        } else {
                            ForEach(todayReminders, id: \.calendarItemIdentifier) { reminder in
                                ReminderRowView(reminder: reminder) {
                                    completeReminder(reminder)
                                }
                            }
                        }
                    }
                }
                .refreshable {
                    await loadTodayReminders()
                }
            }
        }
        .task {
            if eventManager.hasReminderAccess {
                await loadTodayReminders()
            }
        }
    }
    
    // MARK: - 설정 뷰
    
    private var settingsView: some View {
        List {
            Section(header: Text("권한 상태")) {
                HStack {
                    Image(systemName: eventManager.hasCalendarAccess ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(eventManager.hasCalendarAccess ? .green : .red)
                    Text("캘린더 접근")
                    Spacer()
                    if !eventManager.hasCalendarAccess {
                        Button("권한 요청") {
                            Task {
                                await eventManager.requestCalendarAccess()
                            }
                        }
                    }
                }
                
                HStack {
                    Image(systemName: eventManager.hasReminderAccess ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(eventManager.hasReminderAccess ? .green : .red)
                    Text("리마인더 접근")
                    Spacer()
                    if !eventManager.hasReminderAccess {
                        Button("권한 요청") {
                            Task {
                                await eventManager.requestReminderAccess()
                            }
                        }
                    }
                }
            }
            
            Section(header: Text("캘린더 정보")) {
                if eventManager.hasCalendarAccess {
                    HStack {
                        Text("사용 가능한 캘린더")
                        Spacer()
                        Text("\(eventManager.calendars.count)개")
                            .foregroundColor(.secondary)
                    }
                    
                    Button("캘린더 선택") {
                        selectedCalendars = Set(eventManager.calendars)
                        showingCalendarChooser = true
                    }
                } else {
                    Text("캘린더 권한이 필요합니다")
                        .foregroundColor(.gray)
                }
            }
            
            Section(header: Text("테스트 기능")) {
                Button("샘플 이벤트 추가") {
                    addSampleEvent()
                }
                
                Button("샘플 리마인더 추가") {
                    Task {
                        await addSampleReminder()
                    }
                }
            }
        }
    }
    
    // MARK: - 권한 요청 뷰들
    
    private var calendarPermissionView: some View {
        VStack(spacing: 20) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 64))
                .foregroundColor(.orange)
            
            Text("캘린더 접근 권한이 필요합니다")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("일정을 보고 추가하기 위해서는 캘린더 접근 권한이 필요합니다.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            Button("권한 요청") {
                Task {
                    await eventManager.requestCalendarAccess()
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
    
    private var reminderPermissionView: some View {
        VStack(spacing: 20) {
            Image(systemName: "bell.badge.fill")
                .font(.system(size: 64))
                .foregroundColor(.orange)
            
            Text("리마인더 접근 권한이 필요합니다")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("리마인더를 보고 추가하기 위해서는 리마인더 접근 권한이 필요합니다.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            Button("권한 요청") {
                Task {
                    await eventManager.requestReminderAccess()
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
    
    // MARK: - 데이터 로드 메서드들
    
    private func loadInitialData() {
        if eventManager.hasCalendarAccess {
            loadTodayData()
            loadWeekData()
        }
        
        if eventManager.hasReminderAccess {
            Task {
                await loadTodayReminders()
            }
        }
    }
    
    private func loadTodayData() {
        todayEvents = eventManager.getTodayEvents()
    }
    
    private func loadWeekData() {
        thisWeekEvents = eventManager.getThisWeekEvents()
    }
    
    private func loadTodayReminders() async {
        todayReminders = await eventManager.getTodayReminders()
    }
    
    // MARK: - 이벤트/리마인더 관리 메서드들
    
    private func addQuickEvent() {
        Task {
            do {
                let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
                let eventTime = tomorrow.setting(hour: 9, minute: 0)
                
                try await eventManager.addQuickEvent(
                    title: "샘플 이벤트",
                    date: eventTime,
                    duration: 3600
                )
                
                loadTodayData()
                loadWeekData()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
    
    private func addQuickReminder() {
        Task {
            do {
                let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
                
                try await eventManager.addQuickReminder(
                    title: "샘플 리마인더",
                    dueDate: tomorrow
                )
                
                await loadTodayReminders()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
    
    private func addSampleEvent() {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        let startTime = tomorrow.setting(hour: 14, minute: 0)
        let endTime = tomorrow.setting(hour: 15, minute: 30)
        
        let event = eventManager.createEvent(
            title: "EventKit 샘플 미팅",
            startDate: startTime,
            endDate: endTime,
            location: "회의실 A",
            notes: "EventKit 프레임워크를 활용한 샘플 이벤트입니다."
        )
        
        do {
            try eventManager.saveEvent(event)
            loadTodayData()
            loadWeekData()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    private func addSampleReminder() async {
        let nextWeek = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: Date()) ?? Date()
        
        let reminder = eventManager.createReminder(
            title: "EventKit 샘플 리마인더",
            dueDate: nextWeek,
            notes: "EventKit 프레임워크를 활용한 샘플 리마인더입니다.",
            priority: 5
        )
        
        do {
            try eventManager.saveReminder(reminder)
            await loadTodayReminders()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    private func completeReminder(_ reminder: EKReminder) {
        do {
            try eventManager.completeReminder(reminder)
            Task {
                await loadTodayReminders()
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - 유틸리티 메서드들
    
    private func groupEventsByDate(_ events: [EKEvent]) -> [(key: String, value: [EKEvent])] {
        let grouped = Dictionary(grouping: events) { event in
            event.startDate.koreanDateWithWeekdayString
        }
        
        return grouped.sorted { first, second in
            let firstDate = first.value.first?.startDate ?? Date()
            let secondDate = second.value.first?.startDate ?? Date()
            return firstDate < secondDate
        }
    }
}

// MARK: - 개별 행 뷰들

struct EventRowView: View {
    let event: EKEvent
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Rectangle()
                    .fill(Color(event.calendar.cgColor))
                    .frame(width: 4)
                    .cornerRadius(2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(event.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                    
                    HStack {
                        Image(systemName: "clock")
                            .foregroundColor(.secondary)
                            .font(.caption)
                        
                        Text("\(event.startDate.timeString) - \(event.endDate.timeString)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if let location = event.location, !location.isEmpty {
                        HStack {
                            Image(systemName: "location")
                                .foregroundColor(.secondary)
                                .font(.caption)
                            
                            Text(location)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ReminderRowView: View {
    let reminder: EKReminder
    let onComplete: () -> Void
    
    var body: some View {
        HStack {
            Button(action: onComplete) {
                Image(systemName: reminder.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(reminder.isCompleted ? .green : .gray)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(reminder.title)
                    .font(.headline)
                    .strikethrough(reminder.isCompleted)
                    .foregroundColor(reminder.isCompleted ? .secondary : .primary)
                
                if let dueDate = reminder.dueDateComponents?.date {
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundColor(.secondary)
                            .font(.caption)
                        
                        Text(dueDate.koreanDateWithWeekdayString)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                if let notes = reminder.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
            
            Spacer()
            
            if reminder.priority > 0 {
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundColor(.orange)
                    .font(.caption)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - 헬퍼 구조체

struct EKEventWrapper: Identifiable {
    let id = UUID()
    let event: EKEvent
}

// MARK: - Preview

#Preview {
    EventKitSampleView()
}
