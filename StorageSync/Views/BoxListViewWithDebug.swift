import SwiftUI
import Combine

struct BoxListViewWithDebug: View {
    @StateObject private var vm = BoxesViewModel()
    @State private var showAddSheet = false
    @State private var newTitle = ""
    @State private var searchText = ""
    
    var body: some View {
        NavigationView {
            List {
                // Debug section (remove this later)
                Section("Debug Info") {
                    Button("Test CloudKit Connection") {
                        CloudKitManager.shared.testCloudKitConnection { success in
                            print("CloudKit test result: \(success)")
                        }
                    }
                    .foregroundColor(.blue)
                    
                    Button("Refresh All Items") {
                        vm.debugRefreshItems()
                    }
                    .foregroundColor(.green)
                }
                
                // Main content
                if searchText.isEmpty {
                    ForEach(vm.boxes) { box in
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
            }
            .sheet(isPresented: $showAddSheet) {
                NewBoxSheet(isPresented: $showAddSheet) { title in
                    vm.add(title: title)
                }
            }
            .searchable(text: $searchText, prompt: "Search Items")
            .onReceive(
                Just(searchText)
                    .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            ) { debouncedSearchText in
                vm.searchItems(keyword: debouncedSearchText)
            }
        }
    }
}
