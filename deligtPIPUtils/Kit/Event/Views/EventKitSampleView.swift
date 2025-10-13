//
//  EventListViewView.swift
//  deligtPIPUtils
//
//  Created by taeni on 10/13/25.
//

import SwiftUI

struct EventListViewView: View {
    @StateObject private var manager = EventKitManager()
        @State private var showingAddEvent = false
        
        var body: some View {
            NavigationStack {
                Group {
                    switch manager.authorizationStatus {
                    case .notDetermined, .denied, .restricted:
                        PermissionRequestView(manager: manager)
                    case .fullAccess, .writeOnly:
                        EventListView(manager: manager, showingAddEvent: $showingAddEvent)
                    @unknown default:
                        Text("알 수 없는 권한 상태")
                    }
                }
                .navigationTitle("캘린더 이벤트")
                .sheet(isPresented: $showingAddEvent) {
                    AddEventView(manager: manager)
                }
            }
        }
}

#Preview {
    EventListViewView()
}
