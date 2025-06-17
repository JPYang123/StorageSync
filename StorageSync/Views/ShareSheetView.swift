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

#Preview {
    let record = CKRecord(recordType: "Preview")
    let share = CKShare(rootRecord: record)
    return ShareSheetView(share: share)
}
