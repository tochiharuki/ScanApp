//
//  ScanView.swift
//  ScanApp
//
//  Created by Tochishita Haruki on 2025/10/22.
//

import SwiftUI
import VisionKit

// ✅ Hashable 準拠で Picker が使える
enum ScanMode: String, CaseIterable, Hashable {
    case single = "Single"
    case multiple = "Multiple"
}

struct ScanView: View {
    @Binding var scannedImages: [UIImage]
    var mode: ScanMode
    @State private var showScanner = false
    @State private var scanMode: ScanMode = .single

    var body: some View {
        ZStack(alignment: .top) {
            Color.white.ignoresSafeArea()

            VStack(spacing: 20) {
                // ✅ モード切り替え（ラジオボタン）
                Picker("Scan Mode", selection: $scanMode) {
                    ForEach(ScanMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                .background(Color.white.opacity(0.9))
                .cornerRadius(10)
                .padding(.top, 60)

                Spacer()

                // ✅ 手動起動ボタン（必要なら）
                Button(action: {
                    showScanner = true
                }) {
                    Label("Start Scanning", systemImage: "camera.fill")
                        .font(.title3)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.black)
                        .cornerRadius(12)
                        .padding(.horizontal)
                }

                Spacer()
            }
        }
        // ✅ フルスクリーンでスキャナ起動
        .fullScreenCover(isPresented: $showScanner) {
            DocumentScannerView(scannedImages: $scannedImages, mode: scanMode)
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

    // MARK: - Coordinator
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
                saveImageToDocuments(image, index: i)
            }

            if parent.mode == .single {
                // ✅ シングルモード：最後の1枚のみ
                if let last = newImages.last {
                    parent.scannedImages = [last]
                }
            } else {
                // ✅ 複数モード：すべて追加
                parent.scannedImages.append(contentsOf: newImages)
            }

            controller.dismiss(animated: true)
        }

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