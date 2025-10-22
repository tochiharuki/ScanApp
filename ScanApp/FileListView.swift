import SwiftUI

struct FileListView: View {
    @State private var files: [URL] = []
    private let fileManager = FileManager.default
    private let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]

    var body: some View {
        NavigationView {
            List {
                ForEach(files, id: \.self) { file in
                    HStack {
                        Image(systemName: file.hasDirectoryPath ? "folder.fill" : "doc.fill")
                            .foregroundColor(file.hasDirectoryPath ? .blue : .gray)
                        Text(file.lastPathComponent)
                    }
                }
                .onDelete(perform: deleteFiles)
            }
            .navigationTitle("Saved Files")
            .toolbar {
                EditButton() // 編集ボタンで複数削除も可能
            }
            .onAppear(perform: loadFiles)
            .refreshable {
                loadFiles()
            }
        }
    }

    // ファイルを削除
    private func deleteFiles(at offsets: IndexSet) {
        for index in offsets {
            let fileURL = files[index]
            do {
                try fileManager.removeItem(at: fileURL)
                print("Deleted: \(fileURL.lastPathComponent)")
            } catch {
                print("Failed to delete file: \(error)")
            }
        }
        loadFiles() // 更新
    }

    // ファイルを読み込む
    private func loadFiles() {
        do {
            let contents = try fileManager.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil)
            files = contents.sorted(by: { $0.lastPathComponent > $1.lastPathComponent })
        } catch {
            print("Failed to load files: \(error)")
        }
    }
}
