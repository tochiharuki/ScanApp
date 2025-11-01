import SwiftUI
import Foundation

struct FileListItem: View {
    let file: URL
    let isSelected: Bool
    let isEditing: Bool
    let onTap: () -> Void
    var onEmptyTrash: (() -> Void)? = nil  // ← 追加

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
        .contextMenu {
            if file.lastPathComponent == "Trash" {
                Button(role: .destructive) {
                    onEmptyTrash?()
                } label: {
                    Label("Empty Trash", systemImage: "trash.slash")
                }
            }
        }
    }
}