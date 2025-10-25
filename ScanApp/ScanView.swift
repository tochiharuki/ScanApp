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
    // 保存先フォルダ用
    @State private var showFolderSelection = false
    @State private var selectedFolderURL: URL? = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]


    enum SaveFormat: String, CaseIterable, Identifiable {
        case image = "Image"
        case pdf = "PDF"
        
        var id: String { rawValue }
    }

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            VStack {
                Spacer(minLength: 100) // 上部スペース

                // 📸 スキャン開始ボタン（大きめ）
                Button(action: {
                    showScanner = true
                }) {
                    Label("Start Scanning", systemImage: "camera.fill")
                        .font(.headline) // 少し大きく
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.black)
                        .cornerRadius(12)
                        .padding(.horizontal, 40)
                        .padding(.top, 60) // 上部余白を調整
                }

                Spacer().frame(height: 20)

                // Save As ピッカー（少し小さく）
                VStack(spacing: 4) {
                    Text("Save as")
                        .font(.footnote) // 小さめ
                        .foregroundColor(.black)
                    
                    Picker("", selection: $saveFormat) {
                        ForEach(SaveFormat.allCases) { format in
                            Text(format.rawValue).tag(format)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .frame(maxWidth: .infinity)
                }
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                .padding(.horizontal, 40)

                Spacer().frame(height: 20)

                // 保存先フォルダ選択
                VStack(spacing: 4) {
                    Text("Save To")
                        .font(.footnote)
                        .foregroundColor(.black)
                    
                    Button(action: { showFolderSelection = true }) {
                        HStack {
                            Image(systemName: "folder.fill")
                            Text(selectedFolderURL?.lastPathComponent ?? "Select Folder")
                                .font(.footnote)
                                .lineLimit(1)
                            Spacer()
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(8)
                    .foregroundColor(.black)
                    .background(Color.white)
                    .cornerRadius(8)
                    .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                    .padding(.horizontal, 15) // ボタン自体の左右余白


                    // 選択中のパスを相対パス表示
                    if let url = selectedFolderURL {
                        let relativePath = url.pathComponents
                            .drop(while: { $0 != "Documents" })
                            .joined(separator: "/")
                        
                        Text(relativePath)
                            .font(.caption2) // 小さく
                            .foregroundColor(.gray)
                            .lineLimit(1)
                            .truncationMode(.middle)
                            .padding(.horizontal)
                    }
                }
                .padding(6)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                .padding(.horizontal, 40)

                Spacer() // 下部余白
            }
            .frame(maxWidth: .infinity) // VStack を画面幅いっぱいに

        }
        // ✅ カメラビューをフルスクリーンで開く
        .fullScreenCover(isPresented: $showScanner) {
            DocumentScannerView(
                scannedImages: $scannedImages,
                saveFormat: saveFormat,
                selectedFolderURL: selectedFolderURL // ✅ 渡す！
            )
            .ignoresSafeArea()
        }
        .sheet(isPresented: $showFolderSelection) {
            NavigationStack {
                FolderSelectionView(
                    selectedFolderURL: $selectedFolderURL,
                    isPresented: $showFolderSelection
                )
                .accentColor(.black)
                .onChange(of: selectedFolderURL) { newURL in
                    if let url = newURL {
                        UserDefaults.standard.set(url.path, forKey: "scanSaveFolder")
                    }
                }
            }
        }
        .onAppear {
            if let path = UserDefaults.standard.string(forKey: "scanSaveFolder") {
                selectedFolderURL = URL(fileURLWithPath: path)
            }
        }
    }
}

// MARK: - Document Scanner
struct DocumentScannerView: UIViewControllerRepresentable {
    @Binding var scannedImages: [UIImage]
    var saveFormat: ScanView.SaveFormat 
    var selectedFolderURL: URL?

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
            let baseURL = parent.selectedFolderURL ?? fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]

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
                            print("✅ Saved image to:", url.path)
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
                print("✅ Saved PDF to:", pdfURL.path)
            }


        
            controller.dismiss(animated: true)
        } 
    } 
} 