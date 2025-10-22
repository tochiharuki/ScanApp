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
        // ✅ カメラを自動起動
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                showScanner = true
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
    let mode: ScanMode

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


        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
        }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
            for i in 0..<scan.pageCount {
                let image = scan.imageOfPage(at: i)
                parent.scannedImages.append(image)
            }
            controller.dismiss(animated: true)
        }
    }
}