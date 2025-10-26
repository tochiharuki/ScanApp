//
//  DocumentInteractionView.swift
//  ScanApp
//

import SwiftUI
import UIKit

struct DocumentInteractionView: UIViewControllerRepresentable {
    let url: URL
    var onDebugMessage: ((String) -> Void)?  // ← 🔹 追加：デバッグ用コールバック

    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = UIViewController()
        viewController.view.backgroundColor = .systemBackground

        let fileExists = FileManager.default.fileExists(atPath: url.path)
        onDebugMessage?("📂 Opening: \(url.lastPathComponent)\nExists: \(fileExists)")

        let docController = UIDocumentInteractionController(url: url)
        docController.delegate = context.coordinator

        DispatchQueue.main.async {
            if fileExists {
                onDebugMessage?("✅ Presenting preview for \(url.lastPathComponent)")
                docController.presentPreview(animated: true)
            } else {
                onDebugMessage?("⚠️ File not found: \(url.path)")
            }
        }

        context.coordinator.controller = docController
        return viewController
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) { }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject, UIDocumentInteractionControllerDelegate {
        var controller: UIDocumentInteractionController?

        func documentInteractionControllerViewControllerForPreview(_ controller: UIDocumentInteractionController) -> UIViewController {
            UIApplication.shared.connectedScenes
                .compactMap { ($0 as? UIWindowScene)?.keyWindow?.rootViewController }
                .first ?? UIViewController()
        }
    }
}