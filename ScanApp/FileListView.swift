import SwiftUI

struct FileListView: View {
    @State private var currentPath: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    @State private var files: [URL] = []

    var body: some View {
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
                ForEach(folders(), id: \.self) { folder in
                    Button(action: {
                        currentPath = folder
                    }) {
                        Label(folder.lastPathComponent, systemImage: "folder")
                    }
                }

                ForEach(files(), id: \.self) { file in
                    Label(file.lastPathComponent, systemImage: "doc")
                }
            }
        }
        .navigationTitle(currentPath.lastPathComponent)
        .onAppear(perform: loadFiles)
        .onChange(of: currentPath) { _ in
            loadFiles()
        }
    }

    // MARK: - Helper
    private func loadFiles() {
        do {
            files = try FileManager.default.contentsOfDirectory(at: currentPath, includingPropertiesForKeys: nil)
        } catch {
            print("Error loading files:", error)
        }
    }

    private func folders() -> [URL] {
        files.filter { $0.hasDirectoryPath }
    }

    private func files() -> [URL] {
        files.filter { !$0.hasDirectoryPath }
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