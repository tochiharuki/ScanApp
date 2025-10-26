//
//  FileThumbnailView.swift
//  ScanApp
//
//  Created by Tochishita Haruki on 2025/10/26.
//

import Foundation
import SwiftUI
import QuickLookThumbnailing

struct FileThumbnailView: View {
    let url: URL
    @State private var thumbnail: UIImage? = nil

    var body: some View {
        Group {
            if let image = thumbnail {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .cornerRadius(6)
            } else {
                Image(systemName: systemIconName(for: url))
                    .resizable()
                    .scaledToFit()
                    .padding(10)
                    .foregroundColor(.gray)
            }
        }
        .frame(width: 40, height: 40)
        .onAppear {
            loadThumbnail()
        }
    }

    // 📁 ファイル種類ごとのデフォルトアイコン
    private func systemIconName(for url: URL) -> String {
        let ext = url.pathExtension.lowercased()
        if url.hasDirectoryPath { return "folder.fill" }
        if ["jpg", "jpeg", "png", "heic"].contains(ext) { return "photo" }
        if ext == "pdf" { return "doc.richtext" }
        return "doc.text.fill"
    }

    // 📸 QuickLook でサムネイル生成
    private func loadThumbnail() {
        guard thumbnail == nil else { return }

        let size = CGSize(width: 80, height: 80)
        let scale = UIScreen.main.scale
        let request = QLThumbnailGenerator.Request(
            fileAt: url,
            size: size,
            scale: scale,
            representationTypes: .all
        )

        QLThumbnailGenerator.shared.generateBestRepresentation(for: request) { rep, error in
            if let rep = rep {
                DispatchQueue.main.async {
                    self.thumbnail = rep.uiImage
                }
            }
        }
    }
}