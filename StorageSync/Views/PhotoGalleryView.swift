import SwiftUI

struct ZoomableImage: View {
    let image: UIImage
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    var body: some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFit()
            .scaleEffect(scale)
            .offset(offset)
            .gesture(
                MagnificationGesture()
                    .onChanged { value in
                        scale = lastScale * value
                    }
                    .onEnded { _ in
                        lastScale = scale
                    }
            )
            .simultaneousGesture(
                DragGesture()
                    .onChanged { value in
                        offset = CGSize(width: lastOffset.width + value.translation.width,
                                        height: lastOffset.height + value.translation.height)
                    }
                    .onEnded { _ in
                        lastOffset = offset
                    }
            )
    }
}

struct PhotoGalleryView: View {
    let photos: [Photo]
    @State private var index: Int
    @Environment(\.dismiss) private var dismiss

    init(photos: [Photo], initialIndex: Int) {
        self.photos = photos
        _index = State(initialValue: initialIndex)
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            TabView(selection: $index) {
                ForEach(Array(photos.enumerated()), id: \.element.id) { i, photo in
                    if let url = photo.asset.fileURL,
                       let uiImage = UIImage(contentsOfFile: url.path) {
                        ZoomableImage(image: uiImage)
                            .tag(i)
                            .background(Color.black)
                    } else {
                        Color.black.tag(i)
                    }
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
            .background(Color.black)
            .ignoresSafeArea()

            Button(action: { dismiss() }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.largeTitle)
                    .padding()
                    .foregroundColor(.white)
            }
        }
        .background(Color.black.ignoresSafeArea())
    }
}

#Preview {
    PhotoGalleryView(photos: [], initialIndex: 0)
}
