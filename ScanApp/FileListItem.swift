//
//  FileListItem.swift
//  ScanApp
//
//  Created by Tochishita Haruki on 2025/10/24.
//

import SwiftUI
import Foundation

struct FileListItem: View {
    let file: URL
    let isSelected: Bool
    let isEditing: Bool
    let onTap: () -> Void

    var body: some View {
        HStack {
            if isEditing {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
            }
            Image(systemName: file.hasDirectoryPath ? "folder.fill" : "doc.text.fill")
            Text(file.lastPathComponent)
            Spacer()
        }
        .contentShape(Rectangle())
        .onTapGesture { onTap() }
    }
}