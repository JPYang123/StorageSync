// BoxDetailViewModel.swift
import Foundation
import Combine
import CoreData
import CloudKit
import UIKit

@MainActor
final class BoxDetailViewModel: ObservableObject {
    @Published var items: [Item] = []
    @Published var photos: [Photo] = []
    
    let box: Box
    private let context: NSManagedObjectContext
    private var cancellables = Set<AnyCancellable>()
    
    init(box: Box, context: NSManagedObjectContext = SyncManager.shared.container.viewContext) {
        self.box = box
        self.context = context
        fetchContents()
        
        NotificationCenter.default.publisher(
            for: .NSManagedObjectContextDidSave,
            object: context
        )
        .sink { [weak self] _ in self?.fetchContents() }
        .store(in: &cancellables)
        
        NotificationCenter.default.publisher(
            for: .NSPersistentStoreRemoteChange,
            object: SyncManager.shared.container.persistentStoreCoordinator
        )
        .sink { [weak self] _ in self?.fetchContents() }
        .store(in: &cancellables)
    }
    
    func fetchContents() {
        items = box.items.sorted { ($0.name ?? "") < ($1.name ?? "") }
        photos = box.photos.sorted {
            ($0.localURL?.lastPathComponent ?? "") < ($1.localURL?.lastPathComponent ?? "")
        }
    }
    
    // MARK: - Sharing
    var share: CKShare? {
        box.ckShare
    }
    
    func createShare(completion: @escaping (CKShare?) -> Void) {
        if let existing = box.ckShare {
            completion(existing)
            return
        }
        
        let container = SyncManager.shared.container
        container.share([box], to: nil) { objectIDs, share, _, error in
            DispatchQueue.main.async {
                if let share = share {
                    self.box.ckShare = share
                    SyncManager.shared.saveContext()
                } else if let error = error {
                    DebugLogger.log("Create share error: \(error)")
                }
                completion(share)
            }
        }
    }
    
    // MARK: - Item Management
    func addItem(name: String, note: String? = nil) {
        let item = Item(context: context)
        item.id = UUID()
        item.name = name
        item.note = note
        item.parent = box
        
        SyncManager.shared.saveContext()
        fetchContents()
    }
    
    func deleteItem(_ item: Item) {
        context.delete(item)
        SyncManager.shared.saveContext()
        fetchContents()
    }
    
    // MARK: - Photo Management
    func addPhoto(image: UIImage) throws {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return }
        
        let documentsPath = FileManager.default.urls(for: .documentDirectory,
                                                   in: .userDomainMask).first!
        let url = documentsPath.appendingPathComponent("\(UUID().uuidString).jpg")
        
        try data.write(to: url)
        
        let photo = Photo(context: context)
        photo.id = UUID()
        photo.localURL = url
        photo.box = box
        
        SyncManager.shared.saveContext()
        fetchContents()
    }
    
    func deletePhoto(_ photo: Photo) {
        if let url = photo.localURL {
            try? FileManager.default.removeItem(at: url)
        }
        context.delete(photo)
        SyncManager.shared.saveContext()
        fetchContents()
    }
}
