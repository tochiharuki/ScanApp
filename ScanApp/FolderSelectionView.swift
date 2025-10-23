import SwiftUI
import UniformTypeIdentifiers

struct FolderSelectionView: View {
    @State var currentURL: URL
    let onSelect: (URL) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var folders: [URL] = []
    private let fileManager = FileManager.default

    @State private var showCreateFolderAlert = false
    @State private var newFolderName = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // ✅ パス階層バー
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
                    .padding(.vertical, 6)
                }
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .padding(.horizontal)
                .padding(.top)

                Divider()

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
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    // ✅ 戻るボタン
                    Button {
                        goBack()
                    } label: {
                        Image(systemName: "chevron.left")
                    }
                    .disabled(isAtRoot)
                }

                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    // ✅ フォルダ作成ボタン
                    Button {
                        showCreateFolderAlert = true
                    } label: {
                        Image(systemName: "folder.badge.plus")
                    }

                    // ✅ 選択ボタン
                    Button("Select") {
                        onSelect(currentURL)
                        dismiss()
                    }
                }
            }
            .onAppear(perform: loadFolders)
            // ✅ 新規フォルダ作成アラート
            .alert("New Folder", isPresented: $showCreateFolderAlert) {
                TextField("Folder name", text: $newFolderName)
                Button("Create") {
                    createFolder(named: newFolderName)
                    newFolderName = ""
                }
                Button("Cancel", role: .cancel) {}
            }
        }
    }

    // MARK: - 階層ナビゲーション
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

    private func navigateTo(_ url: URL) {
        currentURL = url
        loadFolders()
    }

    private func goBack() {
        let parent = currentURL.deletingLastPathComponent()
        let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        guard parent.path.hasPrefix(documents.path) else { return }
        currentURL = parent
        loadFolders()
    }

    private var isAtRoot: Bool {
        let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        return currentURL == documents
    }

    // MARK: - フォルダ読み込み
    private func loadFolders() {
        do {
            let contents = try fileManager.contentsOfDirectory(at: currentURL, includingPropertiesForKeys: nil)
            folders = contents.filter { $0.hasDirectoryPath }
        } catch {
            print("Failed to load folders:", error)
            folders = []
        }
    }

    // MARK: - フォルダ作成
    private func createFolder(named name: String) {
        guard !name.isEmpty else { return }
        let newFolderURL = currentURL.appendingPathComponent(name)
        do {
            try fileManager.createDirectory(at: newFolderURL, withIntermediateDirectories: false)
            loadFolders()
        } catch {
            print("Create folder failed:", error)
        }
    }
}