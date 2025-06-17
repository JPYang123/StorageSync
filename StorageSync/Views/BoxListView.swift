// BoxListView.swift
import SwiftUI
import CloudKit

struct BoxListView: View {
    @StateObject private var vm = BoxListViewModel()
    @State private var showingAddBox = false

    var body: some View {
        NavigationView {
            List {
                ForEach(vm.boxes, id: \.id) { box in
                    NavigationLink(destination: BoxDetailView(box: box)) {
                        HStack {
                            Text(box.title)
                            Spacer()
                            if let code = box.barcode {
                                Image(systemName: "barcode")
                                    .foregroundColor(.secondary)
                                    .help(code)
                            }
                        }
                    }
                }
                .onDelete(perform: delete)
            }
            .navigationTitle("StorageSync")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddBox = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddBox) {
                AddBoxView(isPresented: $showingAddBox)
            }
        }
    }

    private func delete(at offsets: IndexSet) {
        offsets.map { vm.boxes[$0] }.forEach(vm.deleteBox)
    }
}
