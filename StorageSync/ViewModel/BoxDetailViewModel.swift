import Foundation
import Combine
import CoreData
import CloudKit

@MainActor
final class BoxDetailViewModel: ObservableObject {
    @Published var items: [Item] = []
    @Published var photos: [Photo] = []

    // 从 private 改为 internal
    let box: Box
    private let context: NSManagedObjectContext
    private var cancellables = Set<AnyCancellable>()

    init(box: Box,
         context: NSManagedObjectContext = SyncManager.shared.container.viewContext) {
        self.box = box
        self.context = context
        fetchContents()
        NotificationCenter.default.publisher(
            for: .NSManagedObjectContextDidSave,
            object: context
        )
        .sink { [weak self] _ in self?.fetchContents() }
        .store(in: &cancellables)
    }

    func fetchContents() {
        items = box.items.sorted { $0.name < $1.name }
        photos = box.photos.sorted {
            $0.localURL.lastPathComponent < $1.localURL.lastPathComponent
        }
    }

    // 分享相关
    var share: CKShare? {
        box.ckShare
    }

    // 如需获取 CKRecord，可启用以下代码
    /*
    var record: CKRecord? {
        try? NSPersistentCloudKitContainer
            .default()
            .record(for: box.objectID)
    }
    */
    
    // ... 省略 add/deleteItem, add/deletePhoto 等方法 ...
}
