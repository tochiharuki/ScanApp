//
//  DocumentBrowserView.swift
//  ScanApp
//
//  Created by Tochishita Haruki on 2025/10/22.
//

import SwiftUI
import UIKit

// UIKitのDocument BrowserをSwiftUIで使えるようにする
struct DocumentBrowserView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIDocumentBrowserViewController {
      let browser = UIDocumentBrowserViewController(forOpening: [.item])
      browser.allowsDocumentCreation = true
      browser.allowsPickingMultipleItems = true
      browser.delegate = context.coordinator
      
      // ✅ ツールバー非表示
      browser.toolbarItems = []
      browser.navigationItem.hidesBackButton = true
      browser.view.backgroundColor = .systemBackground
      
      return browser
  }


    func updateUIViewController(_ uiViewController: UIDocumentBrowserViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject, UIDocumentBrowserViewControllerDelegate {
        func documentBrowser(_ controller: UIDocumentBrowserViewController,
                             didRequestDocumentCreationWithHandler importHandler: @escaping (URL?, UIDocumentBrowserViewController.ImportMode) -> Void) {
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("NewFile.txt")
            FileManager.default.createFile(atPath: tempURL.path, contents: Data(), attributes: nil)
            importHandler(tempURL, .move)
        }

        func documentBrowser(_ controller: UIDocumentBrowserViewController,
                             didPickDocumentsAt documentURLs: [URL]) {
            guard let url = documentURLs.first else { return }
            print("📄 選択されたファイル: \(url.lastPathComponent)")
        }
    }
}

