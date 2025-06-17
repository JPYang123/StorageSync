import SwiftUI
import UIKit

struct BoxDetailView: View {
    @ObservedObject var vm: BoxDetailViewModel
    @State private var newItemName = ""
    @State private var showingImagePicker = false
    @State private var imagePickerSource: UIImagePickerController.SourceType = .photoLibrary
    @State private var showingShare = false

    init(box: Box) {
        self.vm = BoxDetailViewModel(box: box)
    }

    var body: some View {
        List {
            Section(header: Text("Items")) {
                ForEach(vm.items, id: \.id) { item in
                    HStack {
                        Text(item.name)
                        Spacer()
                        if let note = item.note, !note.isEmpty {
                            Image(systemName: "note.text")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .onDelete { offsets in
                    offsets.map { vm.items[$0] }.forEach(vm.deleteItem)
                }

                HStack {
                    TextField("New item name", text: $newItemName)
                    Button(action: {
                        vm.addItem(name: newItemName)
                        newItemName = ""
                    }) {
                        Image(systemName: "plus.circle.fill")
                    }
                    .disabled(newItemName.isEmpty)
                }
            }

            Section(header: Text("Photos")) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(vm.photos, id: \.id) { photo in
                            if let uiImage = UIImage(contentsOfFile: photo.localURL.path) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 100, height: 100)
                                    .clipped()
                                    .cornerRadius(8)
                                    .onTapGesture { vm.deletePhoto(photo) }
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
                HStack {
                    Button("Take Photo") {
                        imagePickerSource = .camera
                        showingImagePicker = true
                    }
                    Spacer()
                    Button("Photo Library") {
                        imagePickerSource = .photoLibrary
                        showingImagePicker = true
                    }
                }
            }
        }
        .listStyle(InsetGroupedListStyle())  // iOS 14+ inset style :contentReference[oaicite:4]{index=4}
        .navigationTitle(vm.box.title)       // Exposes title from public box property :contentReference[oaicite:5]{index=5}
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { showingShare = true } label: {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
        // Image picker sheet
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(sourceType: imagePickerSource) { image in
                try? vm.addPhoto(image: image)
                showingImagePicker = false
            }
        }
        // CloudKit share sheet
        .sheet(isPresented: $showingShare) {
            if let share = vm.share {
                ShareSheetView(share: share)
            }
        }
    }
}
