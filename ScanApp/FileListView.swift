import SwiftUI

struct FileListView: View {
    @State private var currentPath: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    @State private var allItems: [URL] = [] // ← 名前変更

    var body: some View {
        NavigationStack {
            VStack {
                // パスバー
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 5) {
                        ForEach(pathComponents(), id: \.self) { path in
                            Button(action: { currentPath = path }) {
                                Text(path.lastPathComponent)
                                    .font(.subheadline)
                            }
                            if path != pathComponents().last {
                                Text("›")
                            }
                        }
                    }
                    .padding()
                }
    
                List {
                    // フォルダ一覧
                    ForEach(foldersOnly(), id: \.self) { folder in
                        Button(action: {
                            currentPath = folder
                        }) {
                            Label(folder.lastPathComponent, systemImage: "folder")
                        }
                    }
    
                    // ファイル一覧
                    ForEach(filesOnly(), id: \.self) { file in
                        Label(file.lastPathComponent, systemImage: "doc")
                    }
                }
            }
            .navigationTitle(currentPath.lastPathComponent)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button(action: { loadFiles() }) {
                        Image(systemName: "arrow.clockwise")
                    }
                    Button(action: {
                        // 新規フォルダ作成など後で追加可能
                        print("Add folder tapped")
                    }) {
                        Image(systemName: "folder.badge.plus")
                    }
                }
            }

        }
    }

    // MARK: - Helper

    private func loadFiles() {
        do {
            allItems = try FileManager.default.contentsOfDirectory(at: currentPath, includingPropertiesForKeys: nil)
        } catch {
            print("Error loading files:", error)
            allItems = []
        }
    }

    private func foldersOnly() -> [URL] {
        allItems.filter { $0.hasDirectoryPath }
    }

    private func filesOnly() -> [URL] {
        allItems.filter { !$0.hasDirectoryPath }
    }

    private func pathComponents() -> [URL] {
        var paths: [URL] = []
        var current = currentPath
        while current.pathComponents.count > 1 {
            paths.insert(current, at: 0)
            current.deleteLastPathComponent()
        }
        return paths
    }
}