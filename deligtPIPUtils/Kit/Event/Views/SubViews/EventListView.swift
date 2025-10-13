//
//  EventListView.swift
//  deligtPIPUtils
//
//  Created by taeni on 10/13/25.
//


import SwiftUI

struct EventListView: View {
    @ObservedObject var manager: EventKitManager
    @Binding var showingAddEvent: Bool
    
    var body: some View {
        List {
            ForEach(manager.events, id: \.eventIdentifier) { event in
                NavigationLink {
                    EventDetailView(manager: manager, event: event)
                } label: {
                    EventRow(event: event)
                }
            }
        }
        .overlay {
            if manager.events.isEmpty {
                ContentUnavailableView(
                    "이벤트 없음",
                    systemImage: "calendar",
                    description: Text("새로운 이벤트를 추가해보세요")
                )
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingAddEvent = true
                } label: {
                    Image(systemName: "plus")
                }
            }
            
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    Task {
                        await manager.loadEvents()
                    }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
            }
        }
        .task {
            await manager.loadEvents()
        }
    }
}
