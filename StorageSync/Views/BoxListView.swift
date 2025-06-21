// BoxListView.swift
// BoxListView.swift
import SwiftUI

struct BoxListView: View {
    @StateObject private var vm = BoxesViewModel()
    @State private var showAddSheet = false
    @State private var newTitle = ""            // ← 单独声明

    var body: some View {
        NavigationView {
            List {
                ForEach(vm.boxes) { box in
                    // 修正 NavigationLink 用法
                    NavigationLink(destination: BoxDetailView(box: box)) {
                        BoxRow(box: box)
                    }
                }
            }
            .navigationTitle("Container")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddSheet) {
                NewBoxSheet(isPresented: $showAddSheet) { title in
                    vm.add(title: title)
                }
            }
        }
    }
}


#Preview {
    BoxListView()
}
