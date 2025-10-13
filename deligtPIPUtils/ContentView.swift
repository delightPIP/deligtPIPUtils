//
//  ContentView.swift
//  beTinged
//
//  Created by taeni on 7/12/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [Item]
    
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            // 기존 아이템 목록 탭
            originalItemsView
                .tabItem {
                    Image(systemName: "list.bullet")
                    Text("아이템")
                }
                .tag(0)
            
            EventListViewView()
                .tabItem {
                    Image(systemName: "calendar.badge.plus")
                    Text("캘린더")
                }
                .tag(1)
            
            AddressValidatorView()
                .tabItem {
                    Image(systemName: "envelope.front")
                    Text("정규표현식")
                }
                .tag(1)
            
            
            FloorContentView()
                .tabItem {
                    Image(systemName: "stairs")
                    Text("CoreMotion")
                }
                .tag(2)
        }
    }
    
    // MARK: - 기존 아이템 뷰
    
    private var originalItemsView: some View {
        NavigationSplitView {
            List {
                ForEach(items) { item in
                    NavigationLink {
                        Text("Item at \(item.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))")
                    } label: {
                        Text(item.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))
                    }
                }
                .onDelete(perform: deleteItems)
            }
            .navigationTitle("아이템")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem {
                    Button(action: addItem) {
                        Label("Add Item", systemImage: "plus")
                    }
                }
            }
        } detail: {
            Text("Select an item")
        }
    }

    private func addItem() {
        withAnimation {
            let newItem = Item(timestamp: Date())
            modelContext.insert(newItem)
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(items[index])
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
