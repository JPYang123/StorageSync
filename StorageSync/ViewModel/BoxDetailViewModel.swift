import Foundation
import UIKit
import SwiftUI

@MainActor
class BoxDetailViewModel: ObservableObject {
    let box: Box
    @Published var items: [Item] = []
    @Published var photos: [Photo] = []
    @Published var error: Error?

    private var observers: [NSObjectProtocol] = []

    init(box: Box) {
        self.box = box
        // 订阅 Item 变化通知
        observers.append(NotificationCenter.default.addObserver(
            forName: .itemsDidChange,
            object: nil,
            queue: OperationQueue.main
        ) { [weak self] _ in
            self?.fetchItems()
        })
        // 订阅 Photo 变化通知
        observers.append(NotificationCenter.default.addObserver(
            forName: .photosDidChange,
            object: nil,
            queue: OperationQueue.main
        ) { [weak self] _ in
            self?.fetchPhotos()
        })
        // 初次加载
        fetchItems()
        fetchPhotos()
    }

    deinit {
        observers.forEach { NotificationCenter.default.removeObserver($0) }
    }

    /// 获取所有 Item 并更新列表
    func fetchItems() {
        CloudKitManager.shared.fetchItems(for: box.id) { [weak self] result in
            switch result {
            case .success(let list):
                let workItem = DispatchWorkItem {
                    self?.items = list
                }
                DispatchQueue.main.async(execute: workItem)
            case .failure(let e):
                let workItem = DispatchWorkItem {
                    self?.error = e
                }
                DispatchQueue.main.async(execute: workItem)
            }
        }
    }

    /// 添加新 Item 并更新列表
    func addItem(name: String) {
        let newItem = Item(name: name, boxRef: box.id)
        CloudKitManager.shared.saveItem(newItem) { [weak self] result in
            switch result {
            case .success(let saved):
                let workItem = DispatchWorkItem {
                    self?.items.insert(saved, at: 0)
                }
                DispatchQueue.main.async(execute: workItem)
            case .failure(let e):
                let workItem = DispatchWorkItem {
                    self?.error = e
                }
                DispatchQueue.main.async(execute: workItem)
            }
        }
    }

    /// 删除 Item
    func deleteItem(at offsets: IndexSet) {
        // Remove immediately from the local array so UI updates at once
        let ids = offsets.compactMap { index in items[index].id }
        items.remove(atOffsets: offsets)
        for id in ids {
            CloudKitManager.shared.delete(recordID: id) { _ in }
        }
    }

    /// 获取所有 Photo 并更新列表
    func fetchPhotos() {
        CloudKitManager.shared.fetchPhotos(for: box.id) { [weak self] result in
            switch result {
            case .success(let list):
                let workItem = DispatchWorkItem {
                    self?.photos = list
                }
                DispatchQueue.main.async(execute: workItem)
            case .failure(let e):
                let workItem = DispatchWorkItem {
                    self?.error = e
                }
                DispatchQueue.main.async(execute: workItem)
            }
        }
    }

    /// 添加新 Photo 并更新列表
    func addPhoto(image: UIImage) {
        // 将 UIImage 写入临时文件
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString + ".jpg")
        if let data = image.jpegData(compressionQuality: 0.8) {
            do {
                 try data.write(to: tempURL)
             } catch {
                 self.error = error
                 Logger.log(error)
                 return
             }
        }
        let newPhoto = Photo(imageURL: tempURL, boxRef: box.id)
        CloudKitManager.shared.savePhoto(newPhoto) { [weak self] result in
            switch result {
            case .success(let savedPhoto):
                let workItem = DispatchWorkItem {
                    self?.photos.insert(savedPhoto, at: 0)
                }
                DispatchQueue.main.async(execute: workItem)
            case .failure(let e):
                let workItem = DispatchWorkItem {
                    self?.error = e
                }
                DispatchQueue.main.async(execute: workItem)
            }
        }
    }

    /// 删除 Photo
    func deletePhoto(at offsets: IndexSet) {
        // Update local state first for immediate feedback
        let ids = offsets.compactMap { index in photos[index].id }
        photos.remove(atOffsets: offsets)
        for id in ids {
            CloudKitManager.shared.delete(recordID: id) { _ in }
        }
    }
    
    /// Delete the current Box
    func deleteBox(completion: @escaping () -> Void) {
        CloudKitManager.shared.delete(recordID: box.id) { _ in
            NotificationCenter.default.post(name: .boxesDidChange, object: nil)
            completion()
        }
    }
}
