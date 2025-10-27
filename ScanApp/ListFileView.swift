import SwiftUI
import Foundation

struct ListFileView: View {
    let files: [URL]
    @Binding var selectedFiles: Set<URL>
    @Binding var isEditing: Bool
    var onTap: (URL) -> Void
    var deleteAction: (IndexSet) -> Void
    var onRename: (URL) -> Void
    @State private var showMoveSheet = false

    var body: some View {
        List {
            ForEach(files, id: \.self) { url in
                HStack(spacing: 12) {
                    // ────────────── 編集モード時の選択丸 ──────────────
                    if isEditing {
                        Image(systemName: selectedFiles.contains(url) ? "checkmark.circle.fill" : "circle")
                            .resizable()
                            .frame(width: 20, height: 20)
                            .foregroundColor(selectedFiles.contains(url) ? .accentColor : .gray)
                            .onTapGesture {
                                // 編集モード中に丸をタップで選択トグル
                                toggleSelection(for: url)
                            }
                    }

                    // ────────────── アイコン表示 ──────────────
                    if isDirectory(url) {
                        // フォルダ（システムアイコン）
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

                    // ────────────── ファイル名 ──────────────
                    Text(url.lastPathComponent)
                        .font(.body)
                        .lineLimit(1)

                    Spacer()
                }
                .contentShape(Rectangle()) // タップ領域を行全体に
                .onTapGesture {
                    // 編集モードなら選択トグル、通常は onTap を呼ぶ（例：ディレクトリ移動）
                    if isEditing {
                        toggleSelection(for: url)
                    } else {
                        onTap(url)
                    }
                }
                .contextMenu {
                    FileContextMenu(
                        file: url,
                        onRename: onRename,
                        onMove: { file in
                            selectedFiles = [file]
                            showMoveSheet = true
                        },
                        onShare: { file in
                            let controller = UIActivityViewController(activityItems: [file], applicationActivities: nil)
                            UIApplication.shared.topMostViewController()?.present(controller, animated: true)
                        }
                    )
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

    // MARK: - 選択トグル処理（編集モード用）
    private func toggleSelection(for url: URL) {
        if selectedFiles.contains(url) {
            selectedFiles.remove(url)
        } else {
            selectedFiles.insert(url)
        }
    }
}