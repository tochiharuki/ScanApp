//
//  ScanView.swift
//  ScanApp
//

import SwiftUI
import VisionKit


struct ScanView: View {
    @State private var scannedImages: [UIImage] = []
    @State private var showScanner = false

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            VStack {
                if scannedImages.isEmpty {
                    // 📸 キャンセル後に出るボタン
                    Button(action: {
                        showScanner = true
                    }) {
                        Label("Start Scanning", systemImage: "camera.fill")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.black)
                            .cornerRadius(12)
                            .padding(.horizontal)
                            .padding(.top, 100)
                    }

                }
            }
        }
        // ✅ カメラビューをフルスクリーンで開く
        .fullScreenCover(isPresented: $showScanner) {
            DocumentScannerView(scannedImages: $scannedImages)
                .ignoresSafeArea()
                
        }
    }
}

// MARK: - Document Scanner
struct DocumentScannerView: UIViewControllerRepresentable {
    @Binding var scannedImages: [UIImage]

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
        let parent: DocumentScannerView

        init(parent: DocumentScannerView) {
            self.parent = parent
        }

        // ✅ キャンセル時にカメラを閉じる
        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            controller.dismiss(animated: true)
        }


        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
        }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
            let fileManager = FileManager.default
            let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        
            for i in 0..<scan.pageCount {
                let image = scan.imageOfPage(at: i)
                // ✅ 親ビューの scannedImages に追加
                parent.scannedImages.append(image)
        
                // 保存
                if let data = image.jpegData(compressionQuality: 0.9) {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyyMMdd_HHmmss"
                    let timestamp = formatter.string(from: Date())
                    let fileName = "Scan_\(timestamp)_\(i+1).jpg"
                    let url = documentsURL.appendingPathComponent(fileName)
                    do {
                        try data.write(to: url)
                        print("✅ Saved image: \(fileName)")
                    } catch {
                        print("❌ Failed saving image:", error)
                    }
                }
            }
        
            controller.dismiss(animated: true)
}
    }
}