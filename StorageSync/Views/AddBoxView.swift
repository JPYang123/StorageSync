// AddBoxView.swift
import SwiftUI

struct AddBoxView: View {
    @Binding var isPresented: Bool
    @State private var title: String = ""
    @State private var barcode: String = ""
    @State private var showingScanner = false

    private let context = SyncManager.shared.container.viewContext
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("箱子信息")) {
                    TextField("标题", text: $title)
                    HStack {
                        TextField("条码 (可选)", text: $barcode)
                        Button(action: { showingScanner = true }) {
                            Image(systemName: "barcode.viewfinder")
                        }
                    }
                }
            }
            .navigationTitle("添加箱子")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        addBox()
                        isPresented = false
                    }.disabled(title.isEmpty)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { isPresented = false }
                }
            }
            .sheet(isPresented: $showingScanner) {
                ScannerView { code in
                    barcode = code
                    showingScanner = false
                }
            }
        }
    }
    private func addBox() {
        let newBox = Box(context: context)
        newBox.id = UUID()
        newBox.title = title
        newBox.barcode = barcode.isEmpty ? nil : barcode
        
        SyncManager.shared.saveContext()
    }
}


#Preview {
    AddBoxView(isPresented: .constant(true))
}
