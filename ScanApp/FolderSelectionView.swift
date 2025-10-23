import SwiftUI
import UniformTypeIdentifiers

struct FolderSelectionView: View {
    @State var currentURL: URL
    let onSelect: (URL) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var folders: [URL] = []
    private let fileManager = FileManager.default

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // ✅ パスバー（階層表示）
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(pathComponents(), id: \.self) { component in
                            Button {
                                navigateTo(component)
                            } label: {
                                Text(component.lastPathComponent)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(component == currentURL ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
                                    .cornerRadius(6)
                            }
                            if component != currentURL {
                                Image(systemName: "chevron.right")
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 4)
                }
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .padding(.horizontal)
                .padding(.top)

                // ✅ フォルダリスト
                List(folders, id: \.self) { folder in
                    Button {
                        currentURL = folder
                        loadFolders()
                    } label: {
                        HStack {
                            Image(systemName: "folder.fill")
                            Text(folder.lastPathComponent)
                        }
                    }
                }
            }
            .navigationTitle(currentURL.lastPathComponent)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Select") {
                        onSelect(currentURL)
                        dismiss()
                    }
                }
            }
            .onAppear(perform: loadFolders)
        }
    }

    // MARK: - 現在のフォルダ階層（例: /Documents/Sub1/Sub2）
    private func pathComponents() -> [URL] {
        var paths: [URL] = []
        var url = currentURL
        let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        while url.path.hasPrefix(documents.path) {
            paths.insert(url, at: 0)
            if url == documents { break }
            url.deleteLastPathComponent()
        }
        return paths
    }

    // MARK: - 階層をクリックで戻る
    private func navigateTo(_ url: URL) {
        currentURL = url
        loadFolders()
    }

    private func loadFolders() {
        do {
            let contents = try fileManager.contentsOfDirectory(at: currentURL, includingPropertiesForKeys: nil)
            folders = contents.filter { $0.hasDirectoryPath }
        } catch {
            print("Failed to load folders:", error)
            folders = []
        }
    }
}