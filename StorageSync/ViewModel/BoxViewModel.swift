import Foundation

@MainActor
class BoxesViewModel: ObservableObject {
    @Published var boxes: [Box] = []
    @Published var searchResults: [Item] = []
    @Published var error: Error?
    
    // Store all items locally for search
    private var allLoadedItems: [Item] = []
    private var searchTask: Task<Void, Never>?
    
    init() {
        NotificationCenter.default.addObserver(
            forName: .boxesDidChange, object: nil, queue: .main
        ) { [weak self] _ in
            self?.reload()
        }
        
        NotificationCenter.default.addObserver(
            forName: .itemsDidChange, object: nil, queue: .main
        ) { [weak self] _ in
            self?.loadAllItems()
        }
        
        reload()
    }
    
    func reload() {
        CloudKitManager.shared.fetchBoxes { [weak self] res in
            DispatchQueue.main.async {
                switch res {
                case .success(let b):
                    self?.boxes = b.sorted { $0.createdAt > $1.createdAt }
                    // After loading boxes, load all items
                    self?.loadAllItems()
                case .failure(let e):
                    self?.error = e
                }
            }
        }
    }
    
    /// Load all items from all boxes
    private func loadAllItems() {
        guard !boxes.isEmpty else { return }
        
        var tempItems: [Item] = []
        let group = DispatchGroup()
        
        for box in boxes {
            group.enter()
            CloudKitManager.shared.fetchItems(for: box.id) { result in
                if case .success(let items) = result {
                    tempItems.append(contentsOf: items)
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) { [weak self] in
            self?.allLoadedItems = tempItems
        }
    }
    
    func add(title: String) {
        CloudKitManager.shared.saveBox(Box(title: title)) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let newBox):
                    self?.boxes.insert(newBox, at: 0)
                case .failure(let e):
                    self?.error = e
                }
            }
        }
    }
    
    func delete(at offsets: IndexSet) {
        for idx in offsets {
            let box = boxes[idx]
            CloudKitManager.shared.delete(recordID: box.id) { _ in }
        }
    }
    
    /// LOCAL SEARCH ONLY - No CloudKit queries
    func searchItems(keyword: String) {
        searchTask?.cancel()
        
        let trimmed = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmed.isEmpty else {
            searchResults = []
            return
        }
        
        searchTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 100_000_000) // 100ms delay
            
            guard !Task.isCancelled else { return }

            let filtered = allLoadedItems.filter { item in
                item.name.localizedCaseInsensitiveContains(trimmed)
            }
            
            self.searchResults = filtered
        }
    }
    
}
