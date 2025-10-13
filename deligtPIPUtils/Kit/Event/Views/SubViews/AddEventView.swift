//
//  AddEventView.swift
//  deligtPIPUtils
//
//  Created by taeni on 10/13/25.
//


import SwiftUI

struct AddEventView: View {
    @ObservedObject var manager: EventKitManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var title = ""
    @State private var startDate = Date()
    @State private var endDate = Date().addingTimeInterval(3600)
    @State private var notes = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("이벤트 정보") {
                    TextField("제목", text: $title)
                    
                    DatePicker("시작", selection: $startDate)
                    DatePicker("종료", selection: $endDate)
                }
                
                Section("메모") {
                    TextEditor(text: $notes)
                        .frame(height: 100)
                }
            }
            .navigationTitle("새 이벤트")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("저장") {
                        Task {
                            let success = await manager.createEvent(
                                title: title,
                                startDate: startDate,
                                endDate: endDate,
                                notes: notes.isEmpty ? nil : notes
                            )
                            if success {
                                dismiss()
                            }
                        }
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }
}
