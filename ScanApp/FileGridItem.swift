//
//  FileGridItem.swift
//  ScanApp
//
//  Created by Tochishita Haruki on 2025/10/24.
//

import SwiftUI
import Foundation

struct FileGridItem: View {
    let file: URL
    let isSelected: Bool
    let isEditing: Bool
    var onRename: ((URL) -> Void)?  // ← 追加

    var body: some View {
        VStack(spacing: 8) {
            ZStack(alignment: .topTrailing) {
                VStack {
                    FileThumbnailView(url: file)   // ← 新しいビューを使う
                        .frame(width: 60, height: 60)
                    Text(file.lastPathComponent)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .frame(width: 80)
                }
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemGray6)))

                if isEditing {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(isSelected ? .black : .gray)
                        .padding(6)
                }
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isSelected)
        .contextMenu {   // ← ここで長押しメニュー
            Button("Rename") {
                onRename?(file)
            }
        }
    }
}