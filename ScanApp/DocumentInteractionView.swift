//
//  DocumentInteractionView.swift
//  ScanApp
//
//  Created by Tochishita Haruki on 2025/10/26.
//

import SwiftUI
import UIKit

struct DocumentInteractionView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = UIViewController()
        DispatchQueue.main.async {
            let docController = UIDocumentInteractionController(url: url)
            docController.delegate = context.coordinator
            docController.presentPreview(animated: true)
        }
        return viewController
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject, UIDocumentInteractionControllerDelegate {
        func documentInteractionControllerViewControllerForPreview(_ controller: UIDocumentInteractionController) -> UIViewController {
            UIApplication.shared.connectedScenes
                .compactMap { ($0 as? UIWindowScene)?.keyWindow?.rootViewController }
                .first ?? UIViewController()
        }
    }
}