import SwiftUI
import VisionKit

enum ScanMode {
    case single
    case multiple
}

struct ScanView: View {
    @Binding var scannedImages: [UIImage]
    @State private var showScanner = false
    @State private var scanMode: ScanMode = .single

    var body: some View {
        ZStack(alignment: .top) {
            Color.white.ignoresSafeArea()

            VStack(spacing: 20) {
                // モード切り替え
                Picker("Scan Mode", selection: $scanMode) {
                    Text("Single").tag(ScanMode.single)
                    Text("Multiple").tag(ScanMode.multiple)
                }
                .pickerStyle(.segmented)
                .padding()
                .background(Color.white.opacity(0.9))
                .cornerRadius(10)
                .padding(.top, 60)

                Spacer()

                // カメラ起動ボタン
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
        // フルスクリーンでスキャナ起動
        .fullScreenCover(isPresented: $showScanner) {
            DocumentScannerView(scannedImages: $scannedImages, mode: scanMode)
                .ignoresSafeArea()
        }
        .onAppear {
            // 自動でスキャナを開く
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                showScanner = true
            }
        }
    }
}

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
                saveImageToDocuments(image, index: i)
            }

            if parent.mode == .single {
                parent.scannedImages = [newImages.last].compactMap { $0 }
            } else {
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