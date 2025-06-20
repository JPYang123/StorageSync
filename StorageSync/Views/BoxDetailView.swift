// BoxDetailView.swift
import SwiftUI

struct BoxDetailView: View {
    @StateObject private var vm: BoxDetailViewModel
    @State private var newItem = ""              // ← 单独声明
    @State private var showPicker = false        // ← 单独声明

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
                    ForEach(vm.items) { item in
                        Text(item.name)
                    }
                    .onDelete(perform: vm.deleteItem)

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
                            ForEach(vm.photos) { photo in
                                if let url = photo.asset.fileURL,
                                   let uiImage = UIImage(contentsOfFile: url.path) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .frame(width: 100, height: 100)
                                        .cornerRadius(8)
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
    }
}

