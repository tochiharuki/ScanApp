import SwiftUI
import Foundation

struct FileListView: View {
    @State private var currentURL: URL
    @State private var isLoading = false
    @State private var folders: [URL] = []

    private let fileManager = FileManager.default
    private var documentsURL: URL { fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0] }

    init(currentURL: URL? = nil) {
        _currentURL = State(initialValue:
            currentURL ?? FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        )
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {

                // ✅ PathBarView（FolderSelectionView と同じ動き）
                PathBarView(currentURL: currentURL) { url in
                    if url != currentURL {
                        currentURL = url
                        loadFolders()
                    }
                }

                Divider()

                // ✅ 読み込み中
                if isLoading {
                    ProgressView("Loading...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // ✅ ファイル一覧（ナビゲーション付き）
                    List {
                        // 🔹 フォルダ一覧
                        ForEach(folders, id: \.self) { folder in
                            NavigationLink(value: folder) {
                                HStack {
                                    Image(systemName: "folder.fill")
                                        .foregroundColor(.accentColor)
                                    Text(folder.lastPathComponent)
                                        .foregroundColor(.primary)
                                    Spacer()
                                }
                            }
                        }

                        // 🔹 ファイル一覧
                        Section {
                            FileListContentView(currentURL: $currentURL)
                        }
                    }
                    .listStyle(.plain)

                    // ✅ 下層フォルダをナビゲート
                    .navigationDestination(for: URL.self) { folder in
                        FileListView(currentURL: folder)
                    }
                }
            }
            .navigationTitle(currentURL.lastPathComponent)
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                loadFolders()
            }
        }
    }

    // MARK: - ロード処理
    private func loadFolders() {
        isLoading = true
        DispatchQueue.global(qos: .userInitiated).async {
            let contents = (try? fileManager.contentsOfDirectory(at: currentURL, includingPropertiesForKeys: [.isDirectoryKey])) ?? []
            let dirs = contents.filter {
                (try? $0.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
            }
            DispatchQueue.main.async {
                self.folders = dirs.sorted(by: { $0.lastPathComponent < $1.lastPathComponent })
                self.isLoading = false
            }
        }
    }
}