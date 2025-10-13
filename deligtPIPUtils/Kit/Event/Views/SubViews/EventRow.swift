//
//  EventRow.swift
//  deligtPIPUtils
//
//  Created by taeni on 10/13/25.
//


import SwiftUI
import EventKit

struct EventRow: View {
    let event: EKEvent
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(event.title ?? "제목 없음")
                .font(.headline)
            
            HStack {
                Image(systemName: "clock")
                    .font(.caption)
                Text(event.startDate.formatted(date: .abbreviated, time: .shortened))
                    .font(.subheadline)
            }
            .foregroundStyle(.secondary)
            
            if let notes = event.notes, !notes.isEmpty {
                Text(notes)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 4)
    }
}