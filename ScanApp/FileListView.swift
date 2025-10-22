import SwiftUI
import FileManagerUI

struct FileListView: View {
    @State private var files: [URL] = []
    private let fileManager = FileManager.default
    private let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]

    var body: some View {
        NavigationView {
            VStack {
                FileManagerView(
                    directoryURL: documentsURL,
                    fileManager: fileManager
                )
                .navigationTitle("Saved Files")

                // 例: ファイル作成ボタン
                Button("Create Test File") {
                    createFile()
                }
                .padding()

                // 例: ファイル削除ボタン
                Button("Delete Test File") {
                    deleteFile()
                }
                .padding()
            }
        }
    }

    private func createFile() {
        let newFileURL = documentsURL.appendingPathComponent("newFile.txt")
        let content = "Hello, SwiftUI!"
        do {
            try content.write(to: newFileURL, atomically: true, encoding: .utf8)
            print("File created at \(newFileURL)")
        } catch {
            print("Error creating file: \(error)")
        }
    }

    private func deleteFile() {
        let newFileURL = documentsURL.appendingPathComponent("newFile.txt")
        do {
            try fileManager.removeItem(at: newFileURL)
            print("File deleted")
        } catch {
            print("Error deleting file: \(error)")
        }
    }
}
