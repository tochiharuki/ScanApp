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
            ForEach(files, id: \.self) { url in
                HStack(spacing: 12) {
                    // MARK: - アイコン表示
                    if isDirectory(url) {
                        // 📁 フォルダの場合
                        Image(systemName: "folder.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 40, height: 40)
                            .foregroundStyle(.black)
                    } else {
                        // 📄 ファイルの場合は汎用アイコンのみ
                        Image(systemName: "doc.text.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 40, height: 40)
                            .foregroundStyle(.gray)
                    }   
               }

                    // MARK: - ファイル名
                    Text(url.lastPathComponent)
                        .font(.body)
                        .lineLimit(1)
                    Spacer()
                }
                .contentShape(Rectangle()) // ← タップ範囲拡大
                .onTapGesture {
                    if !isEditing {
                        onTap(url)
                    }
                }
            }
            .onDelete(perform: deleteAction)
        }
        .listStyle(.plain)
    }

    // MARK: - フォルダ判定
    func isDirectory(_ url: URL) -> Bool {
        var isDir: ObjCBool = false
        FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir)
        return isDir.boolValue
        
    }
    
}