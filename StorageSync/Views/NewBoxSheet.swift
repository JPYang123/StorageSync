import SwiftUI
import CloudKit

struct NewBoxSheet: View {
    @Binding var isPresented: Bool
    var onSave: (String)->Void
    @State private var text = ""
    var body: some View {
        NavigationView { Form { TextField("Title", text: $text) }
            .toolbar {
                ToolbarItem(placement: .cancellationAction){ Button("Cancel"){isPresented=false} }
                ToolbarItem(placement: .confirmationAction){ Button("Save"){onSave(text);isPresented=false} }
            }
        }
    }
}
