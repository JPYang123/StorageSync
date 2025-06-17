import SwiftUI
import CloudKit

struct ShareSheetView: UIViewControllerRepresentable {
    let share: CKShare

    func makeUIViewController(context: Context) -> UICloudSharingController {
        UICloudSharingController(share: share,
                                 container: CKContainer.default())
    }
    func updateUIViewController(_ uiVC: UICloudSharingController, context: Context) {}
}
