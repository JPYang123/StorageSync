// BoxDetailView.swift
import SwiftUI
import UIKit

struct BoxDetailView: View {
    @StateObject private var vm: BoxDetailViewModel
    @State private var newItemName = ""
    @State private var showingImagePicker = false
    @State private var imagePickerSource: UIImagePickerController.SourceType = .photoLibrary
    @State private var showingShare = false
    
    init(box: Box) {
        _vm = StateObject(wrappedValue: BoxDetailViewModel(box: box))
    }
    
    var body: some View {
        List {
            Section(header: Text("Items")) {
                ForEach(vm.items, id: \.id) { item in
                    HStack {
                        Text(item.name ?? "Untitled Item")
                        Spacer()
                        if let note = item.note, !note.isEmpty {
                            Image(systemName: "note.text")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .onDelete { offsets in
                    for index in offsets {
                        vm.deleteItem(vm.items[index])
                    }
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
                            if let url = photo.localURL,
                               let uiImage = UIImage(contentsOfFile: url.path) {
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
        .listStyle(InsetGroupedListStyle())
        .navigationTitle(vm.box.title ?? "Untitled Box")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    vm.createShare { share in
                        if share != nil { showingShare = true }
                    }
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
        // Image picker sheet
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(sourceType: imagePickerSource) { image in
                do {
                    try vm.addPhoto(image: image)
                } catch {
                    print("Add photo error: \(error)")
                }
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

#Preview {
    let context = SyncManager.shared.container.viewContext
    let box = Box(context: context)
    box.id = UUID()
    box.title = "Preview Box"
    return NavigationView { BoxDetailView(box: box) }
}
