// BoxDetailView.swift
import SwiftUI

struct BoxDetailView: View {
    @StateObject private var vm: BoxDetailViewModel
    @State private var newItem = ""              // ← 单独声明
    @State private var showPicker = false        // ← 单独声明
    @State private var showDeleteAlert = false
    @Environment(\.dismiss) private var dismiss
    
    init(box: Box) {
        _vm = StateObject(wrappedValue: BoxDetailViewModel(box: box))
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(vm.box.title)
                    .font(.largeTitle)
                    .bold()
                
                // Items Section
                Section("Items") {
                    ForEach(Array(vm.items.enumerated()), id: \.element.id) { index, item in
                        HStack {
                            Text(item.name)
                            Spacer()
                            Button(role: .destructive) {
                                vm.deleteItem(at: IndexSet(integer: index))
                            } label: {
                                Image(systemName: "trash")
                            }
                        }
                    }
                    
                    HStack {
                        TextField("New Item", text: $newItem)
                        Button("Add") {
                            vm.addItem(name: newItem)
                            newItem = ""
                        }
                        .disabled(newItem.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }
                
                // Photos Section
                Section("Photos") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(Array(vm.photos.enumerated()), id: \.element.id) { index, photo in
                                if let url = photo.asset.fileURL,
                                   let uiImage = UIImage(contentsOfFile: url.path) {
                                    ZStack(alignment: .topTrailing) {
                                        Image(uiImage: uiImage)
                                            .resizable()
                                            .frame(width: 100, height: 100)
                                            .cornerRadius(8)
                                        Button(role: .destructive) {
                                            vm.deletePhoto(at: IndexSet(integer: index))
                                        } label: {
                                            Image(systemName: "minus.circle.fill")
                                                .foregroundColor(.red)
                                                .padding(4)
                                        }
                                    }
                                }
                            }
                            Button {
                                showPicker = true
                            } label: {
                                Image(systemName: "photo.on.rectangle.angled")
                                    .resizable()
                                    .frame(width: 100, height: 100)
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .sheet(isPresented: $showPicker) {
                        PhotoPicker { images in
                            // Loop through each picked UIImage and add them one by one
                            for img in images {
                                vm.addPhoto(image: img)
                            }
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
        }
        .navigationTitle("Detail")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(role: .destructive) {
                    showDeleteAlert = true
                } label: {
                    Image(systemName: "trash")
                }
            }
        }
        .alert("Delete Box", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) {
                vm.deleteBox {
                    dismiss()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete this box?")
        }
    }
}

