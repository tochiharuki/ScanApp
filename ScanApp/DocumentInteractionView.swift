//
//  DocumentInteractionView.swift
//  ScanApp
//

import SwiftUI
import UIKit

struct DocumentInteractionView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = UIViewController()
        viewController.view.backgroundColor = .systemBackground

        // ✅ UIDocumentInteractionController の作成
        let docController = UIDocumentInteractionController(url: url)
        docController.delegate = context.coordinator

        // ✅ 表示（ファイルタイプに応じたプレビュー＋共有など）
        DispatchQueue.main.async {
            docController.presentPreview(animated: true)
        }

        context.coordinator.controller = docController
        return viewController
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // 更新時は特に処理なし
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject, UIDocumentInteractionControllerDelegate {
        var controller: UIDocumentInteractionController?

        // ✅ プレビューをどのViewController上に出すか指定
        func documentInteractionControllerViewControllerForPreview(_ controller: UIDocumentInteractionController) -> UIViewController {
            return UIApplication.shared.connectedScenes
                .compactMap { ($0 as? UIWindowScene)?.keyWindow?.rootViewController }
                .first ?? UIViewController()
        }
    }
}