//
//  PermissionRequestView.swift
//  deligtPIPUtils
//
//  Created by taeni on 10/13/25.
//

import SwiftUI

struct PermissionRequestView: View {
    @ObservedObject var manager: EventKitManager
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "calendar")
                .font(.system(size: 80))
                .foregroundStyle(.blue)
            
            Text("캘린더 접근 권한 필요")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("이벤트를 관리하려면 캘린더 접근 권한이 필요합니다.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
            
            Button {
                Task {
                    await manager.requestAccess()
                }
            } label: {
                Text("권한 허용하기")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.blue)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal)
            
            if let error = manager.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding()
            }
        }
        .padding()
    }
}
