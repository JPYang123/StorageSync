// BoxListView.swift
import SwiftUI
import Combine

private enum SortOption: String, CaseIterable {
    case titleAsc = "Title ⬆️"
    case titleDesc = "Title ⬇️"
    case dateAsc = "Date ⬆️"
    case dateDesc = "Date ⬇️"
}

struct BoxListView: View {
    @StateObject private var vm = BoxesViewModel()
    @State private var showAddSheet = false
    @State private var newTitle = ""
    @State private var searchText = ""
    @State private var searchTimer: Timer?
    @State private var sortOption: SortOption = .dateDesc

    private var sortedBoxes: [Box] {
        switch sortOption {
        case .titleAsc:
            return vm.boxes.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        case .titleDesc:
            return vm.boxes.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedDescending }
        case .dateAsc:
            return vm.boxes.sorted { $0.createdAt < $1.createdAt }
        case .dateDesc:
            return vm.boxes.sorted { $0.createdAt > $1.createdAt }
        }
    }
    var body: some View {
        NavigationView {
            List {
                if searchText.isEmpty {
                    ForEach(sortedBoxes) { box in
                        NavigationLink(destination: BoxDetailView(box: box)) {
                            BoxRow(box: box)
                        }
                    }
                } else {
                    if vm.searchResults.isEmpty {
                        Text("No items found")
                    } else {
                        ForEach(vm.searchResults) { item in
                            if let box = vm.boxes.first(where: { $0.id == item.boxRef }) {
                                NavigationLink(destination: BoxDetailView(box: box)) {
                                    VStack(alignment: .leading) {
                                        Text(item.name)
                                        Text(box.title)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            } else {
                                Text(item.name)
                            }
                        }
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
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Picker("Sort", selection: $sortOption) {
                            ForEach(SortOption.allCases, id: \.self) { option in
                                Text(option.rawValue).tag(option)
                            }
                        }
                    } label: {
                        Image(systemName: "arrow.up.arrow.down")
                    }
                }
            }
            .sheet(isPresented: $showAddSheet) {
                NewBoxSheet(isPresented: $showAddSheet) { title in
                    vm.add(title: title)
                }
            }
            .searchable(text: $searchText, prompt: "Search Items")
            .onChange(of: searchText) { newValue in
                // Simple timer-based debouncing
                searchTimer?.invalidate()
                searchTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { _ in
                    vm.searchItems(keyword: newValue) // FIXED: Use the correct method name
                }
            }
        }
    }
}

#Preview {
    BoxListView()
}
