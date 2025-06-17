// ScannerViewModel.swift
import Foundation
import Combine
import CoreData

@MainActor
final class ScannerViewModel: ObservableObject {
    @Published var scannedBox: Box?
    @Published var errorMessage: String?

    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext = SyncManager.shared.container.viewContext) {
        self.context = context
    }

    func processScan(code: String) {
        let request = NSFetchRequest<Box>(entityName: "Box")
        request.predicate = NSPredicate(format: "barcode == %@", code)
        request.fetchLimit = 1

        do {
            let results = try context.fetch(request)
            if let box = results.first {
                scannedBox = box
                errorMessage = nil
            } else {
                scannedBox = nil
                errorMessage = "No box found for code \(code)"
            }
        } catch {
            scannedBox = nil
            errorMessage = "Fetch error: \(error.localizedDescription)"
        }
    }
}
