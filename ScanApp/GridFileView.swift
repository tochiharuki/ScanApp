//
//  GridFileView.swift
//  ScanApp
//
//  Created by Tochishita Haruki on 2025/10/24.
//
import SwiftUI
import Foundation

struct GridFileView: View {
    let files: [URL]
    @Binding var selectedFiles: Set<URL>
    @Binding var isEditing: Bool
    var onTap: (URL) -> Void
    var onRename: (URL) -> Void  // ← 追加

    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 16) {
                ForEach(files, id: \.self) { file in
                    FileGridItem(file: file, isSelected: selectedFiles.contains(file), isEditing: isEditing)
                        .onTapGesture { onTap(file) }
                        .contextMenu {
                            Button("Rename") { onRename(file) }
                        }
                }
            }
            .padding()
        }
    }
}