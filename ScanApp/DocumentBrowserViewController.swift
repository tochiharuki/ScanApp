//
//  DocumentBrowserViewController.swift
//  ScanApp
//
//  Created by Tochishita Haruki on 2025/10/22.
//

import UIKit
import SwiftUI

class DocumentBrowserViewController: UIDocumentBrowserViewController, UIDocumentBrowserViewControllerDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self

        allowsDocumentCreation = true  // ✅ 新規作成ボタンを有効化
        allowsPickingMultipleItems = true
    }

    // ✅ ドキュメント作成
    func documentBrowser(_ controller: UIDocumentBrowserViewController,
                         didRequestDocumentCreationWithHandler importHandler: @escaping (URL?, UIDocumentBrowserViewController.ImportMode) -> Void) {
        let newDocURL = FileManager.default.temporaryDirectory.appendingPathComponent("NewFile.txt")
        FileManager.default.createFile(atPath: newDocURL.path, contents: Data(), attributes: nil)
        importHandler(newDocURL, .move)
    }

    // ✅ ドキュメント選択時
    func documentBrowser(_ controller: UIDocumentBrowserViewController,
                         didPickDocumentsAt documentURLs: [URL]) {
        guard let url = documentURLs.first else { return }
        // 開く処理（例：別VCを表示）
        print("Selected: \(url.lastPathComponent)")
    }
}

