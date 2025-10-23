//
//  ListFileView.swift
//  ScanApp
//
//  Created by Tochishita Haruki on 2025/10/24.
//

import SwiftUI
import Foundation

struct ListFileView: View {
    let files: [URL]
    @Binding var selectedFiles: Set<URL>
    @Binding var isEditing: Bool
    var onTap: (URL) -> Void
    var deleteAction: (IndexSet) -> Void

    var body: some View {
        List {
            ForEach(files, id: \.self) { file in
                HStack {
                    if isEditing {
                        Image(systemName: selectedFiles.contains(file) ? "checkmark.circle.fill" : "circle")
                    }
                    Image(systemName: file.hasDirectoryPath ? "folder.fill" : "doc.text.fill")
                    Text(file.lastPathComponent)
                }
                .onTapGesture { onTap(file) }
            }
            .onDelete(perform: deleteAction)
        }
        .listStyle(.plain)
    }
}
