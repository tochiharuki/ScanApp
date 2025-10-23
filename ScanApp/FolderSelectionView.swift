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
                // ✅ パス階層バー（パンくずリスト）
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(pathComponents(), id: \.self) { component in
                            Button {
                                navigateTo(component)
                            } label: {
                                Text(component.lastPathComponent)
                                    .font(.subheadline)
                                    .foregroundColor(component == currentURL ? .black : .gray)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 8)
                                    .background(component == currentURL ? Color.gray.opacity(0.3) : Color.gray.opacity(0.1))
                                    .cornerRadius(6)
                            }

                            if component != currentURL {
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .padding(.horizontal)
                .padding(.top, 8)

                Divider()

                // ✅ フォルダリスト
                List(folders, id: \.self) { folder in
                    Button {
                        currentURL = folder
                        loadFolders()
                    } label: {
                        HStack {
                            Image(systemName: "folder.fill")
                                .foregroundColor(.gray)
                            Text(folder.lastPathComponent)
                                .foregroundColor(.black)
                        }
                    }
                }
                .listStyle(.plain)
                .background(Color(.systemGray5))
            }
            .background(Color(.systemGray5))
            .navigationTitle("Select Folder")
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    // ✅ 戻るボタン
                    Button {
                        goBack()
                    } label: {
                        Image(systemName: "chevron.left")
                    }
                    .disabled(isAtRoot)

                    // ✅ キャンセルボタン
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    // ✅ 新規フォルダ作成
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

    // MARK: - パス階層リスト生成
    private func pathComponents() -> [URL] {
        var paths: [URL] = []
        let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        var url = currentURL

        // Documents までの階層を全て配列化
        while url.path.hasPrefix(documents.path) {
            paths.insert(url, at: 0)
            if url == documents { break }
            url.deleteLastPathComponent()
        }
        return paths
    }

    // MARK: - ナビゲーション制御
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