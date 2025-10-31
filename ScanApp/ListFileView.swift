import SwiftUI
import Foundation

struct ListFileView: View {
    let files: [URL]
    @Binding var selectedFiles: Set<URL>
    @Binding var isEditing: Bool
    var onTap: (URL) -> Void
    var deleteAction: (IndexSet) -> Void
    var onRename: (URL) -> Void
    var onMove: (URL) -> Void      // ✅ 追加
    var onShare: (URL) -> Void
    var onDelete: (URL) -> Void

    var body: some View {
        List {
            ForEach(files, id: \.self) { url in
                HStack(spacing: 12) {
                    // 編集モード時の選択丸
                    if isEditing {
                        Image(systemName: selectedFiles.contains(url) ? "checkmark.circle.fill" : "circle")
                            .resizable()
                            .frame(width: 20, height: 20)
                            .foregroundColor(selectedFiles.contains(url) ? .accentColor : .gray)
                            .onTapGesture {
                                toggleSelection(for: url)
                            }
                    }

                    // アイコン
                    if isDirectory(url) {
                        Image(systemName: "folder.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                            .foregroundStyle(.black)
                    } else {
                        Image(systemName: "doc.text.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                            .foregroundStyle(.gray)
                    }

                    // ファイル名
                    Text(url.lastPathComponent)
                        .font(.body)
                        .lineLimit(1)

                    Spacer()
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    if isEditing {
                        toggleSelection(for: url)
                    } else {
                        onTap(url)
                    }
                }
                // ✅ コンテキストメニュー（共通化）
                .contextMenu {
                    FileContextMenu(
                        file: url,
                        onRename: onRename,
                        onMove: onMove,
                        onShare: onShare,
                        onDelete: onDelete,
                        // ✅ Trash フォルダそのものを長押しした場合のみ表示
                        if file.lastPathComponent == "Trash" {
                            Divider()
                            Button(role: .destructive) {
                                onEmptyTrash?()
                            } label: {
                                Label("Empty Trash", systemImage: "trash.slash")
                            }
                        }
   
                    )
                }
            }
            .onDelete(perform: deleteAction)
        }
        .listStyle(.plain)
    }

    // MARK: - フォルダ判定
    private func isDirectory(_ url: URL) -> Bool {
        var isDir: ObjCBool = false
        FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir)
        return isDir.boolValue
    }

    // MARK: - 選択トグル処理
    private func toggleSelection(for url: URL) {
        if selectedFiles.contains(url) {
            selectedFiles.remove(url)
        } else {
            selectedFiles.insert(url)
        }
    }
}