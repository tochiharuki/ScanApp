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
            ForEach(folders, id: \.self) { url in
                HStack(spacing: 16) {
                    // ✅ フォルダとファイルでアイコンを分ける
                    if isDirectory(url) {
                        Image("folderIcon") // ← ここをAssetsの画像名に合わせて
                            .resizable()
                            .scaledToFit()
                            .frame(width: 42, height: 42)
                            .padding(.vertical, 6)
                    } else {
                        Image(systemName: "doc.text.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 38, height: 38)
                            .foregroundColor(.gray)
                            .padding(.vertical, 6)
                    }
        
                    VStack(alignment: .leading, spacing: 4) {
                        Text(url.lastPathComponent)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.primary)
                        if !isDirectory(url) {
                            Text(fileExtension(for: url))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
        
                    Spacer()
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    if isDirectory(url) {
                        currentURL = url // ✅ フォルダを開く
                    } else {
                        // ✅ ファイルはタップ無効
                    }
                }
                .padding(.vertical, 6)
            }
        }
        .listStyle(.plain)
    }
    
    private func fileExtension(for url: URL) -> String {
        url.pathExtension.uppercased()
}
}