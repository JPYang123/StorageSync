// AddBoxView.swift
import SwiftUI

struct AddBoxView: View {
    @Binding var isPresented: Bool
    @StateObject private var vm = BoxListViewModel()
    @State private var title: String = ""
    @State private var barcode: String = ""
    @State private var showingScanner = false

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
                        vm.addBox(title: title, barcode: barcode.isEmpty ? nil : barcode)
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
}


#Preview {
    AddBoxView(isPresented: .constant(true))
}
