//
//  ScanView.swift
//  ScanApp
//

import SwiftUI
import VisionKit

enum ScanMode {
    case single
    case multiple
}

struct ScanView: View {
    @State private var scannedImages: [UIImage] = []
    @State private var showScanner = false
    @State private var scanMode: ScanMode = .single

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            VStack {
                if scannedImages.isEmpty {
                    Text("Scanning...")
                        .foregroundColor(.gray)
                        .padding(.top, 100)
                } else {
                    ScrollView {
                        ForEach(scannedImages, id: \.self) { img in
                            Image(uiImage: img)
                                .resizable()
                                .scaledToFit()
                                .padding()
                        }
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
            DocumentScannerView(scannedImages: $scannedImages, mode: scanMode)
                .ignoresSafeArea()
                .overlay(
                    // カメラ上にモード切り替えボタンを表示
                    VStack {
                        Picker("Mode", selection: $scanMode) {
                            Text("Single").tag(ScanMode.single)
                            Text("Multiple").tag(ScanMode.multiple)
                        }
                        .pickerStyle(.segmented)
                        .padding()
                        .background(Color.black.opacity(0.4))
                        .cornerRadius(10)
                        .padding(.top, 40)
                        Spacer()
                    }
                )
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

        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
            var newImages: [UIImage] = []
            for i in 0..<scan.pageCount {
                let image = scan.imageOfPage(at: i)
                newImages.append(image)
                if parent.mode == .single { break }
            }

            parent.scannedImages.append(contentsOf: newImages)
            controller.dismiss(animated: true)
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