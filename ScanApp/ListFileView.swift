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
                    // 変更後：
                    if isDirectory(fileURL) {
                        Image(systemName: "folder.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 60, height: 60)
                            .foregroundColor(.yellow)
                    } else {
                        let iconName = iconName(for: fileURL)
                        Image(systemName: iconName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 60, height: 60)
                            .foregroundColor(.blue)
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
    // MARK: - アイコン判定
    func isDirectory(_ url: URL) -> Bool {
        var isDir: ObjCBool = false
        FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir)
        return isDir.boolValue
    }
    
    func iconName(for url: URL) -> String {
        let ext = url.pathExtension.lowercased()
        switch ext {
        case "pdf":
            return "doc.richtext"
        case "jpg", "jpeg", "png", "heic":
            return "photo"
        case "txt":
            return "doc.text"
        case "zip":
            return "archivebox"
        default:
            return "doc"
        }
    }
}