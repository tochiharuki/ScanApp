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
        viewController.view.backgroundColor = .systemBackground

        // ✅ ドキュメントコントローラを初期化
        let docController = UIDocumentInteractionController(url: url)
        docController.delegate = context.coordinator
        context.coordinator.controller = docController
        context.coordinator.parent = self

        // ✅ 少し遅らせてプレビューを表示（View階層が確立してから）
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            if FileManager.default.fileExists(atPath: url.path) {
                onDebugMessage?("✅ Presenting preview for \(url.lastPathComponent)")
                if let topVC = UIApplication.shared.topMostViewController() {
                    docController.presentPreview(animated: true)
                    onDebugMessage?("📄 Preview opened successfully from \(String(describing: topVC))")
                } else {
                    onDebugMessage?("⚠️ Could not find top view controller")
                }
            } else {
                onDebugMessage?("❌ File not found: \(url.lastPathComponent)")
            }
        }

        return viewController
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) { }

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