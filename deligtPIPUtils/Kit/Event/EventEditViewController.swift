//
//  EventEditViewController.swift
//  deligtPIPUtils
//
//  Created by taeni on 9/13/25.
//

import SwiftUI
import EventKit
import EventKitUI

// MARK: - EventEditViewController (이벤트 편집)
struct EventEditViewController: UIViewControllerRepresentable {
    let eventStore: EKEventStore
    let event: EKEvent?
    @Binding var isPresented: Bool
    
    var onEventSaved: ((EKEvent) -> Void)?
    var onEventDeleted: ((EKEvent) -> Void)?
    
    init(
        eventStore: EKEventStore,
        event: EKEvent? = nil,
        isPresented: Binding<Bool>,
        onEventSaved: ((EKEvent) -> Void)? = nil,
        onEventDeleted: ((EKEvent) -> Void)? = nil
    ) {
        self.eventStore = eventStore
        self.event = event
        self._isPresented = isPresented
        self.onEventSaved = onEventSaved
        self.onEventDeleted = onEventDeleted
    }
    
    func makeUIViewController(context: Context) -> UINavigationController {
        let eventEditViewController = EKEventEditViewController()
        eventEditViewController.eventStore = eventStore
        eventEditViewController.event = event
        eventEditViewController.editViewDelegate = context.coordinator
        
        return UINavigationController(rootViewController: eventEditViewController)
    }
    
    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {
        // 업데이트가 필요한 경우 여기에 구현
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, EKEventEditViewDelegate {
        var parent: EventEditViewController
        
        init(_ parent: EventEditViewController) {
            self.parent = parent
        }
        
        func eventEditViewController(
            _ controller: EKEventEditViewController,
            didCompleteWith action: EKEventEditViewAction
        ) {
            switch action {
            case .canceled:
                break
            case .saved:
                if let event = controller.event {
                    parent.onEventSaved?(event)
                }
            case .deleted:
                if let event = controller.event {
                    parent.onEventDeleted?(event)
                }
            @unknown default:
                break
            }
            
            parent.isPresented = false
        }
    }
}

// MARK: - EventViewController (이벤트 보기)
struct EventViewController: UIViewControllerRepresentable {
    let event: EKEvent
    @Binding var isPresented: Bool
    
    var onEventEdited: ((EKEvent) -> Void)?
    var onEventDeleted: ((EKEvent) -> Void)?
    
    func makeUIViewController(context: Context) -> UINavigationController {
        let eventViewController = EKEventViewController()
        eventViewController.event = event
        eventViewController.delegate = context.coordinator
        eventViewController.allowsEditing = true
        eventViewController.allowsCalendarPreview = true
        
        return UINavigationController(rootViewController: eventViewController)
    }
    
    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {
        // 업데이트가 필요한 경우 여기에 구현
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, EKEventViewDelegate {
        var parent: EventViewController
        
        init(_ parent: EventViewController) {
            self.parent = parent
        }
        
        func eventViewController(
            _ controller: EKEventViewController,
            didCompleteWith action: EKEventViewAction
        ) {
            switch action {
            case .done:
                break
            case .responded:
                break
            case .deleted:
                parent.onEventDeleted?(controller.event)
            @unknown default:
                break
            }
            
            parent.isPresented = false
        }
    }
}

// MARK: - CalendarChooserViewController (캘린더 선택)
struct CalendarChooserViewController: UIViewControllerRepresentable {
    let eventStore: EKEventStore
    let entityType: EKEntityType
    @Binding var selectedCalendars: Set<EKCalendar>
    @Binding var isPresented: Bool
    
    let selectionStyle: EKCalendarChooserSelectionStyle
    
    init(
        eventStore: EKEventStore,
        entityType: EKEntityType = .event,
        selectedCalendars: Binding<Set<EKCalendar>>,
        isPresented: Binding<Bool>,
        selectionStyle: EKCalendarChooserSelectionStyle = .multiple
    ) {
        self.eventStore = eventStore
        self.entityType = entityType
        self._selectedCalendars = selectedCalendars
        self._isPresented = isPresented
        self.selectionStyle = selectionStyle
    }
    
    func makeUIViewController(context: Context) -> UINavigationController {
        let chooser = EKCalendarChooser(
            selectionStyle: selectionStyle,
            displayStyle: .allCalendars,
            entityType: entityType,
            eventStore: eventStore
        )
        
        chooser.selectedCalendars = selectedCalendars
        chooser.delegate = context.coordinator
        chooser.showsDoneButton = true
        chooser.showsCancelButton = true
        
        return UINavigationController(rootViewController: chooser)
    }
    
    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {
        if let chooser = uiViewController.topViewController as? EKCalendarChooser {
            chooser.selectedCalendars = selectedCalendars
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, EKCalendarChooserDelegate {
        var parent: CalendarChooserViewController
        
        init(_ parent: CalendarChooserViewController) {
            self.parent = parent
        }
        
        func calendarChooserDidFinish(_ calendarChooser: EKCalendarChooser) {
            parent.selectedCalendars = calendarChooser.selectedCalendars
            parent.isPresented = false
        }
        
        func calendarChooserDidCancel(_ calendarChooser: EKCalendarChooser) {
            parent.isPresented = false
        }
    }
}

// MARK: - SwiftUI 편의 확장

extension View {
    /// 이벤트 편집 모달 표시
    func eventEditModal(
        eventStore: EKEventStore,
        event: EKEvent? = nil,
        isPresented: Binding<Bool>,
        onEventSaved: ((EKEvent) -> Void)? = nil,
        onEventDeleted: ((EKEvent) -> Void)? = nil
    ) -> some View {
        self.fullScreenCover(isPresented: isPresented) {
            EventEditViewController(
                eventStore: eventStore,
                event: event,
                isPresented: isPresented,
                onEventSaved: onEventSaved,
                onEventDeleted: onEventDeleted
            )
        }
    }
    
    /// 이벤트 상세보기 모달 표시
    func eventViewModal(
        event: EKEvent,
        isPresented: Binding<Bool>,
        onEventEdited: ((EKEvent) -> Void)? = nil,
        onEventDeleted: ((EKEvent) -> Void)? = nil
    ) -> some View {
        self.fullScreenCover(isPresented: isPresented) {
            EventViewController(
                event: event,
                isPresented: isPresented,
                onEventEdited: onEventEdited,
                onEventDeleted: onEventDeleted
            )
        }
    }
    
    /// 캘린더 선택 모달 표시
    func calendarChooserModal(
        eventStore: EKEventStore,
        entityType: EKEntityType = .event,
        selectedCalendars: Binding<Set<EKCalendar>>,
        isPresented: Binding<Bool>,
        selectionStyle: EKCalendarChooserSelectionStyle = .multiple
    ) -> some View {
        self.sheet(isPresented: isPresented) {
            CalendarChooserViewController(
                eventStore: eventStore,
                entityType: entityType,
                selectedCalendars: selectedCalendars,
                isPresented: isPresented,
                selectionStyle: selectionStyle
            )
        }
    }
}
