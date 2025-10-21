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
    
    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let scanner = VNDocumentCameraViewController()
        scanner.delegate = context.coordinator
        return scanner
    }
    
    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {
        // ここでは更新不要
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        let parent: ScanView
        init(parent: ScanView) {
            self.parent = parent
        }
        
        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
            for i in 0..<scan.pageCount {
                let image = scan.imageOfPage(at: i)
                parent.scannedImages.append(image)
                
                // 保存処理を追加
                saveImageToDocuments(image, index: i)
            }
            controller.dismiss(animated: true)
        }
        
        // MARK: - 保存関数
        private func saveImageToDocuments(_ image: UIImage, index: Int) {
            guard let data = image.jpegData(compressionQuality: 0.9) else { return }
            
            // 日付とページ番号でファイル名を作成
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyyMMdd_HHmmss"
            let timestamp = formatter.string(from: Date())
            let fileName = "Scan_\(timestamp)_\(index + 1).jpg"
            
            let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                .appendingPathComponent(fileName)
            
            do {
                try data.write(to: url)
                print("Saved scan to: \(url)")
            } catch {
                print("Failed saving image:", error)
            }
        }
        
        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            controller.dismiss(animated: true)
        }
        
        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
            print("Scan failed:", error)
            controller.dismiss(animated: true)
        }
    }
}