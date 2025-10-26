import SwiftUI
import Foundation

struct ListFileView: View {
    let files: [URL]
    @Binding var selectedFiles: Set<URL>
    @Binding var isEditing: Bool
    var onTap: (URL) -> Void
    var deleteAction: (IndexSet) -> Void
    var onRename: (URL) -> Void

    var body: some View {
        List {
            ForEach(files, id: \.self) { url in
                HStack(spacing: 12) {
                    // アイコン表示
                    if isDirectory(url) {
                        // フォルダ
                        Image(systemName: "folder.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                            .foregroundStyle(.black)
                    } else {
                        // ファイル（リスト表示では汎用アイコン）
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
                    if !isEditing {
                        onTap(url)
                    }
                }
                .onLongPressGesture {
                    onRename(url) // 長押しでリネーム
                }
            }
            .onDelete(perform: deleteAction)
        }
        .listStyle(.plain)
    }

    // フォルダ判定
    func isDirectory(_ url: URL) -> Bool {
        var isDir: ObjCBool = false
        FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir)
        return isDir.boolValue
    }
}