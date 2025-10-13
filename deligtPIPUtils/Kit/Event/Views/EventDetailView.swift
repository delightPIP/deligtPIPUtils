//
//  EventDetailView.swift
//  deligtPIPUtils
//
//  Created by taeni on 10/13/25.
//


import SwiftUI
import EventKit

struct EventDetailView: View {
    @ObservedObject var manager: EventKitManager
    let event: EKEvent
    
    @State private var isEditing = false
    @State private var showingDeleteAlert = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        List {
            Section("정보") {
                LabeledContent("제목", value: event.title ?? "제목 없음")
                LabeledContent("시작", value: event.startDate.formatted(date: .long, time: .shortened))
                LabeledContent("종료", value: event.endDate.formatted(date: .long, time: .shortened))
            }
            
            if let notes = event.notes, !notes.isEmpty {
                Section("메모") {
                    Text(notes)
                }
            }
            
            Section {
                Button(role: .destructive) {
                    showingDeleteAlert = true
                } label: {
                    Label("이벤트 삭제", systemImage: "trash")
                }
            }
        }
        .navigationTitle("이벤트 상세")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isEditing = true
                } label: {
                    Text("편집")
                }
            }
        }
        .sheet(isPresented: $isEditing) {
            EditEventView(manager: manager, event: event)
        }
        .alert("이벤트 삭제", isPresented: $showingDeleteAlert) {
            Button("취소", role: .cancel) { }
            Button("삭제", role: .destructive) {
                Task {
                    let success = await manager.deleteEvent(event)
                    if success {
                        dismiss()
                    }
                }
            }
        } message: {
            Text("이 이벤트를 삭제하시겠습니까?")
        }
    }
}
