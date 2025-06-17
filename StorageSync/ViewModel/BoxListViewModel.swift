// BoxListViewModel.swift
import Foundation
import Combine
import CoreData

@MainActor
final class BoxListViewModel: ObservableObject {
    @Published var boxes: [Box] = []
    private var cancellables = Set<AnyCancellable>()
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext = SyncManager.shared.container.viewContext) {
        self.context = context
        fetchBoxes()
        NotificationCenter.default.publisher(
            for: .NSManagedObjectContextDidSave,
            object: context
        )
        .sink { [weak self] _ in self?.fetchBoxes() }
        .store(in: &cancellables)
    }

    func fetchBoxes() {
        let request = NSFetchRequest<Box>(entityName: "Box")
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \Box.title, ascending: true)
        ]
        do {
            boxes = try context.fetch(request)
        } catch {
            print("Fetch boxes error: \(error)")
        }
    }

    func addBox(title: String, barcode: String? = nil) {
        let newBox = Box(context: context)
        newBox.id = UUID()
        newBox.title = title
        newBox.barcode = barcode
        SyncManager.shared.saveContext()
    }

    func deleteBox(_ box: Box) {
        context.delete(box)
        SyncManager.shared.saveContext()
    }
}
