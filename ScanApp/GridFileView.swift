import SwiftUI

struct GridFileView: View {
    let files: [URL]
    @Binding var selectedFiles: Set<URL>
    @Binding var isEditing: Bool
    var onTap: (URL) -> Void
    var deleteAction: (IndexSet) -> Void
    var onRename: (URL) -> Void

    private let columns = [
        GridItem(.adaptive(minimum: 100), spacing: 12)
    ]
    var onMove: (URL) -> Void    // ← 追加
    var onShare: (URL) -> Void

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(files, id: \.self) { url in
                    VStack(spacing: 8) {
                        // MARK: - アイコン部分
                        if isDirectory(url) {
                            // 📁 フォルダ
                            Image(systemName: "folder.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 60, height: 60)
                                .foregroundStyle(.black)
                        } else if let image = UIImage(contentsOfFile: url.path) {
                            // 🖼 実際の画像
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 80, height: 80)
                                .cornerRadius(10)
                                .clipped()
                        } else {
                            // 📄 その他ファイル
                            Image(systemName: "doc.text.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 60, height: 60)
                                .foregroundStyle(.gray)
                        }

                        // MARK: - ファイル名
                        Text(url.lastPathComponent)
                            .font(.caption)
                            .lineLimit(1)
                            .frame(width: 80)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if !isEditing {
                            onTap(url)  // ← フォルダでもファイルでも呼ぶ
                        }
                    }
                    .contextMenu {
                        FileContextMenu(
                            file: url,
                            onRename: onRename,
                            onMove: onMove,     // 親の onMove を呼ぶ
                            onShare: onShare    // 親の onShare を呼ぶ
                            onDelete: { file in    // ← 追加
                                moveToTrash(file: file)
                                asyncLoadFiles()

                        )
                    }
                    
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }

    private func isDirectory(_ url: URL) -> Bool {
        var isDir: ObjCBool = false
        FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir)
        return isDir.boolValue
    }
}