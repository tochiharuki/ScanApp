import SwiftUI
import Foundation

struct ListFileView: View {
    let files: [URL]
    @Binding var selectedFiles: Set<URL>
    @Binding var isEditing: Bool
    var onTap: (URL) -> Void
    var deleteAction: (IndexSet) -> Void
    var onRename: (URL) -> Void   // ←追加

    var body: some View {
        List {
            ForEach(files, id: \.self) { file in
                HStack {
                    if isEditing {
                        Image(systemName: selectedFiles.contains(file) ? "checkmark.circle.fill" : "circle")
                    }
        
                    // ✅ サムネイルではなくアイコンを表示
                    Image(systemName: file.hasDirectoryPath ? "folder.fill" : "doc.text.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                        .foregroundColor(file.hasDirectoryPath ? .black : .gray)
        
                    Text(file.lastPathComponent)
                        .lineLimit(1)
                }
                .onTapGesture { onTap(file) }
                .onLongPressGesture {
                    onRename(file)
                }
            }
            .onDelete(perform: deleteAction)
        }
        .listStyle(.plain)
    }
}