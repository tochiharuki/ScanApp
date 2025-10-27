//
//  DocumentInteractionView.swift
//  ScanApp
//

import SwiftUI
import UIKit

struct DocumentInteractionView: UIViewControllerRepresentable {
    let url: URL
    var onDebugMessage: ((String) -> Void)?

    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = UIViewController()
        viewController.view.backgroundColor = .clear  // ✅ 真っ白防止

        // ✅ UIDocumentInteractionController を設定
        let docController = UIDocumentInteractionController(url: url)
        docController.delegate = context.coordinator
        context.coordinator.controller = docController
        context.coordinator.parent = self

        // ✅ ViewController が画面に表示されてからプレビューを開く
        DispatchQueue.main.async {
            if FileManager.default.fileExists(atPath: url.path) {
                if let presenter = viewController.presentingViewController ?? UIApplication.shared.topMostViewController() {
                    onDebugMessage?("✅ Opening preview for \(url.lastPathComponent)")
                    docController.presentPreview(animated: true)
                } else {
                    onDebugMessage?("⚠️ Could not find presenter VC")
                }
            } else {
                onDebugMessage?("❌ File not found: \(url.lastPathComponent)")
            }
        }

        return viewController
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject, UIDocumentInteractionControllerDelegate {
        weak var controller: UIDocumentInteractionController?
        var parent: DocumentInteractionView?

        func documentInteractionControllerViewControllerForPreview(_ controller: UIDocumentInteractionController) -> UIViewController {
            UIApplication.shared.topMostViewController() ?? UIViewController()
        }

        func documentInteractionControllerWillBeginPreview(_ controller: UIDocumentInteractionController) {
            parent?.onDebugMessage?("👁️ Will begin preview")
        }

        func documentInteractionControllerDidEndPreview(_ controller: UIDocumentInteractionController) {
            parent?.onDebugMessage?("✅ Preview closed")
        }
    }
}

// MARK: - Helper Extension
extension UIApplication {
    func topMostViewController(base: UIViewController? = nil) -> UIViewController? {
        let baseVC = base ?? connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.keyWindow?.rootViewController }
            .first

        if let nav = baseVC as? UINavigationController {
            return topMostViewController(base: nav.visibleViewController)
        }
        if let tab = baseVC as? UITabBarController {
            return topMostViewController(base: tab.selectedViewController)
        }
        if let presented = baseVC?.presentedViewController {
            return topMostViewController(base: presented)
        }
        return baseVC
    }
}