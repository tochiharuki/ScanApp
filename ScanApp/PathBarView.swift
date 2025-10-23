//
//  PathBarView.swift
//  ScanApp
//
//  Created by Tochishita Haruki on 2025/10/24.
//

import SwiftUI

struct PathBarView: View {
    let currentURL: URL
    let onNavigate: (URL) -> Void
    
    private let fileManager = FileManager.default
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                ForEach(pathComponents(), id: \.self) { url in
                    Button(action: { onNavigate(url) }) {
                        Text(url.lastPathComponent)
                            .font(.system(size: 13, weight: .medium))
                            .lineLimit(1)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 4)
                            .background(url == currentURL ? Color.accentColor.opacity(0.25) : Color.clear)
                            .cornerRadius(5)
                    }
                    if url != pathComponents().last {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10))
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 6)
        }
        .background(Color(UIColor.secondarySystemBackground))
    }
    
    /// Documents から currentURL までの階層を返す
    private func pathComponents() -> [URL] {
        var stack: [URL] = []
        var url = currentURL
        let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        
        while url.path.hasPrefix(documents.path) {
            stack.insert(url, at: 0)
            if url == documents { break }
            url.deleteLastPathComponent()
        }
        return stack
    }
}
