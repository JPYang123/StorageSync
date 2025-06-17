// ScannerView.swift
import SwiftUI
import AVFoundation

struct ScannerView: UIViewControllerRepresentable {
    var completion: (String) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(completion: completion)
    }

    func makeUIViewController(context: Context) -> UIViewController {
        let controller = UIViewController()
        let scanner = BarcodeScannerService()
        scanner.delegate = context.coordinator

        // 使用公开的 session 属性
        let previewLayer = AVCaptureVideoPreviewLayer(session: scanner.session)
        previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        previewLayer.frame = controller.view.bounds
        controller.view.layer.addSublayer(previewLayer)

        scanner.startScanning()
        context.coordinator.scanner = scanner
        return controller
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // 不需要动态更新
    }

    class Coordinator: NSObject, BarcodeScannerDelegate {
        var scanner: BarcodeScannerService?
        private let completion: (String) -> Void

        init(completion: @escaping (String) -> Void) {
            self.completion = completion
        }

        func didDetect(code: String) {
            completion(code)
        }

        func didFail(with error: Error) {
            // 可以在此添加错误处理逻辑
        }
    }
}
