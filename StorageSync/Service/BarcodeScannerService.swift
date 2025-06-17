// BarcodeScannerService.swift
import Foundation
import AVFoundation
import UIKit

/// 扫描结果回调协议
protocol BarcodeScannerDelegate: AnyObject {
    func didDetect(code: String)
    func didFail(with error: Error)
}

final class BarcodeScannerService: NSObject {
    // 将 session 从 private 改为 internal（或 public）
    let session = AVCaptureSession()
    private let metadataOutput = AVCaptureMetadataOutput()
    weak var delegate: BarcodeScannerDelegate?

    override init() {
        super.init()
        guard let videoDevice = AVCaptureDevice.default(for: .video),
              let videoInput = try? AVCaptureDeviceInput(device: videoDevice),
              session.canAddInput(videoInput)
        else {
            delegate?.didFail(with: NSError(domain: "CameraError", code: -1))
            return
        }
        session.addInput(videoInput)

        if session.canAddOutput(metadataOutput) {
            session.addOutput(metadataOutput)
            metadataOutput.setMetadataObjectsDelegate(self, queue: .main)
            metadataOutput.metadataObjectTypes = [.ean13, .qr, .code128, .code39]
        } else {
            delegate?.didFail(with: NSError(domain: "MetadataError", code: -2))
        }
    }

    func startScanning() {
        if !session.isRunning {
            session.startRunning()
        }
    }

    func stopScanning() {
        if session.isRunning {
            session.stopRunning()
        }
    }
}

extension BarcodeScannerService: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(_ output: AVCaptureMetadataOutput,
                        didOutput metadataObjects: [AVMetadataObject],
                        from connection: AVCaptureConnection) {
        for metadata in metadataObjects {
            guard let readable = metadata as? AVMetadataMachineReadableCodeObject,
                  let code = readable.stringValue else { continue }
            delegate?.didDetect(code: code)
            stopScanning()
            break
        }
    }
}
