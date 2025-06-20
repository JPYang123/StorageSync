// 3. ViewModel - listen for notifications and reload

import Foundation

// BoxesViewModel.swift
@MainActor
class BoxesViewModel: ObservableObject {
    @Published var boxes: [Box] = []
    @Published var error: Error?

    init() {
        // 订阅远端变化
        NotificationCenter.default.addObserver(
            forName: .boxesDidChange, object: nil, queue: .main
        ) { [weak self] _ in self?.reload() }

        reload()
    }

    func reload() {
        CloudKitManager.shared.fetchBoxes { [weak self] res in
            DispatchQueue.main.async {
                switch res {
                case .success(let b):
                    self?.boxes = b.sorted { $0.createdAt > $1.createdAt }
                case .failure(let e):
                    self?.error = e
                }
            }
        }
    }

    // 🚀 修改这里：新增后立即更新本地数组
    func add(title: String) {
        CloudKitManager.shared.saveBox(Box(title: title)) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let newBox):
                    // 把最新的箱子插到列表最前面
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
}
