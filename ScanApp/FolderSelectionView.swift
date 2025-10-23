import SwiftUI
import UniformTypeIdentifiers

struct FolderSelectionView: View {
    @State var currentURL: URL
    let onSelect: (URL) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var folders: [URL] = []
    @State private var showCreateFolderAlert = false
    @State private var newFolderName = ""

    private let fileManager = FileManager.default

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // ✅ パスバー
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
                        withAnimation {
                            currentURL = folder
                        }
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
            .navigationTitle(currentURL.lastPathComponent)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    // 戻るボタン
                    Button {
                        goBack()
                    } label: {
                        Image(systemName: "chevron.left")
                    }
                    .disabled(isAtRoot)

                    // キャンセル
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    // 新規フォルダ作成
                    Button {
                        showCreateFolderAlert = true
                    } label: {
                        Image(systemName: "folder.badge.plus")
                    }

                    // 選択ボタン
                    Button("Select") {
                        onSelect(currentURL)
                        dismiss()
                    }
                }
            }
            .onAppear(perform: loadFolders)
            .onChange(of: currentURL) { _ in
                loadFolders()
            } // ✅ currentURL変更時に再読込
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

    // MARK: - パス階層
    private func pathComponents() -> [URL] {
        var paths: [URL] = []
        guard let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else { return [] }
        var url = currentURL
        while url.path.hasPrefix(documents.path) {
            paths.insert(url, at: 0)
            if url == documents { break }
            url.deleteLastPathComponent()
        }
        return paths
    }

    // MARK: - 移動・戻る
    private func navigateTo(_ url: URL) {
        withAnimation {
            currentURL = url
        }
    }

    private func goBack() {
        let parent = currentURL.deletingLastPathComponent()
        guard let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first,
              parent.path.hasPrefix(documents.path) else { return }
        withAnimation {
            currentURL = parent
        }
    }

    private var isAtRoot: Bool {
        guard let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else { return false }
        return currentURL == documents
    }

    // MARK: - フォルダ読み込み・作成
    private func loadFolders() {
        do {
            let contents = try fileManager.contentsOfDirectory(at: currentURL, includingPropertiesForKeys: nil)
            folders = contents.filter { $0.hasDirectoryPath }
        } catch {
            print("Failed to load folders:", error)
            folders = []
        }
    }

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