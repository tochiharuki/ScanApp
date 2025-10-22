//
//  ScanView.swift
//  ScanApp
//

import SwiftUI
import VisionKit


struct ScanView: View {
    @State private var scannedImages: [UIImage] = []
    @State private var showScanner = false
    @State private var saveFormat: SaveFormat = .image

    enum SaveFormat: String, CaseIterable, Identifiable {
        case image = "Image"
        case pdf = "PDF"
        
        var id: String { rawValue }
    }

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            VStack {
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
                        .padding(.horizontal, 40)
                        .padding(.top, 100)
                }
                // 🔽 保存形式選択プルダウン
                Picker("Save as", selection: $saveFormat) {
                    ForEach(SaveFormat.allCases) { format in
                        Text(format.rawValue).tag(format)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal, 40)
                .padding(.top, 10)
            }
        }
        // ✅ カメラビューをフルスクリーンで開く
        .fullScreenCover(isPresented: $showScanner) {
            DocumentScannerView(scannedImages: $scannedImages, saveFormat: saveFormat)
                .ignoresSafeArea()
        }
    }
}

// MARK: - Document Scanner
struct DocumentScannerView: UIViewControllerRepresentable {
    @Binding var scannedImages: [UIImage]
    var saveFormat: ScanView.SaveFormat 

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

        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
            let fileManager = FileManager.default
            let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]

            if parent.saveFormat == .image {
                // 画像として保存
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyyMMdd_HHmmss"
                let timestamp = formatter.string(from: Date())

                for i in 0..<scan.pageCount {
                    let image = scan.imageOfPage(at: i)
                    parent.scannedImages.append(image)
                    if let data = image.jpegData(compressionQuality: 0.9) {
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
            } else {
                // PDFとして保存
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyyMMdd_HHmmss"
                let timestamp = formatter.string(from: Date())
                let pdfURL = documentsURL.appendingPathComponent("Scan_\(timestamp).pdf")

                let pdfRenderer = UIGraphicsPDFRenderer(bounds: CGRect(origin: .zero, size: scan.imageOfPage(at: 0).size))
                try? pdfRenderer.writePDF(to: pdfURL, withActions: { context in
                    for i in 0..<scan.pageCount {
                        let image = scan.imageOfPage(at: i)
                        context.beginPage()
                        image.draw(in: CGRect(origin: .zero, size: image.size))
                        parent.scannedImages.append(image)
                    }
                })
                print("✅ Saved PDF: Scan_\(timestamp).pdf")
            }


        
            controller.dismiss(animated: true)
        } // ← ここで documentCameraViewController の閉じ括弧
    } // ← ここで Coordinator の閉じ括弧
} // ← ここで DocumentScannerView の閉じ括弧