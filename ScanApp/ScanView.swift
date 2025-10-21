//
//  ScanView.swift
//  ScanApp
//
//  Created by Tochishita Haruki on 2025/10/21.
//

import SwiftUI
import VisionKit

struct ScanView: UIViewControllerRepresentable {
    @Binding var scannedImages: [UIImage]
    let mode: ScanMode  // ← 追加：撮影モード

    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let scanner = VNDocumentCameraViewController()
        scanner.delegate = context.coordinator
        return scanner
    }

    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        let parent: ScanView
        init(parent: ScanView) {
            self.parent = parent
        }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
            var newImages: [UIImage] = []
            
            for i in 0..<scan.pageCount {
                let image = scan.imageOfPage(at: i)
                newImages.append(image)
                saveImageToDocuments(image, index: i)
            }

            // single モードなら最新の1枚だけ保持
            if parent.mode == .single {
                parent.scannedImages = [newImages.last].compactMap { $0 }
            } else {
                parent.scannedImages.append(contentsOf: newImages)
            }

            controller.dismiss(animated: true)
        }

        // MARK: - 保存関数
        private func saveImageToDocuments(_ image: UIImage, index: Int) {
            guard let data = image.jpegData(compressionQuality: 0.9) else { return }
            
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyyMMdd_HHmmss"
            let timestamp = formatter.string(from: Date())
            let fileName = "Scan_\(timestamp)_\(index + 1).jpg"
            
            let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                .appendingPathComponent(fileName)
            
            do {
                try data.write(to: url)
                print("✅ Saved scan to: \(url.lastPathComponent)")
            } catch {
                print("❌ Failed saving image:", error)
            }
        }

        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            controller.dismiss(animated: true)
        }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
            print("❌ Scan failed:", error)
            controller.dismiss(animated: true)
        }
    }
}