//
//  PathBarView.swift
//  ScanApp
//
//  Created by Tochishita Haruki on 2025/10/24.
//

import SwiftUI

struct PathBarView: View {
    let currentURL: URL
    let onSelectPath: (URL) -> Void

    /// iOSサンドボックスの "Documents" 以下だけをパスとして表示
    private var visibleComponents: [URL] {
        var components: [URL] = []

        // アプリのドキュメントディレクトリパスを取得
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!

        // 現在のURLがドキュメント配下か確認
        guard currentURL.path.hasPrefix(documentsURL.path) else { return [] }

        // Documents 自体も含める
        var url = currentURL
        while url.path != documentsURL.deletingLastPathComponent().path {
            components.insert(url, at: 0)
            if url.path == documentsURL.path { break }
            url.deleteLastPathComponent()
        }

        return components
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                ForEach(visibleComponents, id: \.self) { url in
                    Button(action: { onSelectPath(url) }) {
                        Text(url.lastPathComponent)
                            .font(.subheadline)
                            .lineLimit(1)
                            .foregroundColor(.blue)
                    }
                    if url != visibleComponents.last {
                        Image(systemName: "chevron.right")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
        }
        .background(Color(.systemGray6))
    }
}